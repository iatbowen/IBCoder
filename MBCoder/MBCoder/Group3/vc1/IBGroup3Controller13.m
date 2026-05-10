//
//  IBGroup3Controller13.m
//  MBCoder
//
//  Created by 叶修 on 2025/3/18.
//  Copyright © 2025 inke. All rights reserved.
//

#import "IBGroup3Controller13.h"

@interface IBGroup3Controller13 ()

@end

@implementation IBGroup3Controller13

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end

/*

 ============================================================
 WebRTC 原理与实践 面试题总结
 ============================================================

 一、WebRTC 整体架构
 ──────────────────────────────────────────

 【架构总览】

 +-----------------------+
 |     应用层（JS / ObjC） |
 | - getUserMedia        |
 | - RTCPeerConnection   |
 | - RTCDataChannel      |
 +----------+------------+
            |
 +----------v------------+
 |      Voice Engine     |
 | - 采集 / 预处理 (AEC)  |
 | - Opus 编码            |
 | - PLC / Jitter Buffer |
 +----------+------------+
            |
 +----------v------------+
 |      Video Engine     |
 | - 采集 / 分辨率适配     |
 | - VP8/VP9/H.264/AV1   |
 | - Simulcast / SVC     |
 +----------+------------+
            |
 +----------v------------+
 |       Transport       |
 | - ICE (STUN / TURN)   |
 | - SRTP / RTCP         |
 | - DTLS-SCTP           |
 +-----------------------+

 【三大核心引擎】

 Voice Engine（音频引擎）
   采集（getUserMedia / AVFoundation）→ 预处理 → Opus 编码 → 网络适应
   预处理模块：
   - AEC（Acoustic Echo Cancellation）：消除扬声器反馈到麦克风的回声
   - ANS（Ambient Noise Suppression）：降低环境噪声
   - AGC（Automatic Gain Control）：自动平衡音量波动
   - VAD（Voice Activity Detection）：静音检测，减少无效包传输
   编码：Opus 为默认（6kbps~510kbps，延迟 5~50ms）；G.711（PCMU/PCMA）用于传统电话兼容
   网络适应：动态码率调整、PLC（丢包补偿，插值修复丢包）、Jitter Buffer（平滑网络抖动）

 Video Engine（视频引擎）
   采集（getUserMedia / AVFoundation）→ 预处理 → 编码 → 网络适应
   预处理：分辨率/帧率动态适配、去噪/锐化、屏幕共享（getDisplayMedia）
   编码：VP8/VP9（开放格式，抗丢包强）、H.264（浏览器广泛兼容）、AV1（新一代，逐步普及）
   网络适应：
   - Simulcast：同时发送多分辨率流，接收端按带宽选择最优版本
   - SVC（可伸缩视频编码）：分基础层+增强层，弱网时只传基础层
   - FEC（前向纠错）：发送冗余包，接收端无需重传即可恢复
   - RTX（重传）：请求关键帧或丢失的包
   - NACK：接收端通知发送端某包丢失，触发重传

 Transport（传输层）
   ICE / STUN / TURN → SRTP（加密音视频）→ RTCP（质量监控）→ DTLS-SCTP（数据通道）
   拥塞控制：GCC（Google Congestion Control），基于延迟梯度 + 丢包率动态调整发送速率
   QoS：音频优先于视频（音频对延迟更敏感）；DSCP 标记网络优先级


 ============================================================
 二、WebRTC 源码目录结构
 ============================================================

 webrtc/
 ├── api/                           # 核心 API 层（跨平台接口）
 │   ├── audio/                     # 音频设备与处理 API
 │   ├── crypto/                    # 加密相关（DTLS / SRTP）
 │   ├── data_channel_interface.h   # 数据通道接口
 │   ├── peerconnection_interface.h # PeerConnection 核心接口
 │   ├── transport/                 # 网络传输抽象（NetworkMonitor）
 │   └── video/                    # 视频帧、编码器配置
 │
 ├── call/                          # 媒体流调度中枢
 │   ├── audio_send_stream.h        # 音频发送流管理
 │   ├── video_send_stream.h        # 视频发送流（Simulcast/SVC）
 │   └── bitrate_allocator.h        # 动态码率分配（带宽预测）
 │
 ├── media/                         # 媒体设备与引擎
 │   ├── base/                      # 设备管理（Camera / 麦克风）
 │   ├── engine/                    # 音视频引擎入口
 │   └── sdp/                       # SDP 格式解析与生成
 │
 ├── modules/                       # 核心功能实现
 │   ├── audio_processing/          # 音频处理（AEC3 / ANS）
 │   ├── audio_device/              # 音频设备抽象（各平台适配）
 │   ├── audio_coding/              # 音频编解码（Opus）
 │   ├── video_coding/              # 视频编解码（VP9 / AV1 / H.264）
 │   ├── rtp_rtcp/                  # RTP/RTCP 协议栈
 │   ├── congestion_controller/     # 拥塞控制（GCC / BBR）
 │   └── pacing/                    # 流量整形（Pacer，基于时间窗口）
 │
 ├── p2p/                           # P2P 网络传输
 │   ├── base/                      # ICE 框架（Port / Connection）
 │   └── client/                    # STUN / TURN 客户端
 │
 ├── pc/                            # PeerConnection 实现
 │   ├── peer_connection.h          # PC 核心逻辑
 │   ├── rtp_transmission_manager.h # RTP 流管理
 │   └── sdp_offer_answer.h         # SDP 协商（Unified Plan）
 │
 ├── rtc_base/                      # 基础库
 │   ├── network/                   # 网络地址与路由
 │   ├── thread/                    # 线程模型（TaskQueue）
 │   └── ssl/                       # DTLS / TLS 实现
 │
 ├── sdk/                           # 移动端 SDK
 │   ├── android/                   # Android 封装（Camera2 API）
 │   ├── ios/                       # iOS 封装（AVFoundation 适配）
 │   └── objc/                      # Objective-C 桥接层
 │
 └── test/                          # 测试框架
     ├── network/                   # 网络模拟（丢包 / 延迟）
     ├── video/                     # 视频质量分析（PSNR / SSIM）
     └── gtest/                     # 单元测试


 ============================================================
 三、P2P 连接建立完整流程
 ============================================================

 【信令 + ICE + DTLS 三阶段】

 阶段一：信令交换（Signaling，通过自建 WebSocket 服务器）

 1. 呼叫方（Caller）创建 RTCPeerConnection，调用 createOffer()
    → 生成 SDP Offer（包含：支持的编解码、分辨率、SRTP 密钥参数等）
 2. 呼叫方调用 setLocalDescription(offer)
    → 同时触发 ICE 候选收集（onIceCandidate 回调）
 3. 通过信令服务器将 SDP Offer 发送给被叫方
 4. 被叫方调用 setRemoteDescription(offer)，再 createAnswer()
    → 生成 SDP Answer（选择双方均支持的编解码等）
 5. 被叫方调用 setLocalDescription(answer)，通过信令返回 SDP Answer
 6. 呼叫方调用 setRemoteDescription(answer)，SDP 协商完成

 阶段二：ICE 候选交换（NAT 穿透）

 7. 双方各自收集 ICE 候选地址（三种类型，按优先级）：
    host  ：本地局域网 IP（最优，直接通信）
    srflx ：通过 STUN 服务器获取的公网 IP:Port（适合锥形 NAT）
    relay ：通过 TURN 服务器分配的中继地址（最后手段，适合对称 NAT）
 8. 通过信令服务器互换 ICE 候选（addIceCandidate）
 9. ICE 框架按优先级做 Connectivity Check（STUN Binding Request），选第一个连通的路径

 阶段三：DTLS 握手 + 媒体传输

 10. ICE 连通后，执行 DTLS 握手，协商 SRTP 加密密钥
 11. 建立 SRTP 通道，开始加密的音视频传输（RTP over UDP）
 12. RTCP 同步传输，持续反馈丢包率/RTT/抖动等质量指标

 【SDP 关键字段】
 v=    ：版本
 o=    ：会话来源（user, session-id, version, net-type, addr-type, addr）
 m=    ：媒体描述（audio/video + 端口 + 编解码列表）
 a=    ：属性（rtpmap 编解码映射、fmtp 参数、ice-ufrag/ice-pwd 认证）
 c=    ：连接地址


 ============================================================
 三、NAT 穿透：STUN / TURN / ICE
 ============================================================

 【NAT 类型与穿透难度】
 完全锥形（Full Cone NAT）     ：任何外网主机可向映射端口发包，穿透最容易
 地址限制锥形（Address Restricted）：只有发过包的外网 IP 才能回包
 端口限制锥形（Port Restricted）：发过包的 IP:Port 才能回包
 对称型（Symmetric NAT）       ：每个会话分配不同外网端口，STUN 无法穿透，必须 TURN 中继

 【STUN（Session Traversal Utilities for NAT）】
 设备向 STUN 服务器发送 Binding Request → 服务器返回观测到的公网 IP:Port（srflx 候选）
 局限：无法穿透对称型 NAT（约占 20% 的网络环境）

 【TURN（Traversal Using Relays around NAT）】
 设备向 TURN 服务器申请中继地址，所有数据经服务器转发（relay 候选）
 代价：延迟增加，带宽成本高（通常按流量计费），是保证连通性的最终兜底方案

 【ICE（Interactive Connectivity Establishment）】
 整合 STUN/TURN 的智能选路框架：
 1. 收集所有候选（host / srflx / relay）
 2. 按优先级排序：host > srflx > relay
 3. 对所有候选对做 Connectivity Check
 4. 选择第一个连通的候选对作为传输路径（可后续升级到更优路径）


 ============================================================
 四、多人连麦架构
 ============================================================

 【Mesh（全互联，P2P）】
 每个参与者与所有人建立独立 P2P 连接，N 人需要 N×(N-1)/2 条连接。
 优点：无服务器，延迟最低
 缺点：连接数随人数指数增长，带宽/CPU 压力大，适合 ≤4 人

 【SFU（Selective Forwarding Unit）】
 每个客户端只向 SFU 上传一路流，SFU 按订阅需求选择性转发给其他客户端。
 优点：带宽效率高（每人只上传一次），支持 50~100 人，可动态订阅
 缺点：需要服务器资源，单点故障需集群部署，略增延迟
 常见开源：mediasoup、Janus、LiveKit

 【MCU（Multipoint Control Unit）】
 服务器解码所有输入流，混合成一路（视频拼接网格布局 + 音频混音）后下发。
 优点：客户端压力最小，兼容性极佳，布局统一
 缺点：服务器计算成本极高，延迟高（编解码耗时），灵活性差
 适用：老旧设备、传统电视会议系统

 【SFU + Simulcast / SVC（推荐方案）】
 Simulcast：发送端上传多套分辨率（720p/360p/180p），SFU 按接收端带宽动态选路
 SVC      ：单流分层（Base Layer + Enhancement Layers），弱网时截断增强层即可

 【方案对比】
 Mesh          ：≤4 人，延迟最低，无服务器成本
 SFU           ：50~100 人，延迟中等，服务器成本中等（主流方案，如 Zoom/腾讯会议）
 MCU           ：100+ 人，延迟高，服务器成本极高（传统电话会议）
 SFU+Simulcast ：100+ 人，延迟中低，服务器成本中高（自适应码率场景）

 【信令服务器职责】
 无论哪种架构，均需信令服务器完成：
 - 房间管理（创建/加入/退出，维护成员列表）
 - SDP/ICE 候选中转（转发 Offer/Answer 和 ICE 候选）
 - 控制消息（静音/踢人/主讲人切换）
 技术选型：WebSocket / Socket.IO（Node.js）/ gRPC


 ============================================================
 五、关键类与 iOS 集成
 ============================================================

 【核心类说明】

 RTCPeerConnection
   管理本地与远端的 P2P 连接，处理 ICE/SDP/媒体流/数据通道的完整生命周期
   关键方法：createOffer / createAnswer / setLocalDescription / setRemoteDescription
             addIceCandidate / addTrack / getStats

 RTCSessionDescription
   封装 SDP 信息（媒体能力、网络参数），用于 Offer/Answer 协商

 RTCIceCandidate
   表示一个 ICE 候选地址，通过 onIceCandidate 回调收集后经信令发送给对端

 RTCRtpSender / RTCRtpReceiver
   RTCRtpSender  ：管理本地媒体编码与发送，可调整编码参数（码率/分辨率）
   RTCRtpReceiver：管理接收端媒体解码与播放

 RTCRtpTransceiver
   管理收发方向（sendrecv / sendonly / recvonly / inactive），支持动态切换

 RTCDataChannel
   P2P 上传输任意数据（文本/文件），无需服务器中转
   支持可靠（ordered，类 TCP）或不可靠（类 UDP）模式，适合游戏/文件共享

 RTCStatsReport
   通过 getStats() 获取连接统计：带宽、RTT、丢包率、抖动、编解码信息等

 【iOS 原生 WebRTC SDK（google/webrtc）】
 集成：通过 CocoaPods 引入 GoogleWebRTC / WebRTC-SDK

 采集：RTCCameraVideoCapturer（基于 AVFoundation），RTCAudioSession 管理音频会话
 视频轨：RTCVideoTrack + RTCCameraVideoCapturer + RTCVideoSource
 渲染：RTCMTLVideoView（Metal 渲染）或 RTCEAGLVideoView（OpenGL ES）

 硬件编解码：iOS SDK 默认启用 VideoToolbox 硬件加速（H.264）
   - 编码：VTCompressionSession → 输出 NALU → 封装为 RTP 包
   - 解码：NALU → VTDecompressionSession → CVPixelBuffer → MTLTexture → 渲染

 典型连接建立代码流程（Objective-C）：
   1. RTCPeerConnectionFactory 初始化（配置编解码器）
   2. RTCPeerConnection 创建（传入 ICE Server 列表 STUN/TURN）
   3. 添加本地音视频 Track（RTCVideoTrack / RTCAudioTrack）
   4. createOffer / setLocalDescription → 通过 WebSocket 发送 SDP
   5. 收到对端 SDP → setRemoteDescription
   6. 收到 ICE 候选 → addIceCandidate
   7. onAddStream / onTrack 回调收到远端流 → 绑定 RTCMTLVideoView 渲染


 ============================================================
 六、常见面试问题
 ============================================================

 Q：WebRTC 为什么使用 UDP 而不是 TCP？
 A：实时音视频对延迟敏感，TCP 的重传机制会造成额外延迟（队头阻塞）。
    UDP 丢包时通过 FEC/NACK/PLC 等应用层机制恢复，延迟可控。
    WebRTC 在 UDP 上构建了 RTP（媒体传输）+ RTCP（质量反馈）协议栈。

 Q：SRTP 和 RTP 的区别？
 A：SRTP（Secure RTP）在 RTP 基础上添加了加密（AES）和消息认证（HMAC-SHA1），
    防止音视频流被窃听和篡改。WebRTC 强制使用 SRTP，密钥通过 DTLS 协商获取。

 Q：Simulcast 和 SVC 有什么区别？
 A：Simulcast：发送端同时编码并上传多套完整独立的流（每套有自己的编码上下文），
              SFU 选择其中一套转发，切换时需要等待关键帧。
    SVC：      单路流内部分层，Enhancement Layer 依赖 Base Layer，
              SFU 可直接截断高层，无需等待关键帧，切换更平滑。
    Simulcast 实现简单，SVC 切换更平滑但编码复杂度高。

 Q：ICE 候选收集失败怎么办？
 A：ICE 分三类候选：host（直连）→ srflx（STUN）→ relay（TURN）。
    若 host 和 srflx 均失败（对称 NAT / 严格防火墙），ICE 会回退到 relay（TURN 中继），
    牺牲一定延迟和带宽成本换取 100% 连通性。
    TURN 服务器部署是 WebRTC 兜底保障的关键基础设施。

 Q：WebRTC 拥塞控制是如何工作的？
 A：WebRTC 使用 GCC（Google Congestion Control）算法：
    发送端：基于延迟梯度（到达时间变化趋势）估计可用带宽，动态调整发送速率。
    接收端：通过 RTCP Transport-CC Feedback 将每个包的到达时间戳反馈给发送端。
    当检测到拥塞时：降低码率（通知编码器降分辨率/质量），反之升高码率。

*/
