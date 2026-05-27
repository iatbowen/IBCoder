//
//  IBGroup3Controller18.m
//  MBCoder
//
//  Created by 叶修 on 2026/5/26.
//  Copyright © 2026 inke. All rights reserved.
//

#import "IBGroup3Controller18.h"

/*
 ============================================================
 iOS 直播技术 面试题总结
 ============================================================
 关联：音视频链路/采集解码见 IBGroup3Controller12；WebRTC/同步见 IBGroup3Controller11


 ============================================================
 一、完整链路
 ============================================================

 采集 → 前处理(美颜/降噪) → 编码 → 封装 → 推流 → CDN → 拉流 → 解复用 → 解码 → 同步 → 渲染

 主播端：AVCaptureSession → GPU/Metal → VideoToolbox/AAC → RTMP/WebRTC
 观众端：HTTP-FLV/HLS/WebRTC → 解复用 → VideoToolbox/AudioUnit → Metal + AudioQueue


 ============================================================
 二、采集层
 ============================================================

 分辨率：360P / 480P / 720P / 1080P
 帧率：  15fps(弱网) / 24fps / 30fps(主流) / 60fps(游戏)

 音频采样率（Sample Rate，每秒采样点数，单位 Hz）：
 - 44100Hz：CD 标准，直播/录制最常用，AAC 默认友好
 - 48000Hz：专业音频/部分视频工作流，与 44.1k 混用需重采样
 - 16000Hz / 8000Hz：仅语音、省带宽场景（音质明显下降）
 位深：通常 16bit PCM（每采样 2 字节）；Float 仅在内部处理链出现
 声道：  单声道 mono（直播语音省带宽）/ 立体声 stereo（音乐、游戏）

 采样率与码率关系（PCM 未压缩）：
 数据率 ≈ sampleRate × channels × bitsPerSample/8
 例：44100 × 1 × 16/8 ≈ 88KB/s；立体声约 176KB/s（编码 AAC 后约 64~128kbps）

 iOS 要点：
 - AVCaptureSession + VideoDataOutput / AudioDataOutput
 - 像素格式：NV12(kCVPixelFormatType_420YpCbCr8BiPlanar*) → 硬编首选
             BGRA → GPUImage/Metal 美颜链首选
 - alwaysDiscardsLateVideoFrames = YES，防帧堆积
 - startRunning 放子线程；视频/音频用独立串行队列
 - 帧率：activeVideoMinFrameDuration / MaxFrameDuration
 - 音频采样率：AVAudioSession setPreferredSampleRate:44100（或 48000）
   实际值以 session.sampleRate / 采集回调里 ASBD 为准，勿假设一定等于设置值
 - 从 CMSampleBuffer 读采样率：
   CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)->mSampleRate


 ============================================================
 三、处理层（美颜/滤镜）
 ============================================================

 CMSampleBuffer → CVPixelBuffer → Metal/GPUImage/OpenGL
 磨皮：双边滤波（保边缘）  美白：色阶/色相  滤镜：3D LUT
 瘦脸/大眼：人脸关键点 + 局部网格变形（商汤/旷视/自研或 GPUImage）


 ============================================================
 四、编码层
 ============================================================

 视频：
 - H.264(AVC)：兼容最好，直播主流
 - H.265(HEVC)：同画质码率约减半，编解码更重，需服务端支持
 - VP9/AV1：Web 侧多

 音频：
 - AAC：直播/点播主流
 - Opus：WebRTC/连麦（FEC/DTX/PLC，20ms 帧）
 - MP3：兼容好，实时性差

 音频编码参数（与采样率强绑定）：
 - 采样率：44100Hz（直播推荐）/ 48000Hz；全链路采集→编码→封装→播放须一致
 - 声道：   1（mono）或 2（stereo）
 - AAC 帧：每帧 1024 个采样点 → 帧时长 ≈ 1024/44100 ≈ 23.2ms（48k 时约 21.3ms）
 - 码率：   64kbps(语音) / 96~128kbps(音乐级 mono) / 立体声可更高
 - AudioConverter：输入 ASBD(mSampleRate/mChannels) 与输出 AAC 的 sampleRate 不一致会先重采样
 - Opus：   常 48kHz；WebRTC 内部可重采样，勿与 RTMP-AAC 44.1k 链路直接混用不重采样

 GOP：I(完整) / P(参考前帧) / B(参考前后，压缩高、增延迟)
 直播建议：CBR + RealTime=YES + AllowFrameReordering=NO(禁 B 帧) + GOP 1~2s

 参考码率（可 ABR 动态调）：
 - 1080P 2~4Mbps / 720P 1~2Mbps / 480P 500kbps~1Mbps
 - 音频 64~128kbps AAC

 软编 vs 硬编：
 - 软编(x264)：质量/参数可控，CPU 高
 - 硬编(VideoToolbox/MediaCodec)：省电快，部分机型需降级策略

 VideoToolbox 关键属性：
 kVTCompressionPropertyKey_RealTime = YES
 kVTCompressionPropertyKey_AllowFrameReordering = NO
 kVTCompressionPropertyKey_AverageBitRate / MaxKeyFrameInterval
 kVTEncodeFrameOptionKey_ForceKeyFrame（弱网插 I 帧）

 AVCC vs Annex-B（必考）：
 - VideoToolbox 输出 AVCC：[4 字节长度][NALU]
 - RTMP 需 Annex-B：[00 00 00 01][NALU]
 - 转换：读长度 → 换起始码；首包发 AVC Sequence Header(SPS+PPS)


 ============================================================
 五、封装、协议与推流
 ============================================================

 协议对比（延迟 / 场景）：
 - RTMP：      1~3s，TCP，推流标准
 - HTTP-FLV：  1~3s，拉流，Web 常用
 - HLS：       5~30s，分片 HTTP，iOS 原生友好、延迟高
 - WebRTC：    <500ms，UDP+SRTP，连麦/会议
 - SRT：       <1s，弱网推流
 - QUIC：      低延迟传输，0-RTT 等优势

 RTMP 结构概要：
 Video Tag：AVC Sequence Header(SPS+PPS) + NALU(I/P/B)
 Audio Tag：AAC Sequence Header + AAC Raw

 开源：
 推流 LFLiveKit / 播放 IJKPlayer、VLCKit / 处理 FFmpeg、GPUImage / 实时 WebRTC


 ============================================================
 六、播放端架构
 ============================================================

 网络 → 解复用(FLV/HLS) → 音视频流 → 硬解 → Metal 渲染 + AudioQueue 播放
 同步：以音频时钟为基准，videoPTS - audioPTS
       > 阈值(约 40ms) 等待；< -阈值 丢帧；否则正常渲染


 ============================================================
 七、弱网与延迟优化
 ============================================================

 弱网：
 - ABR：带宽检测 → 降/升码率、分辨率、帧率（升级慢于降级，防抖动）
 - 丢帧：B > P，保留 I
 - FEC：冗余恢复；NACK/RTCP：WebRTC 丢包反馈
 - 推流缓冲超阈值：丢帧或降码

 延迟拆解（量级）：
 采集~33ms + 编码~50ms + 网络~100~500ms + CDN~0~200ms + 解码~33ms + 渲染~16ms

 优化：
 - 小 GOP、禁 B 帧、小播放缓冲(0.3~0.5s 极速模式)
 - 协议：超低延迟用 WebRTC；推流弱网 SRT/QUIC
 - CDN 就近、少跳

 首屏优化（<1s，优秀 <500ms）：
 DNS 预解析、TCP/QUIC 预连接、播放器预热、低 GOP 快出 I 帧、缩小 JitterBuffer、行为预加载


 ============================================================
 八、连麦 vs 普通直播
 ============================================================

 普通：主播 RTMP → CDN → 观众(1~3s，单向)

 连麦：主播 A/B WebRTC P2P 或经 RTC 服务(<500ms 双向)
       混流/旁路后 RTMP → CDN → 观众

 SFU：服务器只转发，客户端收多路，灵活、延迟低，下行带宽大
 MCU：服务端合流为一路，客户端省带宽，CPU/延迟高
 会议场景：视频常 SFU；音频可服务端混流(MCU)——音频小、混流收益大

 AEC：外放时扬声器声音被麦克风采集，需回声消除(WebRTC AudioProcessing / 系统 AEC)
 ICE：STUN 拿公网地址，TURN 中继兜底，候选连通性检测


 ============================================================
 九、视频会议（腾讯会议类）要点
 ============================================================

 架构：SFU 为主（非全量 MCU 合流）
 - 每人上行 1 路，下行 N-1 路；服务器不解码合屏
 - 音频例外：百人会议可服务端混成 1 路音频下行

 Simulcast：发送端同时发高/中/低清流，SFU 按窗口大小转发对应层

 大规模(100+)：
 - 按需订阅：只拉九宫格可见的 N 路
 - 说话人优先(VAD)：保障当前发言者码率与延迟
 - JitterBuffer 动态：网好缩小降延迟，网差扩大防卡

 Opus vs AAC（会议）：Opus 帧短、FEC/DTX/PLC，适合实时；AAC 适合直播录制


 ============================================================
 十、监控与质量指标（定义 + 采集 + 计算 + 排障）
 ============================================================

 【10.0 为什么要多层监控】

 单看「卡顿率」无法定位：可能是主播上行差、CDN 某省节点、客户端解码失败、或 DNS 慢。
 必须「客户端体验 + 源站推流 + CDN 分发」三源对齐，用 trace_id/stream_id 串一条链路。

 主播 App(推流SDK) → 推流接入(源站) → 转码/录制 → CDN边缘 → 观众 App(播放SDK)
       │                 │               │            │              │
   埋点+周期指标     publish日志      转码任务日志   access log      埋点+周期指标


 ──────────────────────────────────────────
 10.1 指标定义、公式、阈值、采集方
 ──────────────────────────────────────────

 【推流端】
 实际视频码率    sum(sendBytes)*8/windowMs → kbps；与 target 比得达成率    目标±20%    推流SDK
 实际/采集帧率   encode回调/秒 vs capture回调/秒                          ≥24         推流SDK
 编码丢帧率      (capture帧-encode帧)/capture帧                           <5%         推流SDK
 GOP间隔         相邻I帧 PTS 差(ms)                                       1~3s        推流SDK
 发送缓冲积压    queueBytes/(bitrate/8) 或 队列帧数*帧间隔                  >2s告警     推流SDK
 推流断连/重连   socket/RTMP错误次数、重连成功次数                          越低越好    SDK+源站
 推流成功率      成功publish次数/尝试次数                                   >99.5%      源站
 音视频PTS差     |lastVideoPTS-lastAudioPTS|                               <200ms      推流SDK
 音频采样率      采集/编码实际 Hz（与配置是否一致）                        44100/48000  推流SDK
 音频声道数      mono/stereo                                               与档位一致   推流SDK
 音频编码帧长    AAC 1024 采样/帧，可推算音频包间隔                         ~23ms@44.1k  推流SDK

 【播放端】
 首屏时间        t_first_render - t_play_click                            <800ms优    播放SDK
 首屏拆解        DNS/TCP/TLS/首字节/首I帧/解码/上屏 各阶段耗时               分段P95     播放SDK
 卡顿次数        buffering_start 事件计数                                   —           播放SDK
 卡顿时长        Σ(buffering_end - buffering_start)                       —           播放SDK
 卡顿率          卡顿时长/有效观看时长                                      <0.5%       平台聚合
 二次缓冲率      播放中进入buffering次数/观看次数                           <1%         播放SDK
 拉流码率        下载字节*8/窗口秒数                                        匹配档位    SDK+CDN
 播放成功率      首帧成功次数/play_start次数                                >99%        SDK
 硬解失败率      fallback软解次数/总解码                                    分机型      播放SDK
 E2E延迟         t_render - server_ts(SEI/UTC)，需服务端打戳                业务定义    服务端+SDK

 【网络】丢包(RTCP RR)、RTT(ping/RTCP)、Jitter(包间隔标准差)、ABR降档次数


 ──────────────────────────────────────────
 10.2 埋点事件与公共字段
 ──────────────────────────────────────────

 公共字段：event_name, event_time, trace_id, stream_id, room_id, uid(hash),
 app_version, sdk_version, os, device_model, network_type, carrier, role

 生命周期（必报）：
 live_push_start/stop/error/reconnect
 live_play_start/first_frame/buffering/error/stop

 周期质量（2~5s，埋点上报可抽样 10%，非音频采样率）live_push_quality / live_play_quality：
 video_bitrate, audio_bitrate, audio_sample_rate, audio_channels, audio_codec(aac/opus),
 fps_in, fps_out, gop_ms, send_buffer_ms, queue_depth, rtt_ms, stall_count, avg_download_kbps

 live_push_start 建议带上：target_audio_sample_rate, target_audio_channels, target_audio_bitrate

 ABR：live_abr_downgrade/upgrade（from_level, to_level, reason）


 ──────────────────────────────────────────
 10.3 iOS 推流端采集（挂点与算法）
 ──────────────────────────────────────────

 (1) 码率：RTMP send 处累加 bytes；每1s bitrate=bytes*8/1000 kbps
 (2) 帧率：captureOutput 与 VideoEncoderCallback 分别计数/秒
 (3) 关键帧：!CFDictionaryContainsKey(att, kCMSampleAttachmentKey_NotSync)
 (4) 积压：sendQueue 字节数/(实际码率/8) → send_buffer_ms；连续>2s打 live_push_stall
 (5) 断连状态机：Idle→Connecting→Publishing→Reconnecting→Stopped，映射 error_code/stage
 (6) PTS：编码回调更新 lastVideoPTS/lastAudioPTS，每秒检查 |v-a|>200ms
 (7) 音频采样率/声道：音频 CMSampleBuffer 取 formatDesc → ASBD.mSampleRate、mChannelsPerFrame
     与 AVAudioSession.sampleRate、AAC 编码器配置对比；不一致打 audio_format_mismatch
 统计放独立串行队列，勿阻塞编码线程


 ──────────────────────────────────────────
 10.4 iOS 播放端采集（挂点与算法）
 ──────────────────────────────────────────

 首屏拆解（强烈建议）：
 t0点击 → t1 DNS → t2 TCP/TLS(NSURLSessionTaskMetrics) → t3 HTTP首字节
 → t4首关键帧收齐 → t5解码出首帧 → t6上屏
 first_screen=t6-t0，子阶段一并上报，看P95卡在哪段

 卡顿主路径：onBufferingStart记录t_start，End时 stall_duration+=now-t_start，count++
 辅助：相邻渲染间隔>200ms且非seek/后台 → render_stall
 卡顿率 SQL：sum(stall_duration)/sum(watch_duration) 按版本/省份/CDN聚合

 成功率：分母 play_start，分子 first_frame且error=0；另报 dns/tcp/http/decode 分阶段失败率

 E2E：SEI写入 server_ts_ms，解码后 e2e=local_ms-server_ts（注意时钟skew）


 ──────────────────────────────────────────
 10.5 服务端 / CDN / WebRTC
 ──────────────────────────────────────────

 源站 publish 日志：stream_key, duration, disconnect_reason, avg_bitrate, avg_fps, codec, 分辨率
 CDN access：status, bytes_sent, request_time, cache_status(HIT/MISS), node_id, province, isp
 分析：某省MISS高+首包慢→边缘覆盖；5xx突增→源站/鉴权；bytes/时长远低于码率→大量卡顿退出
 WebRTC：RTCP fraction_lost/jitter；iOS RTCStatisticsReport inbound-rtp 周期上报
 转码：任务 submit→success 耗时、queue_depth


 ──────────────────────────────────────────
 10.6 上报、存储、大盘
 ──────────────────────────────────────────

 策略：生命周期事件立即上报；周期指标批量2~5s；失败入本地队列补发
 注意区分：「埋点采样」= 只上报 10% 用户的 quality 事件；「音频采样率」= 44100Hz 等，应全量上报在 start/quality 里

 源站 publish 日志建议增加：audio_sample_rate, audio_channels, audio_codec
 链路：HTTPS网关→Kafka→Flink(1min窗)→ClickHouse→Grafana(P50/P95/P99)
 下钻维度：version, sdk, device_level, network, cdn_node, protocol, province, anchor_id


 ──────────────────────────────────────────
 10.7 告警示例与排障顺序
 ──────────────────────────────────────────

 P0 播放成功率5min<90%且UV大 → 电话
 P1 卡顿率5min>3% / 推流断连>0.5% → 企微
 P2 首屏P95>2s / 单节点5xx>1% → 邮件或切流

 观众卡顿：成功率→error stage→首屏子阶段→CDN省份→同房间推流质量→源站断流→APM主线程卡
 花屏：推流丢帧/GOP/缺SPS-PPS→源站是否收全→CDN丢包

 拨测：机房定时拉流得基线首屏，区分「服务挂」vs「特定机型网络差」
 质量分(可选)：Q=w1*首屏+w2*(1-卡顿率)+w3*成功率，用于档位推荐与运营


 ============================================================
 十一、iOS 实现要点（无冗长代码）
 ============================================================

 【采集】AVCaptureSession preset → 音视频 Input/Output → delegate 得 CMSampleBuffer

 【编码】VTCompressionSessionCreate(H264/HEVC) → EncodeFrame(CVPixelBuffer)
         回调里判关键帧、抽 SPS/PPS、NALU 转 Annex-B 送 RTMP
         音频：AudioConverter PCM→AAC，或采集链直接 CMSampleBuffer

 【边推边录】编码后 fork：一路 RTMP，一路 AVAssetWriter.appendSampleBuffer
         expectsMediaDataInRealTime=YES；首帧须 I 帧；时间戳对齐

 【播放渲染】CVMetalTextureCache 将 NV12 零拷贝为 Y/UV 纹理，Shader YUV→RGB
         优于 BGRA 再转（少一次 CPU/GPU 格式转换）

 【后台推流】默认进后台停采集；
         beginBackgroundTask(约 3 分钟) / 音频后台+静态帧 / ReplayKit Extension

 【ReplayKit】
 - App 内 RPScreenRecorder.startCaptureWithHandler
 - 系统级 Broadcast Upload Extension + App Group 传帧给主 App

 【业务】礼物：SVGA/PAG/Lottie，串行队列防同时播；弹幕：Cell 复用 + 轨道算法防叠


 ============================================================
 十二、常见面试问答
 ============================================================

 Q：直播推流基本流程？
 A：采集→前处理→编码(H264+AAC)→封装(RTMP/FLV)→CDN→拉流→解码→同步→渲染。

 Q：H.264 直播关键参数？
 A：CBR、RealTime、禁 B 帧、GOP 1~2s；I/P/B 含义；码率随分辨率 ABR。

 Q：为什么直播用 AAC，连麦用 Opus？
 A：AAC 成熟兼容点播/直播；Opus 低延迟帧、内置 FEC/DTX/PLC，适合 WebRTC。

 Q：AVCC 和 Annex-B？RTMP 为什么要转？
 A：硬编输出长度前缀 NALU(AVCC)；RTMP/部分解复用要 0x00000001 起始码(Annex-B)。

 Q：音视频怎么同步？
 A：以音频播放时钟为基准，比较 videoPTS；超前等待、落后丢帧。

 Q：滑动时 NSTimer 暂停的原理？（延伸 RunLoop）
 A：Timer 在 DefaultMode，ScrollView 滑动切 TrackingMode，CommonModes 可双模式触发。

 Q：连麦架构？
 A：双方 WebRTC 低延迟；混流或旁路 RTMP 给观众；SFU 转发 vs MCU 合流取舍见上。

 Q：SFU 和 MCU？
 A：SFU 只转发、延迟低、客户端多路解码；MCU 服务端合一路、省下行、服务器重。

 Q：首屏/卡顿怎么排查？
 A：推流：GOP/缓冲/编码；传输：RTT/CDN/丢包；播放：JitterBuffer/解码/首 I 帧。

 Q：直播质量监控怎么做？卡顿率怎么算？
 A：客户端埋点+源站+CDN三源；播放端 buffering 起止算卡顿时长，卡顿率=卡顿时长/观看时长；
    周期上报码率/fps/缓冲积压；首屏拆 DNS/TCP/首字节/首 I 帧/解码/上屏；trace_id 串联全链路；
    Flink 聚 P95，告警看成功率/卡顿率/首屏；下钻 version/省份/CDN 节点定位。

 Q：首屏时间为什么要分段埋点？
 A：总耗时无法区分 DNS 慢、等 I 帧慢还是解码慢；分段后 P95 可直指优化点
    （预连接、低 GOP、播放器预热、硬解初始化等）。

 Q：直播音频采样率怎么选？采集和编码不一致会怎样？
 A：直播常用 44100Hz mono + AAC 64~128kbps；专业场景可用 48000Hz。
    采集、AudioSession、AudioConverter、封装、播放器必须一致，否则需显式重采样。
    不一致会出现变调、加速/变慢、杂音；监控应上报 audio_sample_rate 并与配置比对。

 Q：花屏/绿屏常见原因？
 A：丢包导致 NALU 不完整、YUV 格式混用、硬编异常、纹理格式不匹配。

 Q：Metal 渲染 NV12 为何更快？
 A：摄像头/解码原生 NV12，零拷贝进 GPU，Shader 转 RGB；避免 BGRA 中间转换。

 Q：App 进后台还能推流吗？
 A：默认不能持续采摄像头；短时后台任务、静态帧+音频、或 Broadcast Extension。

 Q：WebRTC 穿透 NAT？
 A：ICE：收集 host/srflx/relay，STUN 映射，TURN 中继，连通性检查选最优路径。

 */

@interface IBGroup3Controller18 ()

@end

@implementation IBGroup3Controller18

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
