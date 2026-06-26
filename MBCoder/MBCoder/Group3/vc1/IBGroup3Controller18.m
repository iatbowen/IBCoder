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


 ============================================================
 一、完整链路
 ============================================================

 采集 → 前处理(美颜/降噪) → 编码 → 封装 → 推流 → CDN → 拉流 → 解复用 → 解码 → 同步 → 渲染

 主播端：AVCaptureSession → GPU/Metal(美颜) → VideoToolbox H.264 + AudioConverter AAC → RTMP 封装推流
 观众端：HTTP-FLV/HLS/WebRTC → 解复用 → VideoToolbox 硬解 + AAC 软解 → Metal + AudioQueue

 ============================================================
 二、采集层
 ============================================================

 分辨率：360P / 480P / 720P / 1080P
 帧率：  15fps(弱网) / 24fps / 30fps(主流) / 60fps(游戏)

 iOS 核心要点：
 - AVCaptureSession + VideoDataOutput / AudioDataOutput
 - 像素格式：NV12(kCVPixelFormatType_420YpCbCr8BiPlanar*) → 硬编首选
             BGRA → GPUImage/Metal 美颜链首选
 - alwaysDiscardsLateVideoFrames = YES，防帧堆积
 - startRunning 放子线程；视频/音频各用独立串行队列
 - 帧率控制：activeVideoMinFrameDuration / MaxFrameDuration
 - AVAudioSession setPreferredSampleRate:44100；实际值以采集回调 ASBD.mSampleRate 为准，
   勿假设一定等于设置值；Category 选型见十三章 13.2
 - 从 CMSampleBuffer 读实际采样率：
   CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)->mSampleRate
 - 音频编码参数（采样率/声道/码率）见四章；CVPixelBuffer 内存管理见十三章 13.4


 ============================================================
 三、处理层（美颜/滤镜）
 ============================================================

 CMSampleBuffer → CVPixelBuffer → Metal/GPUImage/OpenGL
 磨皮：双边滤波（保边缘）  美白：色阶/色相  滤镜：3D LUT
 瘦脸/大眼：人脸关键点 + 局部网格变形（商汤/旷视/自研或 GPUImage）


 ============================================================
 四、编码层
 ============================================================

 【视频编码格式】
 - H.264(AVC)：兼容最好，直播主流；Profile/Level 选型见十三章 13.9
 - H.265(HEVC)：同画质码率约减半，编解码更重，CDN/Web 兼容性弱
 - VP9/AV1：Web 侧为主

 【音频编码格式】
 - AAC：直播/点播主流；每帧 1024 采样 → 帧时长 ≈ 1024/44100 ≈ 23.2ms（48k 约 21.3ms）
         ADTS 每帧带同步头(0xFFF)，可从任意位置解码，适合直播流
 - Opus：WebRTC/连麦，FEC/DTX/PLC，20ms 帧，低延迟
 - MP3：兼容好，实时性差

 【音频编码参数（全链路必须一致，否则变调/杂音）】
 - 采样率：44100Hz（直播推荐）/ 48000Hz（专业）；采集→AVAudioSession→AudioConverter→封装→播放器须一致
 - 声道：  1(mono) / 2(stereo)；直播语音省带宽用 mono
 - 码率：  64kbps(语音) / 96~128kbps(音乐级 mono) / 立体声可更高
 - PCM 未压缩数据率 ≈ sampleRate × channels × 16/8；例：44100×1×2 ≈ 88KB/s → AAC 约 64~128kbps
 - AudioConverter：输入/输出 ASBD sampleRate 不一致时自动重采样
 - Opus 常 48kHz；勿与 RTMP-AAC 44.1k 链路直接混用不重采样

 【视频编码参数（直播推荐配置）】
 - GOP：I(完整帧) / P(参考前帧) / B(参考前后，压缩最高，直播禁用)
 - 直播：CBR + RealTime=YES + AllowFrameReordering=NO(禁 B 帧) + GOP 1~2s
 - 参考码率：1080P 2~4Mbps / 720P 1~2Mbps / 480P 500kbps~1Mbps / 音频 64~128kbps

 【软编 vs 硬编】
 - 软编(x264)：质量/参数可控，CPU 高；直播降级参数：preset ultrafast + tune zerolatency
 - 硬编(VideoToolbox)：省电快；后台/过热场景需降级策略（详见十三章 13.5）

 【VideoToolbox 关键属性】
 kVTCompressionPropertyKey_RealTime = YES
 kVTCompressionPropertyKey_AllowFrameReordering = NO
 kVTCompressionPropertyKey_AverageBitRate / MaxKeyFrameInterval
 kVTEncodeFrameOptionKey_ForceKeyFrame（弱网强制插 I 帧）

 【AVCC vs Annex-B（必考）】
 - VideoToolbox 输出 AVCC：[4 字节长度][NALU]
 - RTMP 需 Annex-B：[00 00 00 01][NALU]
 - 转换：读 4 字节长度 → 替换为起始码；推流首包发 AVC Sequence Header(SPS+PPS)


 ============================================================
 五、封装、协议与推流
 ============================================================

 【协议对比（延迟 / 传输层 / 场景）】
 RTMP     1~3s     TCP       推流标准；握手流程
 HTTP-FLV 1~3s     HTTP      拉流，Web 常用（黄金组合：RTMP推流 + HTTP-FLV拉流）
 HLS      5~30s    HTTP/TCP  分片，iOS 原生友好，延迟高，适合点播
 WebRTC   <500ms   UDP+SRTP  连麦/会议
 SRT      <1s      UDP       弱网推流
 QUIC     极低     UDP       0-RTT，低延迟传输

 【RTMP Tag 结构】
 Video Tag：AVC Sequence Header(SPS+PPS) + NALU(I/P 帧)
 Audio Tag：AAC Sequence Header + AAC Raw
 Script Tag：onMetaData（码率/分辨率/时长等元信息）

 【推流鉴权与安全】见十三章 13.8

 【开源库】
 推流：LFLiveKit / 播放：IJKPlayer、VLCKit / 处理：FFmpeg、GPUImage / 实时：WebRTC


 ============================================================
 六、播放端架构
 ============================================================

 【数据流】
 网络 → 解协议 → 解复用(FLV/HLS/TS) → 音视频 Packet(含PTS/DTS)
      → VideoToolbox 硬解 + AAC 软解 → PCM/YUV
      → JitterBuffer(排序/平滑抖动) → 音视频同步
      → Metal 渲染(NV12零拷贝) + AudioQueue 播放

 【音视频同步】以音频时钟为基准，比较 videoPTS：
 超前(>+40ms) 等待；落后(<-40ms) 丢帧；误差内正常渲染
 PTS/DTS 区别与时间戳对齐见十三章（直播禁 B 帧后 PTS=DTS）

 【iOS 播放器 API 分层选型】
 高层：AVPlayer / AVPlayerLayer — HLS/MP4/本地，一行代码播放
 中层：AVSampleBufferDisplayLayer — 自定义渲染，系统管理同步
 低层：VideoToolbox + AudioUnit — 完全自定义，最低延迟（直播首选）
 混合：FFmpeg 解封装 + VideoToolbox 硬解 — 格式兼容性 + 低功耗

 【Metal 渲染 NV12（零拷贝）】
 CVMetalTextureCache 绑定 Y/CbCr 两平面纹理
 → Fragment Shader YUV→RGB 矩阵转换 → 上屏
 优于 BGRA：省去摄像头/解码器额外格式转换开销
 注意：纹理用完须 CVMetalTextureCacheFlush + 释放 textureRef（见十三章 13.4）


 ============================================================
 七、弱网与延迟优化
 ============================================================

 【延迟拆解（各环节量级）】
 采集~33ms + 编码~50ms + 网络~100~500ms + CDN~0~200ms + 解码~33ms + 渲染~16ms

 【弱网推流策略】
 - ABR（动态码率）：带宽估算 → 动态降/升码率、分辨率、帧率（升慢降快，防 Oscillation）
 - 丢帧优先级：B > P，保留 I
 - FEC：冗余恢复；NACK/RTCP：WebRTC 丢包重传反馈
 - 缓冲积压 > 2s：丢帧或降码率

 【延迟优化手段】
 - 小 GOP(1~2s)、禁 B 帧、小播放缓冲(极速模式 0.3~0.5s)
 - 追帧：播放缓冲 > 上限时以 1.2x 加速播放，降至目标水位后恢复 1x
 - 协议：超低延迟 WebRTC；弱网推流 SRT/QUIC；CDN 就近节点、减少跳数

 【首屏优化（目标 <1s，优秀 <500ms）】
 DNS 预解析 + TCP/QUIC 预连接 + 播放器预热 + 低 GOP 快出 I 帧 + 缩小 JitterBuffer + 行为预加载


 ============================================================
 八、连麦 vs 普通直播
 ============================================================

 普通：主播 RTMP → CDN → 观众（1~3s，单向）

 连麦：主播 A/B WebRTC P2P 或经 RTC 服务（<500ms 双向）
       混流/旁路后 RTMP → CDN → 观众

 SFU：服务器只转发，客户端收多路，灵活、延迟低，下行带宽大
 MCU：服务端合流为一路，客户端省带宽，CPU 重、延迟高
 最佳实践：SFU 主播/连麦侧（低延迟交互）+ MCU/CDN 观众侧（省带宽大规模分发）
 会议场景：视频常 SFU；音频可服务端 MCU 混流（音频数据小，混流收益大）

 AEC：外放时扬声器声音被麦克风采集 → 回声消除（WebRTC AudioProcessing / 系统 AEC）
 ICE：STUN 拿公网地址，TURN 中继兜底，候选连通性检测
 DTLS：UDP 上的 TLS，握手后建立 SRTP 加密通道


 ============================================================
 九、视频会议（腾讯会议类）要点
 ============================================================

 架构：SFU 为主（非全量 MCU 合流）
 - 每人上行 1 路，下行 N-1 路；服务器不解码合屏
 - 音频例外：百人会议可服务端 MCU 混成 1 路音频下行

 Simulcast：发送端同时发高/中/低清流，SFU 按窗口大小转发对应层

 大规模（100+）：
 - 按需订阅：只拉九宫格可见的 N 路
 - VAD 说话人优先：保障当前发言者码率与延迟
 - JitterBuffer 动态调整：网好缩小降延迟，网差扩大防卡（详见十三章 13.10）

 Opus vs AAC（会议）：Opus 帧短(20ms)、FEC/DTX/PLC，适合实时；AAC 适合直播/录制


 ============================================================
 十、推拉流质量检测与流畅性保障方案
 ============================================================

 【推流端 QoS 核心指标】
 上行码率：实际推流码率 vs 目标码率，波动 < 20%；偏差 = 1 - (实际/目标)
 发送帧率：实际 FPS ≥ 目标帧率的 85%
 关键帧间隔（GOP）：IDR 帧出现频率 1~3s；过大导致首屏慢，过小增加带宽
 编码耗时：单帧编码时间 < 帧间隔（1000/FPS ms），超出则丢帧
 发送队列堆积：待发送数据量 < 500KB；持续堆积说明网络跟不上编码产出
 RTT：推流端到服务器往返时延 < 200ms
 上行丢包率：数据包丢失比例 < 5%；> 5% 立即触发降码率

 【拉流端 QoE 核心指标】
 首帧时间（TTFF）：从起播请求到首帧渲染 < 1s（优秀 < 500ms）
 卡顿率：卡顿总时长 / 播放总时长 < 1%；卡顿率 = Σ卡顿时长 / 有效观看时长
 卡顿次数：单位时间内卡顿频率 < 3次/分钟；结合卡顿率共同衡量体验
 丢帧率：播放器丢帧计数持续增长 → 解码性能不足或码率过高
 缓冲区大小：当前已缓冲数据量，动态调整；< 500ms 预警，< 0 触发卡顿
 音视频同步差：音画偏差时长 < 100ms；偏差过大因时钟漂移或解码耗时不均
 端到端延迟：RTC < 400ms，直播 < 3s
 播放成功率：> 99%；失败细分为网络错误/解码失败/鉴权失败等

 【推流端优化】
 - ABR 动态码率：网络好 → 升码率/分辨率；网络差 → 降码率 → 降帧率 → 降分辨率（升慢降快防 Oscillation）
 - GOP 优化：I 帧间隔 1~2s，便于快速首屏与快速定位
 - 硬编优先：VideoToolbox 降低 CPU 占用；失败自动降级 x264（详见十三章 13.5）
 - 丢帧策略：发送队列堆积时优先丢 B/P 帧，保留 I 帧

 【传输层优化】
 - 协议选型：低延迟场景 WebRTC / SRT / QUIC；普通直播 RTMP + HTTP-FLV；点播 HLS / DASH
 - FEC 前向纠错：抗随机丢包
 - NACK 选择性重传：ARQ 补包
 - 多 CDN 调度：实时质量探测，自动切换最优节点

 【拉流端优化】
 - Jitter Buffer 自适应：网络抖动大 → 增加缓冲（抗卡顿但增延迟）；网络平稳 → 减小缓冲（降延迟）（详见十三章 13.10）
 - 追帧策略：缓冲 > high_watermark 时 1.2x 加速播放（WSOLA 变速不变调）追至目标水位
 - 快速首屏：CDN 边缘缓存 GOP，从最近 I 帧起播，缩小初始 JitterBuffer
 - 降级播放：弱网自动切换低码率流（HLS/DASH 多码率自适应）

 【监控数据采集】
 客户端 SDK 埋点 → 每 5~10s 上报：QoS（码率/帧率/丢包/RTT） + QoE（卡顿/首屏/延迟） + 异常事件（断流/重连/错误码）
 用 streamId + sessionId 串联推流→源站→CDN→拉流全链路，异常时一键回溯

 【告警阈值】
 P0：成功率 5min < 90% → 电话；卡顿率 > 5% 持续 1min → 即时通知
 P1：卡顿率 > 3% / 断连率 > 0.5% → 即时通知；首屏 P95 > 2s → 邮件
 P2：首屏时间 > 3s → 排查 CDN；推流断流率突增 → 检查源站

 【网络质量分级与推流策略】
 优秀（RTT < 100ms，丢包 < 1%）：保持当前参数
 一般（RTT < 300ms，丢包 < 5%）：适当降低码率
 较差（RTT ≥ 300ms，丢包 ≥ 5%）：触发降级策略（降分辨率/帧率/切软编）

 【推流异常类型】
 连接异常：握手失败 / 连接超时 / 服务器拒绝
 编码异常：编码器初始化失败 / 编码耗时过长 / 硬编降软编
 网络异常：码率骤降 / 丢包率升高 / 网络类型切换（WiFi→蜂窝）
 设备异常：摄像头断开 / 麦克风断开 / CPU 内存不足

 【ABR 多码率档位参考】
 超清 1080P 4Mbps / 高清 720P 2Mbps / 标清 480P 1Mbps / 流畅 360P 500Kbps
 切换冷静期：10s 内不重复切换，防频繁抖动

 【断线重连策略（指数退避）】
 第1次立即重连 → 失败等 2s → 失败等 4s → 失败等 8s → … 上限 30s → 超过最大次数通知用户
 重连时加随机抖动（jitter），防止大量客户端同时重连造成服务器雪崩

 【服务端监控指标】
 推流监控：推流连接数 / 推流码率 / 推流错误率 / 推流时长分布
 拉流监控：拉流连接数 / 出口带宽 / 拉流错误率 / CDN 命中率
 质量监控：端到端延迟 / 首帧时间 P99 / 全局卡顿率
 资源监控：服务器 CPU / 内存 / 带宽水位

 【端到端质量保障全流程】
 推流前：网络预检（带宽/延迟测试）+ 设备检测（摄像头/麦克风可用性）+ 参数预设（按网络选码率档位）
 推流中：每 3s 采集质量数据 + 实时异常检测告警 + ABR 动态调整 + 断线指数退避重连
 播放端：智能缓冲区管理 + 卡顿检测与追帧 + ABR 自动切换清晰度 + 质量数据实时上报
 事后分析：质量日报/周报统计 + 异常问题归因分析 + 持续优化迭代
 
 【典型问题排查】
 全局卡顿 → CDN 节点/源站/调度问题
 个别用户卡顿 → 用户网络/设备性能
 同地区卡顿 → 区域 CDN/运营商问题
 首屏慢 → GOP 过大/CDN 未缓存/DNS 解析慢
 延迟大 → 缓冲过大/转码链路过长
 音画不同步 → 时间戳问题/解码性能不足
 黑屏 → 推流端未发送视频数据
 绿屏 → NV12/I420 格式混用
 花屏 → 丢包导致 NALU 不完整 / I 帧丢失 P 帧无法参考

 【信令与流状态的关系】
 信令是控制面（协商/通知），流是数据面（传输音视频）；信令驱动流状态机跳转，流状态决定 UI 行为。

 信令  ──控制──>  流的建立/修改/终止
 流    ──反馈──>  触发新的信令动作

两者是 双向依赖、协同工作 的关系:
• 信令是"指挥官" - 决定流的生命周期
• 流状态是"执行者" - 实际数据传输
• 状态同步是"核心挑战"

 最佳实践：
 - 信令先于流：信令状态 ⊇ 流状态，信令建立成功才开始推/拉流，信令断开立即停止流
 - 双向同步：流状态异常（无数据/超时）需反馈给信令层，触发重协商或终止
 - 超时保护：信令超时 → 强制终止流；流数据超时（N 秒无帧）→ 触发信令重协商/断开
 - 原子操作：信令变更（切换码率/分辨率）与流变更保持一致，避免信令与实际流参数不同步

常见问题: 信令与流状态不一致

场景1: 信令成功但流未建立
 原因: NAT 穿透失败（WebRTC 无 TURN 兜底）/ DTLS 握手超时 / 编码器未启动无数据发送 / 采集权限被拒
 解决: 配置 TURN 服务器；检查编码器启动时序与采集权限

场景2: 流中断但信令未感知
 原因: WiFi→蜂窝切换 UDP 断但 TCP 信令靠重传短暂存活 / App 进后台系统挂起发包 / CDN 节点故障但源站信令仍在
 解决: 心跳检测（RTMP Ping/Pong、RTCP SR/RR）+ 流数据超时检测（N 秒无帧 → 判定断流）

场景3: 信令异常终止
 原因: 鉴权过期服务端主动断链 / App 被强杀 TCP 未优雅关闭服务端资源未释放 / 多端顶替旧端流资源未同步清理
 解决: 信令断开时立即停止编码发包；服务端超时兜底强制释放流资源


 ============================================================
 十一、iOS 实现要点
 ============================================================

 【采集】
 AVCaptureSession preset → 音视频 Input/Output → delegate 得 CMSampleBuffer
 AVAudioSession Category 选型见十三章 13.2（推流/连麦/播放/后台场景各不同）

 【编码】
 VTCompressionSessionCreate(H264/HEVC) → EncodeFrame(CVPixelBuffer)
 回调里判关键帧（!kCMSampleAttachmentKey_NotSync）→ 抽 SPS/PPS → NALU 转 Annex-B → 推流
 Profile/Level 选型见十三章 13.9；硬编失败降级策略见十三章 13.5
 音频：AudioConverter PCM→AAC；全链路采样率一致（见四章）

 【视频旋转/镜像】见十三章 13.6（推流场景推荐 SPS VUI 方向标记 + Shader 前置镜像翻转）

 【边推边录】
 编码后 fork：一路 RTMP，一路 AVAssetWriter.appendSampleBuffer
 expectsMediaDataInRealTime=YES；首帧须 I 帧；两路时间戳对齐（同一 CMClock）

 【播放渲染】
 CVMetalTextureCache NV12 零拷贝绑定 Y/UV 纹理 → Shader YUV→RGB → 上屏
 CVPixelBuffer/CVMetalTextureRef 内存管理见十三章 13.4

 【后台推流】
 - beginBackgroundTask（约 3 分钟）
 - Audio 后台模式（Info.plist）+ 静态帧持续推流
 - Broadcast Upload Extension + App Group 传帧（系统级，不受前后台限制）

 【ReplayKit】
 - App 内：RPScreenRecorder.startCaptureWithHandler
 - 系统级：Broadcast Upload Extension + App Group 传帧给主 App

 【业务层】
 - 礼物：SVGA/PAG/Lottie，串行队列防同时播
 - 弹幕：Cell 复用 + 轨道算法防叠
 - SEI 互动事件与视频帧绑定同步见十三章 13.3


 ============================================================
 十二、常见面试问答
 ============================================================

 Q：直播推流基本流程？
 A：采集→前处理→编码(H264+AAC)→封装(RTMP/FLV)→CDN→拉流→解码→同步→渲染。

 Q：H.264 直播关键参数？
 A：CBR、RealTime=YES、禁 B 帧(AllowFrameReordering=NO)、GOP 1~2s；
    码率按分辨率 ABR 动态调：1080P 2~4Mbps / 720P 1~2Mbps / 480P 500k~1Mbps。

 Q：为什么直播用 AAC，连麦用 Opus？
 A：AAC 成熟兼容，与 RTMP/HLS/点播生态深度绑定；
    Opus 低延迟（20ms 帧）、内置 FEC/DTX/PLC，适合 WebRTC 实时场景。

 Q：AVCC 和 Annex-B？RTMP 为什么要转换？
 A：VideoToolbox 硬编输出 AVCC（4 字节长度前缀 NALU）；
    RTMP/播放器解复用需要 Annex-B（0x00000001 起始码）。
    转换：读 4 字节长度 → 替换起始码；推流首包发含 SPS+PPS 的 AVC Sequence Header。

 Q：直播音频采样率怎么选？不一致会怎样？
 A：直播常用 44100Hz mono + AAC 64~128kbps；专业场景可用 48000Hz。
    全链路（AVAudioSession→采集→AudioConverter→封装→播放器）必须一致；
    不一致会出现变调、加速/变慢、杂音；监控须上报 audio_sample_rate 并与配置比对告警。

 Q：音视频怎么同步？
 A：以音频播放时钟为基准，比较 videoPTS：
    超前(>+40ms) 等待，落后(<-40ms) 丢帧，±40ms 内正常渲染。
    原因：人耳对时序误差比眼睛更敏感。

 Q：花屏/绿屏常见原因？
 A：丢包导致 NALU 不完整；推流端未发 SPS-PPS Sequence Header；
    YUV 格式混用（NV12/BGRA 搞混）；硬编异常；Metal 纹理格式不匹配。

 Q：Metal 渲染 NV12 为何更快？
 A：摄像头/解码器原生输出 NV12，CVMetalTextureCache 零拷贝绑定 GPU 纹理，
    Shader YUV→RGB 矩阵；避免 BGRA 中间格式转换的额外 CPU/GPU 开销。

 Q：App 进后台还能推流吗？
 A：默认不能持续采集摄像头；可用：beginBackgroundTask（约3分钟）、
    Audio 后台模式+静态帧、Broadcast Upload Extension（系统级，不受限）。

 Q：连麦架构？SFU 和 MCU 区别？
 A：双方 WebRTC <500ms 低延迟互通，混流/旁路 RTMP 给观众。
    SFU：只转发、延迟低、客户端多路解码；MCU：服务端合成一路、省带宽、服务器重。
    最佳实践：SFU 主播/连麦侧 + MCU/CDN 观众侧。

 Q：WebRTC 如何穿透 NAT？
 A：ICE 收集 host/srflx/relay 候选；STUN 获取公网映射地址；TURN 中继兜底；
    连通性检查选最优路径；DTLS 握手后建 SRTP 加密通道。

 Q：滑动时 NSTimer 暂停的原理？（延伸 RunLoop）
 A：Timer 在 DefaultMode，ScrollView 滑动切 TrackingMode，CommonModes 可双模式触发。

 Q：推流实际码率和目标码率为什么会不一样？如何监控？
 A：原因有四：
    ① 网络拥塞：TCP 拥塞控制压缩发送窗口，实际吞吐低于编码产出，发送队列积压后被丢弃或降速；
    ② 编码器波动：CBR 模式下复杂场景/场景切换需要更多 bits，I 帧体积远大于 P 帧，造成周期性码率突刺；
    ③ ABR 主动介入：SDK 检测到 RTT 增大/丢包/发送队列堆积后，主动下调目标码率，实际码率随之低于初始目标；
    ④ 设备性能瓶颈：过热降频导致硬编变慢 → 帧率下降 → 码率降低；alwaysDiscardsLateVideoFrames=YES 时主线程卡顿直接丢帧。
    监控：码率偏差 = 1 - (实际发送码率 / 目标码率)；偏差 > 20% 告警。
    偏差为正（实际低于目标）→ 大概率网络拥塞或设备过热；
    偏差为负（实际高于目标）→ 编码器 CBR 控制不稳或 I 帧突增。

 Q：直播质量监控怎么做？卡顿排查思路？各阶段阈值？
 A：三源对齐：客户端埋点 + 源站 publish 日志 + CDN access log，用 trace_id 串联全链路。
    卡顿率 = Σ卡顿时长 / 有效观看时长（buffering 起止打点）；阈值 <0.5%。
    首屏分段：t0点击→t1 DNS→t2 TCP/TLS→t3首字节→t4首I帧→t5解码→t6上屏，看 P95 卡在哪段。
    排查顺序：成功率→error stage→首屏子阶段→CDN省份→同房间推流质量→源站断流→APM主线程卡。
    推流阈值：码率偏差<20% / 丢帧率<5% / 缓冲积压<2s / RTT<200ms / 上行丢包<5%。
    播放阈值：首屏<800ms / 卡顿率<0.5% / 成功率>99% / E2E: RTC<400ms, 直播<3s。
    告警：P0 成功率5min<90%→电话；P1 卡顿率>3%/断连>0.5%→即时通知；P2 首屏P95>2s→邮件。

 Q：RTMP 推流握手过程？（详见十三章 13.1）
 A：C0/S0(1B版本号) + C1/S1(1536B时间戳+随机) + C2/S2(1536B echo)，共 3073 字节；
    握手后：connect → createStream → publish → onStatus(Publish.Start) 才可发音视频 Tag。

 Q：AVAudioSession Category 怎么选？（详见十三章 13.2）
 A：推流：Record；连麦：PlayAndRecord；播放：Playback；
    setCategory 须在 startRunning 前调用；来电/耳机中断需监听 Notification 重新 setActive。

 Q：PTS/DTS 区别？推流时间戳怎么对齐？
 A：无 B 帧 PTS=DTS；有 B 帧解码顺序≠显示顺序，DTS<PTS。
    直播禁 B 帧后，音视频须基于同一 CMClock；每秒检查 |videoPTS-audioPTS|<200ms，偏差过大重置基准。

 Q：SEI 是什么？直播里有什么用？（详见十三章 13.3）
 A：NALU 类型 0x06，携带用户自定义数据，不影响解码。
    用途：① 注入 server_ts_ms 计算 E2E 延迟；② 绑定礼物/弹幕时间戳与视频帧同步显示。

 Q：ABR 升降档策略？（详见十三章 13.7）
 A：升慢降快防 Oscillation：连续 3s 带宽稳定才升一档；带宽不足立即降（可跨多档）。
    带宽估算：滑动窗口吞吐量 × 0.8；极端弱网先降帧率再降分辨率。

 Q：CVPixelBuffer 内存管理注意点？（详见十三章 13.4）
 A：retain/release 严格配对；跨线程 CFRetain；VT 编码中勿手动 release；
    Metal 纹理用完须 CVMetalTextureCacheFlush + 释放 textureRef，否则 pool 耗尽卡顿。

 Q：VideoToolbox 硬编失败怎么降级？（详见十三章 13.5）
 A：回调 status!=noErr → 销毁 Session → 切 x264(ultrafast+zerolatency) → 上报 fallback 事件；
    前台后重建硬编 Session 切回；iOS 14+ 后台须配合 beginBackgroundTask 保活。

 Q：H.264 Profile/Level iOS 怎么选？（详见十三章 13.9）
 A：直播推荐 High 4.1（1080p/30fps，iOS VT 硬解上限）；
    兼容性要求高降为 Main 3.1 或 Baseline 3.1；H.265 用 HEVC_Main_AutoLevel(iOS 11+)。

 Q：视频旋转和镜像怎么处理？（详见十三章 13.6）
 A：推流场景：SPS VUI 写方向（编码零开销）+ Metal Shader 前置镜像翻转；
    录制：AVAssetWriter transform 写旋转矩阵；SPS 宽高须与物理分辨率一致。

 Q：JitterBuffer 动态调整原理？（详见十三章 13.10）
 A：三水位线：low(<0.3s卡顿) / target(~0.5s正常) / high(>1s追帧)。
    追帧：1.2x 加速播放（WSOLA 变速不变调）；WebRTC 基于 RTCP jitter 字段自适应。

 Q：推流鉴权防盗推怎么做？（详见十三章 13.8）
 A：URL 附带 MD5(push_key+stream_id+txTime) 签名；服务端验签失败断流；
    播放端 CDN 签名 URL + Referer 白名单；WebRTC DTLS-SRTP 端到端加密。


 ============================================================
 十三、查缺补漏（补充知识点）
 ============================================================

 ──────────────────────────────────────────
 13.1 RTMP 握手完整流程
 ──────────────────────────────────────────

 握手分三步，共交换 3073 字节：
 阶段       字节数   内容
 C0/S0      1        版本号（0x03 = RTMP 3）
 C1/S1      1536     timestamp(4B) + zeros(4B) + random(1528B)
 C2/S2      1536     echo：对端 C1/S1 的 timestamp + time2 + random echo

 握手后建连流程（chunk 流）：
 客户端 connect(app) → 服务端 _result(连接成功)
 → createStream → _result(stream_id)
 → publish(stream_name, "live") → onStatus("NetStream.Publish.Start")
 → 开始发送 Video/Audio Tag

 常见推流 chunk size：128 字节（默认），可通过 Set Chunk Size message 协商到 4096 提升效率。


 ──────────────────────────────────────────
 13.2 AVAudioSession 完整选型
 ──────────────────────────────────────────

 场景                     Category                           Option
 纯推流（无播放）          AVAudioSessionCategoryRecord        —
 连麦（边采边播）          AVAudioSessionCategoryPlayAndRecord  allowBluetooth / defaultToSpeaker
 纯播放（观众端）          AVAudioSessionCategoryPlayback       —
 后台播放                 AVAudioSessionCategoryPlayback       需 Info.plist background audio
 静音键不静音              AVAudioSessionCategoryPlayback       —（Playback 类型忽略静音键）

 关键注意点：
 · setCategory 须在 AVCaptureSession startRunning 前调用
 · 耳机插拔 / 来电中断 需监听 AVAudioSessionRouteChangeNotification / InterruptionNotification
 · 中断恢复后须重新 setActive:YES 并 restart AVCaptureSession


 ──────────────────────────────────────────
 13.3 SEI 结构与写入方式
 ──────────────────────────────────────────

 SEI NALU 结构：
 [NALU Header 0x06][payload_type 1B][payload_size 1B][payload data]

 常用 payload_type：
 5  = user_data_unregistered（自定义数据，直播最常用）
 1  = pic_timing（帧时间信息）
 45 = frame_packing_arrangement（3D 视频）

 直播注入 E2E 时间戳：
 payload = UUID(16B) + custom_json(如 {"ts":1717246512345})
 推流 SDK 在每个 IDR 帧后插入 SEI NALU，
 播放端解复用后从 CMSampleBuffer 的 attachments 或裸 NALU 流中提取。

 iOS 侧写入 SEI：VideoToolbox 不直接支持，需在 NALU 转 Annex-B 后手动拼接 SEI NALU 字节流。


 ──────────────────────────────────────────
 13.4 CVPixelBuffer 生命周期与 Pool 复用
 ──────────────────────────────────────────

 常见内存问题：
 1. CVPixelBuffer 未 release → 采集 pool 耗尽 → captureOutput 回调停止
 2. Metal 纹理未 flush CVMetalTextureCache → pixelBuffer 引用计数不归零
 3. 跨线程传递忘记 CFRetain → 野指针崩溃

 正确用法：
 // 采集回调持有
 CVPixelBufferRetain(pixelBuffer);
 dispatch_async(encodeQueue, ^{
     // 编码使用
     VTCompressionSessionEncodeFrame(session, pixelBuffer, ...);
     CVPixelBufferRelease(pixelBuffer);  // 编码提交后释放
 });

 VTCompressionSession 内部在编码完成前持有引用，
 编码回调(outputCallback)触发后系统自动 release，无需手动处理。

 CVMetalTextureCache 使用后必须：
 CVMetalTextureCacheFlush(textureCache, 0);
 CFRelease(textureRef);  // 释放 MTLTexture 包装对象


 ──────────────────────────────────────────
 13.5 VideoToolbox 硬编降级策略
 ──────────────────────────────────────────

 触发降级的常见场景：
 · 进入后台（iOS 14+ 后台硬编资源被系统回收）
 · 设备过热（SoC 降频，硬编单元不可用）
 · 特殊分辨率/帧率（超出 Level 限制）
 · 第一帧 status = kVTVideoEncoderMalfunctionErr

 降级流程：
 VTCompressionSession 回调 status != noErr
   → 销毁 Session（VTCompressionSessionInvalidate）
   → 切换 x264 软编（preset=ultrafast, tune=zerolatency）
   → 上报 hw_encode_fallback 事件
   → 后台返回前台后尝试重建硬编 Session，成功后切回

 软编 x264 推荐参数（直播）：
 profile=baseline / preset=ultrafast / tune=zerolatency
 keyint=fps*2（GOP） / bframes=0 / cbr / threads=2（省电）


 ──────────────────────────────────────────
 13.6 视频旋转与镜像完整方案
 ──────────────────────────────────────────

 iOS 摄像头默认输出方向：LandscapeRight（Home 键在右）
 前置摄像头额外问题：左右镜像（自拍镜像效果 vs 推流非镜像）

 方案对比：
 方案                  优点           缺点
 AVCaptureConnection   简单一行       部分格式不支持，增加 GPU 开销
 SPS VUI 写方向        编码零开销     服务端/CDN 需正确透传 display_orientation
 Metal Shader 变换     灵活高效       实现较复杂
 推流前 CPU 旋转        最兼容         内存拷贝开销大

 推荐：推流场景用 SPS VUI 方向标记 + Metal shader 镜像翻转（前置）；
       录制场景用 AVAssetWriter 的 transform 属性写入旋转矩阵。

 注意：SPS 里 width/height 必须是旋转前的物理分辨率，
 否则解码器按错误宽高分配缓冲区 → 花屏。


 ──────────────────────────────────────────
 13.7 ABR 带宽估算与防抖动
 ──────────────────────────────────────────

 推流端带宽估算方法：
 · 基于发送吞吐量：滑动窗口（3~5s）计算 bytes/s，乘以 0.8 得目标码率
 · 基于 RTT 变化：RTT 增大说明网络拥塞，提前降档（类 BBR 思路）
 · 基于丢包率：上行丢包 > 5% 立即降档

 升降档规则（防 Oscillation）：
 降档：任意 1 次检测到带宽不足 → 立即降至对应档位
 升档：连续 3~5 次检测带宽稳定超过上一档阈值 → 才升档
 档位间隔：降档幅度可跨多档（如 1080P 直降 480P）；升档每次只升一档

 直播常见档位（视频 + 音频）：
 超清  1080P  3Mbps  + AAC 128kbps
 高清  720P   1.5Mbps + AAC 96kbps
 标清  480P   800kbps + AAC 64kbps
 流畅  360P   400kbps + AAC 48kbps

 电商直播：客户端上传一路，服务端转码多路 + ABR 分发
 互动连麦：客户端多路上传（Simulcast） + SFU 转发
 视频会议：SVC 单路上传 + 智能转发

 ──────────────────────────────────────────
 13.8 推流鉴权与安全
 ──────────────────────────────────────────

 推流 URL 鉴权（txSecret/txTime 模式，腾讯云等常用）：
 txTime = 十六进制过期时间戳（如 5E7B8BC0）
 txSecret = MD5(push_key + stream_id + txTime)
 推流 URL：rtmp://domain/live/stream_id?txSecret=xxx&txTime=xxx

 服务端验签：
 · 解析 txTime，判断是否过期
 · 重新计算 MD5 与 txSecret 比对
 · 验签失败 → 断流，返回 NetStream.Publish.Unauthorized

 播放防盗链：
 · CDN 签名 URL（有效期 5~30min）防止 URL 被转发
 · Referer 白名单
 · IP 限速（同 IP 并发拉流数上限）

 端到端安全：
 · HTTPS-FLV / HLS 防明文抓包
 · WebRTC DTLS + SRTP 端到端加密（密钥不过 CDN）


 ──────────────────────────────────────────
 13.9 H.264 Profile/Level iOS 选型速查
 ──────────────────────────────────────────

 Profile              适用场景                    编解码复杂度
 Baseline 3.0         低端兼容、视频会议            最低（无B帧、无CABAC）
 Main 3.1             广播电视、中端直播             中
 High 4.0             720P/1080P 直播推荐           中高
 High 4.1             1080P/30fps iOS VT 硬解上限   高（iOS 主流选择）
 High 4.2             1080P/60fps                  高
 High 5.1             4K/60fps                     很高

 iOS VideoToolbox 设置方式：
 kVTProfileLevel_H264_High_4_1
 kVTProfileLevel_H264_Main_3_1
 kVTProfileLevel_H264_Baseline_3_0

 H.265 选型：kVTProfileLevel_HEVC_Main_AutoLevel（iOS 11+）
 注意：H.265 推流需 CDN 支持转码，Web 播放端兼容性弱，谨慎用于直播。


 ──────────────────────────────────────────
 13.10 JitterBuffer 与追帧完整机制
 ──────────────────────────────────────────

 JitterBuffer 本质：有序优先队列，按 PTS 排序，平滑乱序与抖动后送解码。

 三个水位线：
 low_watermark（如 0.3s）：缓冲不足，暂停解码等待（buffering 卡顿）
 target_delay（如 0.5s）：目标缓冲水位，正常播放
 high_watermark（如 1.0s）：缓冲过多，触发追帧

 追帧策略（低延迟直播关键）：
 · 缓冲 > high_watermark → 以 1.2x 速度加速播放（音频变速不变调：WSOLA 算法）
 · 缓冲降至 target_delay → 恢复 1.0x 正常速率
 · 缓冲 < low_watermark → 触发 buffering，等待缓冲积累到 target_delay 后恢复

 动态 JitterBuffer（WebRTC 方案）：
 · 实时估算网络 Jitter（RTCP RR jitter 字段 = 包间隔标准差 / 16）
 · target_delay = base_delay + jitter × 系数（自适应，网差时自动扩大）
 · 比固定缓冲策略更平滑，适合 RTC 场景
 
 ──────────────────────────────────────────
 13.11 直播画质优化有哪些策略
 ──────────────────────────────────────────
 采集端优化：
 1.硬件配置
 摄像头：优先使用单反/微单/专业摄像机，避免手机直采（除非旗舰机型）
 采集卡：使用专业采集卡（如 Elgato、Magewell）保证无损传输
 镜头选择：根据场景选定焦镜头（虚化突出商品）或广角（展示场景）
 
 2. 灯光布置
 三点布光法：主光 + 辅光 + 轮廓光
 色温统一（建议 5500K）避免偏色
 避免逆光、顶光造成的阴影
 商品特写区单独补光（如珠宝、服饰细节）

 编码端优化：
 1.编码器选择
 H.265/HEVC：同码率画质比 H.264 提升 30%-50%
 AV1：新一代编码，适合高端场景
 2. 码率策略
 1080P：建议 4-6 Mbps
 720P：建议 2-3 Mbps

 传输端优化
 1. 协议选择
 RTMP：兼容性好，延迟 3-5s
 SRT/QUIC：抗弱网能力强
 WebRTC：超低延迟（<1s），适合互动
 
 2. 网络保障
 双线/多线备份（有线 + 4G/5G 推流宝）
 上行带宽冗余 2 倍以上
 启用 BBR 拥塞控制算法
 
 3. CDN 调度
 多 CDN 厂商容灾
 就近接入节点
 边缘节点转码
 
 云端处理（核心增值）
 1. 超分辨率（Super Resolution）
 AI 超分：720P → 1080P/4K
 适用于移动端低码率推流场景
 
 2. 智能增强
 去噪：消除暗光噪点
 锐化：增强商品边缘细节
 HDR 增强：扩展动态范围
 色彩增强：提升商品色彩饱和度（服装、化妆品场景效果显著）
 
 3. ROI 感兴趣区域编码
 识别商品/主播区域，分配更多码率
 背景区域降低码率节省带宽
 
 4. 窄带高清（用更小的带宽（窄带），传输更清晰的画面（高清））
 阿里云、腾讯云、火山引擎均有此服务
 同等画质下码率降低 30-50%
 
 播放端优化
 1. 自适应码率（ABR）
 根据用户网络动态切换清晰度
 提供"超清/高清/标清"多档位
 
 2. 解码优化
 优先硬解，降低功耗发热
 弱设备降级播放策略
 
 场景化策略
 场景类型     重点优化
 服装类      色彩还原、布料质感、HDR
 美妆类      肤色自然、高清细节、避免过度美颜
 珠宝类      高码率、特写镜头、反光控制
 食品类      色彩饱和度、近景对焦
 数码 3C     文字清晰度、屏幕拍摄防摩尔纹
 
 ──────────────────────────────────────────
 13.12 SVC 分层编码
 ──────────────────────────────────────────
 核心思想：
 传统编码：1 路视频 = 1 个码流
 SVC 编码：1 路视频 = 基础层 + 多个增强层

 弱网用户：只解码基础层 → 流畅
 强网用户：解码全部层 → 高清
 
 SVC 的三种分层维度
 1. 时间分层（Temporal Scalability）⭐ 最常用
 通过帧率分层
 
 基础层 (T0):  I─────P─────P─────P    15fps
 增强层1(T1):    ↑P↑   ↑P↑   ↑P↑      +15fps = 30fps
 增强层2(T2):   ↑P↑P↑ ↑P↑P↑           +30fps = 60fps

 弱网：只拉 T0 → 15fps 流畅
 强网：拉 T0+T1+T2 → 60fps 高清
 特点：
 ✅ 实现简单，H.264/H.265 原生支持
 ✅ 兼容性好
 ✅ 几乎无编码损失
 
 合并渲染：增强层 = 插入更多帧
 基础层 T0:    帧0 ─────→ 帧4 ─────→ 帧8     （7.5fps）
 增强层 T1:        帧2 ─────→ 帧6             （+7.5fps = 15fps）
 增强层 T2:    帧1 帧3 帧5 帧7                 （+15fps = 30fps）
 合并后播放：帧0 帧1 帧2 帧3 帧4 帧5 帧6 帧7 帧8（30fps）
 
 2. 空间分层（Spatial Scalability）
 通过分辨率分层
 
 基础层: 360P
 增强层1: +到 720P
 增强层2: +到 1080P

 弱网：只解码基础层 360P
 强网：叠加到 1080P
 
 特点：
 ✅ 画质提升明显
 ❌ 编码效率损失 10-20%
 ❌ 实现复杂
 ❌ 硬件支持差
 
 本质：增强层 = 基础层的"超分信息"
 基础层:     360P 完整画面
 增强层1:    "如何从 360P 放大到 720P 的差异信息"
 增强层2:    "如何从 720P 放大到 1080P 的差异信息"
 
 解码过程：
 Step 1: 解码基础层 → 360P 画面
 Step 2: 上采样到 720P + 叠加增强层1 → 720P 画面
 Step 3: 上采样到 1080P + 叠加增强层2 → 1080P 画面
 Step 4: 输出最终 1080P 给渲染器
 
 3. 质量分层（Quality/SNR Scalability）：应用最少
 通过画质（量化参数）分层
 
 SVC 的"现实困境"：
 困境 1：编码端支持差（硬件编码器几乎不支持 SVC）
 困境 2：推流工具不支持 ，只有 WebRTC 生态部分支持（VP9 SVC、AV1 SVC）
 困境 3：观众端解码兼容性差
 困境 4：协议生态绑定，SVC 主要存活在 WebRTC 生态：
 
 */

@interface IBGroup3Controller18 ()

@end

@implementation IBGroup3Controller18

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
