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
 一、WebRTC 整体架构
 +-----------------------+
 |     应用层（JS API）     |
 | - getUserMedia        |
 | - RTCPeerConnection   |
 | - RTCDataChannel      |
 +----------+------------+
            |
 +----------v------------+
 |      Voice Engine     |
 | - 采集/预处理          |
 | - Opus编码            |
 | - 网络适应（PLC/AGC）  |
 +----------+------------+
            |
 +----------v------------+
 |      Video Engine     |
 | - 采集/分辨率适配       |
 | - VP8/H.264编码       |
 | - Simulcast/SVC       |
 +----------+------------+
            |
 +----------v------------+
 |       Transport       |
 | - ICE (STUN/TURN)     |
 | - SRTP/RTCP           |
 | - DTLS-SCTP           |
 +-----------------------+

 三大核心引擎：Voice Engine（音频处理）、Video Engine（视频处理）和Transport（传输层）
 
 1. Voice Engine（音频引擎）
 负责音频数据的采集、处理、编解码和传输，核心功能包括：
 
 1.1 音频采集与预处理
 1.1.1 输入/输出设备管理：通过getUserMedia访问麦克风，获取原始音频流（PCM格式）。
 1.1.2 音频处理模块：
       - 回声消除（AEC）：消除扬声器到麦克风的回声。
       - 噪声抑制（NR）：降低环境噪声。
       - 自动增益控制（AGC）：平衡音量波动。
       - 静音检测（VAD）：减少无效数据传输。
 
 1.2 音频编解码
 - Opus：默认编码器，支持动态码率（6kbps~510kbps）、抗丢包和低延迟（5~50ms）。
 - 备用编码器：G.711（PCMU/PCMA）用于传统电话系统兼容。
 
 1.3 网络适应性
 - 动态码率调整：根据网络带宽实时调整音频码率。
 - 丢包补偿（PLC）：通过插值算法修复丢失的音频包。
 - 抖动缓冲（Jitter Buffer）：平滑网络延迟波动。
 
 2. Video Engine（视频引擎）
 负责视频数据的采集、处理、编解码和优化，核心功能包括：
 
 2.1 视频采集与处理
 2.1.1 摄像头捕获：通过getUserMedia获取视频流（原始帧，如YUV或RGB）。
 2.1.2 视频处理模块：
       - 分辨率/帧率适配：根据网络条件动态调整（如从1080p降至720p）。
       - 图像增强：去噪、锐化、色彩校正。
       - 屏幕共享：支持getDisplayMedia捕获桌面或应用窗口。
 
 2.2 视频编解码
 - VP8/VP9：WebRTC默认支持的开放编码格式，抗丢包能力强。
 - H.264：浏览器广泛兼容的格式（如Safari强制要求）。
 - AV1：下一代编码格式（逐步支持，节省带宽）。
 - 关键帧（I帧）请求：在网络差时快速恢复画面。
 
 2.3 网络适应性
 2.3.1 自适应码率（Simulcast/SVC）：
       - Simulcast：同时发送多分辨率流，接收端选择最优版本。
       - SVC（可分层编码）：将视频分为基础层和增强层，弱网时仅传输基础层。
 2.3.2 丢包恢复：
       - 前向纠错（FEC）：发送冗余数据包。
       - 重传（RTX）：请求关键帧或丢失的包。
 
 3. Transport（传输层）
 负责建立可靠、安全的端到端连接，核心功能包括：
 
 3.1 连接建立与管理
 3.1.1 ICE（Interactive Connectivity Establishment）：
       - 通过STUN服务器获取公网IP/端口，尝试P2P直连。
       - 若直连失败，使用TURN服务器中继流量。
 3.1.2 NAT穿透：支持对称NAT、锥形NAT等多种网络拓扑。
 
 3.2 协议栈
 - SRTP（Secure RTP）：加密音视频流，防止窃听。
 - RTCP（RTP Control Protocol）：监控传输质量（如丢包率、延迟）。
 - SCTP over DTLS：为RTCDataChannel提供可靠/不可靠的数据传输。
 - DTLS（Datagram TLS）：用于密钥交换和连接认证。
 
 3.3 网络优化
 3.3.1 拥塞控制：基于Google的GCC（Google Congestion Control）算法，动态调整发送速率。
 3.3.2 优先级与 QoS：
       - 音频优先于视频（因音频对延迟更敏感）。
       - 支持DSCP（差分服务代码点）标记网络优先级。
 
 二、WebRTC 源码目录结构
 webrtc/
 ├── api/                          # 核心API层（跨平台接口）
 │   ├── audio/                    # 音频设备与处理API
 │   ├── crypto/                   # 加密相关（DTLS、SRTP）
 │   ├── data_channel_interface.h  # 数据通道接口
 │   ├── peerconnection_interface.h # PC核心接口
 │   ├── transport/                # 网络传输抽象（如 NetworkMonitor）
 │   └── video/                    # 视频帧、编码器配置
 │
 ├── call/                         # 媒体流调度中枢
 │   ├── audio_send_stream.h       # 音频发送流管理
 │   ├── video_send_stream.h       # 视频发送流（支持Simulcast/SVC）
 │   └── bitrate_allocator.h       # 动态码率分配（基于带宽预测）
 │
 ├── media/                        # 媒体设备与引擎
 │   ├── base/                     # 设备管理（Camera/麦克风）
 │   ├── engine/                   # 音视频引擎入口
 │   └── sdp/                      # SDP格式解析与生成
 │
 ├── modules/                      # 核心功能实现
 │   ├── audio_processing/         # 音频处理（AEC3、噪声抑制）
 │   ├── audio_device/             # 音频设备抽象（各平台适配）
 │   ├── audio_coding/             # 音频编解码（Opus）
 │   ├── video_coding/             # 视频编解码（VP9/AV1/H.264）
 │   ├── rtp_rtcp/                 # RTP/RTCP协议栈
 │   ├── congestion_controller/    # 拥塞控制（GCC2、BBR）
 │   └── pacing/                   # 流量整形（基于时间窗口）
 │
 ├── p2p/                          # P2P网络传输
 │   ├── base/                     # ICE框架（Port、Connection）
 │   └── client/                   # STUN/TURN客户端
 │
 ├── pc/                           # PeerConnection实现
 │   ├── peer_connection.h         # PC核心逻辑
 │   ├── rtp_transmission_manager.h # RTP流管理
 │   └── sdp_offer_answer.h        # SDP协商（Unified Plan）
 │
 ├── rtc_base/                     # 基础库
 │   ├── network/                  # 网络地址与路由
 │   ├── thread/                   # 线程模型（TaskQueue）
 │   └── ssl/                      # DTLS/TLS实现
 │
 ├── sdk/                          # 移动端SDK
 │   ├── android/                  # Android封装（Camera2 API）
 │   ├── ios/                      # iOS封装（AVFoundation适配）
 │   └── objc/                     # Objective-C桥接
 │
 └── test/                         # 测试框架
     ├── network/                  # 网络模拟（丢包/延迟）
     ├── video/                    # 视频质量分析（PSNR/SSIM）
     └── gtest/                    # 单元测试
 
 三、WebRTC 关键类
 1. 连接管理类
 - RTCPeerConnection
 作用：管理本地与远端之间的P2P连接，处理信令、编解码协商、网络传输等。
 关键功能：
 ICE（Interactive Connectivity Establishment）候选地址收集。
 SDP（Session Description Protocol）交换（Offer/Answer模型）。
 媒体流（MediaStream）的添加/移除。
 数据通道（RTCDataChannel）的创建。
 
 - RTCDataChannel
 作用：在P2P连接上传输任意数据（如文本、文件），类似WebSocket但无需服务器中转。
 关键特性：
 支持可靠（TCP-like）或不可靠（UDP-like）传输模式。
 低延迟，适用于游戏、文件共享等场景。
 
 2. 媒体处理类
 - MediaStream
 作用：表示音视频流（如摄像头、麦克风或屏幕共享的流）。
 关键组件：
 MediaStreamTrack：流的单个轨道（如音频轨或视频轨）。
 可通过getUserMedia()获取本地设备流，或通过RTCPeerConnection接收远端流。
 
 - MediaStreamTrack
 作用：表示媒体流的单个轨道（如音频或视频），支持动态控制（启停、分辨率调整等）。
 RTCRtpSender / RTCRtpReceiver
 作用：
 RTCRtpSender：管理本地媒体数据的编码和发送。
 RTCRtpReceiver：管理接收到的远端媒体数据的解码和播放。
 
 3. 信令与网络类
 - RTCIceCandidate
 作用：表示ICE候选地址（本地网络可能的连接路径），用于NAT穿透。
 流程：通过onicecandidate事件收集候选，并通过信令服务器交换。
 
 - RTCSessionDescription
 作用：封装SDP信息（媒体能力、网络参数等），用于RTCPeerConnection的Offer/Answer协商。
 
 4. 统计与监控类
 - RTCStatsReport
 作用：通过getStats()获取连接统计信息（如带宽、延迟、丢包率等），用于监控和调试。
 
 5. 其他辅助类
 - RTCPeerConnectionIceEvent
 作用：ICE候选地址相关的事件对象（如icecandidate事件）。
 - RTCRtpTransceiver
 作用：管理媒体流的收发方向（如sendrecv、recvonly），支持动态调整。
 
 6. 关键流程中的类交互
 - 建立连接：
 getUserMedia() → MediaStream → 添加到RTCPeerConnection。
 createOffer() → RTCSessionDescription → 通过信令交换。
 addIceCandidate()处理ICE候选。
 - 数据传输：
 createDataChannel()创建RTCDataChannel。
 - 监控：
 getStats()返回RTCStatsReport。
 
 四、P2P 连接
 WebRTC 的 P2P 连接建立依赖于 NAT 穿透技术，而 STUN、TURN 和 ICE 是解决 NAT 和防火墙问题的核心协议。以下是它们的作用及协作关系：

 1. NAT（Network Address Translation）
 作用：NAT 是路由器将私有 IP（如 192.168.1.2）映射为公网 IP 的技术，但会导致：
 - P2P 连接障碍：设备隐藏在 NAT 后，无法直接被外网访问。
 - 对称型 NAT 问题：不同会话分配不同端口，难以预测通信地址。
 注意：WebRTC 必须解决 NAT 穿透问题才能建立直接连接。

 2. STUN（Session Traversal Utilities for NAT）
 作用：STUN 协议用于 发现设备的公网 IP 和端口，帮助绕过 NAT 限制。
 工作流程：
 - 设备向 STUN 服务器（如 Google 的 stun.l.google.com:19302）发送请求。
 - STUN 服务器返回设备的 公网 IP:Port（即 srflx 候选地址）。
 - 双方交换此地址，尝试直接 P2P 连接。
 局限性：
 - 无法穿透 对称型 NAT 或严格防火墙。
 - 仅适用于约 80% 的网络环境。
 
 3. TURN（Traversal Using Relays around NAT）
 作用：当 STUN 失败（如对称 NAT 或防火墙阻挡），TURN 作为 中继服务器 转发所有数据：
 - 设备与 TURN 服务器建立连接。
 - 数据通过 TURN 服务器中转（relay 候选地址）。
 - 牺牲性能（延迟高、带宽成本高），但保证连通性。
 关键点：是最后手段（ICE 优先尝试 STUN）。需要服务器资源和带宽，通常按流量计费。
 
 4. ICE（Interactive Connectivity Establishment）
 作用：ICE 是 整合 STUN/TURN 的智能决策框架，用于选择最优连接路径。
 工作流程：
 - 收集候选地址：
   host：本地局域网 IP（如 192.168.1.2）。
   srflx：通过 STUN 获取的公网 IP（如 1.2.3.4:5000）。
   relay：通过 TURN 分配的中继地址（如 5.6.7.8:3000）。
 - 优先级排序：直连（host） > STUN（srflx） > TURN（relay）。
 - 连通性测试：按优先级尝试连接，选择第一个成功的方案。

 五、多人连麦
 1. 基础方案：Mesh 网络（全互联模式）
 原理：每个参与者与其他所有人建立 独立的 P2P 连接，形成网状结构（Mesh）。
 示例：3 人会议时，每个客户端需维护 2 条连接（A↔B, A↔C, B↔C）。

 实现方式
 - 通过多个 RTCPeerConnection 实例管理不同对端。
 - 信令服务器协调 SDP 和 ICE 候选交换。
 优缺点
 优点                           缺点
 无需中心服务器，纯 P2P    连接数随人数呈指数增长（N*(N-1)/2）
 低延迟（直接传输）        带宽/CPU 压力大（每人需上传多份流）
 适合小规模（≤4人）        无法扩展
 
 2. 优化方案：SFU（Selective Forwarding Unit）
 2.1 原理：引入 SFU 服务器 作为中间节点，负责 选择性转发 媒体流：
 - 每个客户端仅上传 1 份流 到 SFU。
 - SFU 根据订阅需求（如仅看主讲人）转发流给其他客户端。
 
 2.2 典型架构
 flowchart TB
     A[客户端A] -->|发送流| SFU
     B[客户端B] -->|发送流| SFU
     C[客户端C] -->|发送流| SFU
     SFU -->|转发A的流| B & C
     SFU -->|转发B的流| A & C
 
 2.3 技术实现
 - 协议支持：使用 RTCPeerConnection 连接 SFU（类 P2P，实际是 C/S）。
 - 流控制：通过 RTCRtpTransceiver 动态开关订阅的流。
 - 开源 SFU： mediasoup（高性能，支持 WebRTC）、Janus（插件化架构）
 
 2.4 优缺点
 优点                           缺点
 带宽效率高（每人只上传一次）       需要服务器资源
 支持大规模（50~100人）           单点故障风险（需集群部署）
 可动态调整订阅（如只收音频）       略增延迟（服务器中转）
 
 3. 高级方案：MCU（Multipoint Control Unit）
 原理：MCU 服务器 混合所有参与者的音视频流，生成单一合成流再下发：
 - 视频：将多画面拼接为网格布局（如 2x2）。
 - 音频：混音后输出。
 
 适用场景
 老旧设备（无法处理多流解码）。
 需要固定布局（如电视会议系统）。
 
 技术实现
 - 编解码处理：需解码所有输入流，重新编码合成流。
 - 开源 MCU：Jitsi（支持 SFU/MCU 混合模式）、Kurento（已逐渐被淘汰）
 
 优缺点
 优点                         缺点
 客户端压力小（只需处理1路流）    服务器计算成本极高
 兼容性极佳                    延迟高（编解码耗时）
 布局统一                      灵活性差（无法单独订阅某一路）
 
 4. 混合方案：SFU + Simulcast/SVC
 优化手段
 - Simulcast（ simulcast）：发送端上传 多分辨率流（如 720p/360p），SFU 根据接收端网络选择合适版本。
 - SVC（可伸缩视频编码）：单流分层（Base Layer + Enhancement Layers），动态裁剪部分层以适应带宽。

 5. 信令服务器设计
 无论采用何种方案，均需 信令服务器 协调以下任务：
 - 房间管理：创建/加入房间，维护成员列表。
 - SDP/ICE 交换：转发 Offer/Answer 和 ICE 候选。
 - 控制消息：如静音、踢人、主讲人切换。
 
 技术选型：
 - 协议：WebSocket、Socket.IO。
 - 开源实现：SignalR（.NET）、Socket.IO（Node.js）
 
 6. 完整架构示例（SFU + Simulcast）
 flowchart TB
     subgraph Clients
         A[客户端A] -->|WebSocket| Signaling
         B[客户端B] -->|WebSocket| Signaling
         C[客户端C] -->|WebSocket| Signaling
     end

     subgraph Server
         Signaling[信令服务器] -->|控制信令| SFU
         SFU[SFU 节点] -->|转发流| A & B & C
     end
 
 总结：如何选择方案？
 方案           人数上限     延迟    服务器成本    适用场景
 Mesh（全互联）    ≤4人      最低    无          小规模加密通信
 SFU           50~100人    中      中          主流视频会议（Zoom）
 MCU            100+人     高      极高        传统电话会议系统
 SFU+Simulcast  100+人     中低    中高        需要自适应码率的场景

*/

