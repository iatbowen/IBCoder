//
//  IBGroup2Controller28.m
//  MBCoder
//
//  Created by BowenCoder on 2020/8/1.
//  Copyright © 2020 inke. All rights reserved.
//

#import "IBGroup2Controller28.h"

/*

 ============================================================
 网络库、协议与 iOS 网络优化 面试题总结
 ============================================================

 一、libcurl 与 Cronet 对比
 ──────────────────────────────────────────

 libcurl
 - C 语言编写，跨平台（Windows / Linux / macOS / iOS / Android）
 - 协议覆盖广：HTTP、HTTPS、FTP、SMTP、SFTP 等数十种
 - 接口简单，同步为主，异步需自行管理线程或事件循环
 - 适合：嵌入式设备、自动化工具、多协议场景

 Cronet（Chrome 网络栈）
 - 基于 Chromium 网络栈，支持 HTTP/1.1、HTTP/2、QUIC（HTTP/3）
 - 专为移动端高性能设计：异步 API、连接池、证书缓存、带宽预测
 - 低延迟：QUIC 协议 0-RTT 连接，弱网表现优异
 - 协议限于 HTTP/HTTPS，不如 libcurl 广泛
 - 适合：Android / iOS 高性能网络、有 QUIC 需求的场景（抖音、YouTube 等均使用）

 选型建议：
 - 需要多协议支持或跨平台 C 层集成 → libcurl
 - 移动端追求低延迟、弱网优化、HTTP/2 / QUIC → Cronet


 ============================================================
 二、HTTP 协议演进
 ============================================================

 【HTTP/1.0】
 - 每次请求建立一个 TCP 连接，响应后立即关闭（短连接）
 - 并发多个请求需要建立多个 TCP 连接，开销大

 【HTTP/1.1】
 - 默认开启持久连接（Keep-Alive），同一 TCP 连接可复用发送多个请求
 - 管道化（Pipelining）：允许客户端不等响应就发送多个请求，但服务端必须按序响应
 - 队头阻塞（Head-of-Line Blocking）：前面的请求未完成，后续响应被阻塞
 - 浏览器通常对同一域名开 6 个并发 TCP 连接绕过此限制

 【HTTP/2】
 - 二进制分帧（Binary Framing）：将数据分割为帧（Frame），替代文本协议
 - 多路复用（Multiplexing）：同一 TCP 连接上并发多个流（Stream），彻底解决 HTTP 层队头阻塞
 - 头部压缩（HPACK）：使用静态/动态表压缩重复头部，减少冗余数据
 - 服务器推送（Server Push）：服务端主动推送资源，减少客户端请求次数
 - ⚠️ TCP 层的队头阻塞依然存在：一个 TCP 包丢失会阻塞所有流

 【HTTP/3（QUIC）】
 - 基于 UDP，QUIC 在应用层实现可靠传输，彻底解决 TCP 层队头阻塞
 - 0-RTT / 1-RTT 握手：已知服务端时可 0-RTT 直接发送数据（HTTP/2 需要 TCP 三次握手 + TLS 握手）
 - 连接迁移（Connection Migration）：网络切换（WiFi → 4G）不断开连接，靠 Connection ID 标识
 - 内置 TLS 1.3：加密是 QUIC 协议的强制要求，无明文传输
 - 适合：弱网、移动网络频繁切换场景（视频流、直播、即时通信）


 ============================================================
 三、HTTPS 与 TLS 握手
 ============================================================

 【HTTPS = HTTP + TLS/SSL】
 TLS（Transport Layer Security）在 TCP 和 HTTP 之间提供加密、身份验证和数据完整性保护。

 【TLS 1.2 握手流程（4 次握手，2-RTT）】
 1. Client Hello：客户端发送支持的 TLS 版本、加密套件列表、随机数（Client Random）
 2. Server Hello：服务端选择加密套件、返回随机数（Server Random）、数字证书（含公钥）
 3. 客户端验证证书：验证证书链、有效期、域名匹配；生成预主密钥（Pre-Master Secret），
    用服务端公钥加密后发送
 4. 双方各自使用 Client Random + Server Random + Pre-Master Secret 生成会话密钥（Session Key）
 5. 后续使用对称加密（AES 等）加密通信

 【TLS 1.3 握手（1-RTT，更快）】
 - 移除了不安全的加密套件（RSA 密钥交换），只支持 ECDHE
 - 客户端在 Client Hello 中直接附带密钥交换参数，服务端一次往返即可完成握手
 - 支持 0-RTT 恢复（Session Resumption），已建立过连接的请求可跳过握手

 【证书验证】
 - 证书由 CA（Certificate Authority）签发，形成信任链：根证书 → 中间证书 → 服务端证书
 - 系统内置受信任根 CA 列表，客户端沿链验证每级签名
 - OCSP（Online Certificate Status Protocol）：实时查询证书是否被吊销

 【SSL Pinning（证书绑定）】
 客户端内置服务端证书（或公钥指纹），连接时对比服务端下发的证书，不匹配则拒绝连接。
 防止中间人攻击（Charles / Fiddler 抓包原理即在此处被拦截）。
 iOS 实现：在 NSURLSessionDelegate 的 didReceiveChallenge: 中手动验证。


 ============================================================
 四、iOS 网络层架构
 ============================================================

 【NSURLSession（iOS 7+，推荐）】
 苹果现代网络 API，替代已废弃的 NSURLConnection。

 核心组件：
 - NSURLSession：会话对象，管理一组相关请求，持有配置和代理
 - NSURLSessionConfiguration：配置请求策略（缓存、Cookie、超时、后台传输等）
   - defaultSessionConfiguration：默认，使用磁盘缓存和 Cookie
   - ephemeralSessionConfiguration：隐私模式，无磁盘缓存，关闭 Cookie
   - backgroundSessionConfiguration：后台传输，App 挂起后继续下载/上传
 - NSURLSessionTask：具体任务
   - NSURLSessionDataTask：普通数据请求（GET/POST）
   - NSURLSessionDownloadTask：文件下载，支持断点续传
   - NSURLSessionUploadTask：文件上传
   - NSURLSessionStreamTask：TCP/TLS 流式数据

 【HTTP/2 多路复用支持】
 NSURLSession 底层自动支持 HTTP/2，同一 Session 对同一域名的并发请求会复用连接。

 【AFNetworking】
 基于 NSURLSession 的封装，提供：序列化/反序列化、安全策略（AFSSLPinningMode）、
 网络状态监听（AFNetworkReachabilityManager）、请求/响应管理等。


 ============================================================
 五、iOS 网络优化策略
 ============================================================

 【连接优化】
 1. 使用 HTTP/2 或 QUIC：多路复用减少连接数，降低握手延迟
 2. 连接复用：同一 NSURLSession 实例管理同域名请求，避免重复建连
 3. DNS 优化：
    - DNS 预解析（HTTPDNSPreFetch）：App 启动时提前解析常用域名
    - HTTPDNS：绕过运营商 DNS 污染，直接通过 HTTP 查询 IP，避免 LocalDNS 劫持
 4. 连接池（Connection Pooling）：维护长连接，减少 TCP 握手和 TLS 握手开销

 【数据优化】
 5. 数据压缩：请求/响应体使用 gzip / Brotli 压缩，减少传输体积
 6. 图片格式优化：WebP 替代 JPEG/PNG（同质量下体积更小）；按需加载（缩略图 → 原图）
 7. 请求合并（Batching）：将多个小请求合并为一次网络请求，减少往返次数
 8. 协议缓冲（Protocol Buffers / FlatBuffers）：替代 JSON，编解码更快，体积更小

 【缓存策略】
 9. HTTP 缓存：合理设置 Cache-Control / ETag / Last-Modified，命中本地缓存时无需网络请求
 10. 本地磁盘缓存：对接口数据做本地持久化，首次展示本地数据，后台刷新（Stale-While-Revalidate 策略）

 【弱网优化】
 11. 超时与重试：合理设置 timeoutInterval，弱网下指数退避重试（Exponential Backoff）
 12. 请求优先级：NSURLSessionTask 设置 priority，关键请求优先完成
 13. 预加载（Prefetch）：根据用户行为预测下一步请求，提前发起

 【安全】
 14. HTTPS 强制：使用 ATS（App Transport Security），禁止明文 HTTP 传输
 15. SSL Pinning：防止中间人攻击，适合金融、支付类场景
 16. Token 刷新：统一处理 401 响应，自动刷新 Access Token 并重试原始请求


 ============================================================
 六、常见网络面试问题
 ============================================================

 Q：HTTP 和 HTTPS 的区别？
 A：HTTPS = HTTP + TLS。HTTPS 在 TCP 和 HTTP 之间加入 TLS 层，提供加密（防窃听）、
    身份验证（防冒充）、数据完整性（防篡改）。默认端口 HTTP 80，HTTPS 443。

 Q：HTTP/2 多路复用解决了什么问题？
 A：解决了 HTTP/1.1 的应用层队头阻塞（Head-of-Line Blocking）。HTTP/1.1 同一连接上请求
    必须按序响应，前面请求慢会阻塞后续请求；HTTP/2 通过流（Stream）机制让多个请求在
    同一 TCP 连接上独立并发传输，互不阻塞。

 Q：为什么 HTTP/3 选择 UDP 而不是 TCP？
 A：TCP 自身的队头阻塞无法在协议层面解决——一个 TCP 包丢失，后续所有数据必须等待重传。
    QUIC 基于 UDP，在应用层实现可靠传输，每个流独立处理重传，丢包只影响该流，
    不影响其他流；同时实现了 0-RTT 握手和连接迁移，更适合移动网络。

 Q：Charles 如何抓 HTTPS 包？
 A：Charles 充当中间人（MITM），将自签发的根证书安装到设备，使设备信任 Charles 证书。
    客户端与 Charles 建立 TLS 连接，Charles 再以真实身份与服务器建立 TLS 连接，
    中间对数据解密、记录、重新加密转发。SSL Pinning 可阻止此类抓包。

 Q：HTTPDNS 解决什么问题？
 A：传统 LocalDNS 存在缓存污染、DNS 劫持（运营商将域名解析到广告页）、解析慢（递归查询）等问题。
    HTTPDNS 绕过系统 DNS，直接通过 HTTP(S) 向自建 DNS 服务器查询 IP，
    返回精准调度的 IP（就近接入、负载均衡），提升解析速度和可靠性。

 Q：TCP 三次握手和四次挥手？
 A：三次握手（建立连接）：
    ① Client → Server：SYN（同步，seq=x）
    ② Server → Client：SYN-ACK（同步确认，seq=y，ack=x+1）
    ③ Client → Server：ACK（确认，ack=y+1）
    三次握手的原因：确保双方的发送和接收能力均正常，同步初始序列号。

    四次挥手（关闭连接）：
    ① Client → Server：FIN（主动关闭，进入 FIN_WAIT_1）
    ② Server → Client：ACK（确认，进入 CLOSE_WAIT；Client 进入 FIN_WAIT_2）
    ③ Server → Client：FIN（Server 数据发送完毕，进入 LAST_ACK）
    ④ Client → Server：ACK（Client 进入 TIME_WAIT，等待 2MSL 后关闭）
    四次挥手的原因：TCP 全双工，双方各自独立关闭发送方向，需要各发一个 FIN。

*/

@interface IBGroup2Controller28 ()

@end

@implementation IBGroup2Controller28

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

}

@end

