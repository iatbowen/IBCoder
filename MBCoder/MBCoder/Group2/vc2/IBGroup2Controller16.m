//
//  IBGroup2Controller16.m
//  MBCoder
//
//  Created by Bowen on 2019/11/1.
//  Copyright © 2019 inke. All rights reserved.
//

#import "IBGroup2Controller16.h"
#import "SonicWebViewController.h"

@interface IBGroup2Controller16 ()

@property (nonatomic, strong) NSString *url;

@end

@implementation IBGroup2Controller16

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.url = @"http://mc.vip.qq.com/demo/indexv3";
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self sonicRequestAction];
}

- (void)normalRequestAction
{
    SonicWebViewController *webVC = [[SonicWebViewController alloc]initWithUrl:self.url useSonicMode:NO unStrictMode:NO];
    [self addChildViewController:webVC];
    [self.view addSubview:webVC.view];
}

- (void)sonicResourcePreloadAction
{
    SonicWebViewController *webVC = [[SonicWebViewController alloc]initWithUrl:@"http://www.kgc.cn/zhuanti/bigca.shtml?jump=1" useSonicMode:YES unStrictMode:YES];
    [self addChildViewController:webVC];
    [self.view addSubview:webVC.view];
}

- (void)sonicPreloadAction
{
    [[SonicEngine sharedEngine] createSessionWithUrl:self.url withWebDelegate:nil];
}

- (void)sonicRequestAction
{
    SonicWebViewController *webVC = [[SonicWebViewController alloc]initWithUrl:self.url useSonicMode:YES unStrictMode:NO];
    [self addChildViewController:webVC];
    [self.view addSubview:webVC.view];
}

- (void)unstrictModeSonicRequestAction
{
    SonicWebViewController *webVC = [[SonicWebViewController alloc]initWithUrl:@"http://www.kgc.cn/zhuanti/bigca.shtml?jump=1" useSonicMode:YES unStrictMode:YES];
    [self addChildViewController:webVC];
    [self.view addSubview:webVC.view];
}

- (void)loadWithOfflineFileAction
{
    SonicWebViewController *webVC = [[SonicWebViewController alloc]initWithUrl:@"http://mc.vip.qq.com/demo/indexv3?offline=1" useSonicMode:YES unStrictMode:NO];
    [self addChildViewController:webVC];
    [self.view addSubview:webVC.view];
}

- (void)clearAllCacheAction
{
    [[SonicEngine sharedEngine] clearAllCache];
}

@end

/**
 
 ============================================================
 浏览器页面渲染流程（Critical Rendering Path）
 ============================================================

 1）网络进程请求 HTML，渲染进程接收字节流
 2）解析 HTML → 构建 DOM 树（遇到 <script> 默认阻塞解析，除非 defer/async）
 3）解析 CSS（内联/外链）→ 构建 CSSOM；JS 可能修改 DOM/CSSOM，形成解析-执行循环
 4）DOM + CSSOM → 渲染树（Render Tree，不含 display:none 等不可见节点）
 5）布局（Layout/Reflow）：计算几何位置，生成布局树
 6）绘制（Paint）：生成绘制记录（颜色/边框/阴影等），非直接像素
 7）分层（Layer）→ 栅格化（Raster）→ 合成（Composite）→ GPU 上屏
 
 CSSOM（CSS Object Model，CSS 对象模型）是浏览器解析 CSS 后生成的一棵树，结构和 DOM 类似，但节点是样式规则而不是 HTML 标签。

 iOS WKWebView 多进程对应关系：
 Network Process（网络）/ WebContent Process（解析+渲染+JS）/ GPU Process（合成上屏）
 主 App 进程只持有 WKWebView 壳，通过 IPC 与 WebContent 通信 → 首屏比 UIWebView 慢，但更安全稳定

 性能关键点：
 - 阻塞渲染：head 内同步 JS/CSS、未设尺寸的 img 导致布局抖动
 - 重排重绘：改 width/top 触发 Layout；改 color 只触发 Paint；transform/opacity 通常只走 Composite
 - 首屏指标：FP（首像素）/ FCP（首内容）/ LCP（最大内容）/ TTI（可交互）

 参考：https://github.com/Tencent/VasSonic/wiki
      https://dequan1331.github.io/
      https://developer.yahoo.com/performance/rules.html


 ============================================================
 iOS 中 Web 相关优化策略（Web 维度 + Native 维度）
 ============================================================

 【Web 维度优化】
 网络层：DNS 预解析 / HTTP-DNS、CDN 就近、HTTP 缓存（Cache-Control/ETag）、资源压缩（gzip/br）、合并减少请求数
 渲染层：精简 JS/CSS、路由懒加载、非首屏资源 defer/async、图片懒加载/WebP、减少 DOM 层级与回流
 业务层（高侵入）：动静分离、模板+数据拆分、分段缓存（如 VasSonic 标签划分 data/template）

 【Native 维度优化】
 1）容器预热与复用
 - WKWebView 首次创建慢（进程启动+IPC），JIT 虽加速 JS 执行，但纯 HTML 首屏常慢于 UIWebView
 - 预热：App 启动时创建空 WKWebView，提前拉起 WebContent 进程
 - 复用：内存常驻空 WebView 或 WebView 池，页面关闭只 load about:blank 不销毁

 2）Native 并行资源请求 & 离线包
 - 痛点：WebView 初始化期间网络空闲，内核内请求链路不可控
 - 方案：Native 并行拉主文档/接口，通过 NSURLProtocol（UIWebView）/ LocalServer / WKURLSchemeHandler 桥接给内核
 - 离线包：HTML/JS/CSS/占位图预下载到本地，渲染时 Native 直接返回 → 弱网零依赖、成功率最高
 - 工程要点：下载时机、版本灰度、增量 diff、签名校验、回滚

 3）复杂 DOM 节点 Native 化（Hybrid）
 - WKWebView IPC + LocalServer 有编解码/建连开销，重资源模块改 Native 渲染更高效
 - 常见：图片/地图/音视频/评论区 → Web 占位 + JSBridge 调 Native View
 - 收益：减少 Web 进程压力、交互更顺滑、可与 Native 列表并行渲染

 【两种加载模式对比】
 页面直出（loadRequest）：运营活动/广告页，优化重点是并行请求+缓存+离线包
 模板渲染（loadHTMLString）：资讯详情等，优化重点是本地模板+接口数据注入，避免重复下载静态资源


 ============================================================
 一、Web 传统模式加载流程与痛点
 ============================================================

 流程：
 1、用户点击 → 终端初始化（进程启动、Runtime、创建 WebView）— 此阶段网络空闲
 2、WebView 就绪 → CDN 请求 HTML → 解析下载 CSS/JS
 3、页面 JS 发起 API 请求（传统称 CGI，现多为 REST/GraphQL）或读 localStorage → 回包后操作 DOM 更新

 痛点：
 1、初始化与网络串行，主资源发起时机晚
 2、资源/数据强依赖网络，弱网白屏长
 3、CSR 模式先渲染空壳再填数据，二次 DOM 更新开销大（重排+重绘）

 优化方向（引出 VasSonic）：并行加载、流式桥接、动静分离、本地缓存与增量更新


 ============================================================
 面试题：浏览器渲染 & iOS Web 优化
 ============================================================

 Q：浏览器从 URL 到页面显示的完整渲染流程？
 A：请求 HTML → 解析建 DOM → 解析 CSS 建 CSSOM → 合并 Render Tree → Layout → Paint → Layer/Raster/Composite → GPU 上屏。
    同步 JS 会阻塞 DOM 解析；CSS 不阻塞 DOM 解析但阻塞 Render Tree 构建。

 Q：Reflow 和 Repaint 区别？如何减少？
 A：Reflow 改几何（width/height/top）；Repaint 改外观（color/visibility）。减少：批量改样式、用 transform 代替 top/left、避免逐行读 offsetTop 触发强制同步布局。

 Q：WKWebView 和 UIWebView 核心区别？为何首屏更慢？
 A：WKWebView 多进程隔离（Network/WebContent/GPU），JS 在独立进程 JIT 执行更安全；UIWebView 单进程。
    WK 首屏慢因进程冷启动+IPC；但内存占用低、崩溃不拖垮 App。UIWebView 已废弃。

 Q：WKWebView 为什么不能直接用 NSURLProtocol 拦截 HTTP/HTTPS？
 A：请求在 Network Process，不走 App 进程 NSURLProtocol。iOS 11+ 的 WKURLSchemeHandler 只能拦自定义 scheme，http/https 默认不可拦。
    常见替代：GCDWebServer 本地代理、registerSchemeForCustomProtocol 私有 API（POST body 易丢失）、离线包+loadHTMLString。

 Q：WebView 预热和复用怎么做？注意什么？
 A：App 启动创建空 WKWebView 预热进程；页面间复用实例，跳转前 loadRequest:about:blank 清状态。
    注意：Cookie/LocalStorage 隔离、历史栈清理、内存常驻权衡、多 Tab 需独立配置。

 Q：Native 并行请求 Web 资源原理？
 A：Native 在 WebView 创建同时发起主文档/接口请求，通过 Protocol/LocalServer/SchemeHandler 把已下载数据流式喂给 WebKit，避免"等 WebView 好了才开始下"。

 Q：离线包方案核心设计与风险？
 A：静态资源打包下发，Native 拦截返回本地文件；配合版本号/MD5 增量更新。
    风险：包体积、更新不及时、缓存穿透、需灰度+回滚+签名校验。

 Q：DOM 节点 Native 化适用场景？
 A：图片墙、地图、播放器、复杂列表等重交互/重资源模块；Web 留占位+JSBridge，Native 渲染 UIView，减少 Web 进程压力。

 Q：传统 Web 加载三大痛点？VasSonic 怎么解决？
 A：痛点：初始化与网络串行、弱网白屏、CSR 二次 DOM 更新。
    VasSonic：并行加载+BridgeStream 流式桥接、模板/数据动静分离、本地缓存+etag/template-tag 增量更新。

 Q：CSR / SSR / SSG 区别？App 内 H5 怎么选？
 A：CSR 客户端渲染，首屏慢 SEO 差但交互灵活；SSR 服务端出完整 HTML，首屏快；SSG 构建时生成静态页。
    App 内嵌页优先 SSR/模板直出+Native 缓存；纯活动页可 CSR+离线包。

 Q：H5 白屏如何监控？Native 侧能做什么？
 A：H5：window.onerror、unhandledrejection、资源 onerror、框架 mount 标记。
    Native：decidePolicyForNavigation 拦主文档失败、evaluateJavaScript 探活、定时截图/DOM 采样、监听 WebContent 进程崩溃。

 Q：iOS 11 WKURLSchemeHandler 能做什么、不能做什么？
 A：能拦截自定义 scheme（如 myapp://）做本地资源映射；不能拦截 http/https 系统默认 scheme，这是与 UIWebView NSURLProtocol 的最大差异。
 
 ============================================================
 二、VasSonic 核心方案
 ============================================================

 【1. 并行加载 + BridgeStream 流式桥接】
 串行模式：WebView 初始化完成 → 才发起主资源请求（初始化期间网络空闲）
 并行模式：WebView 初始化同时，子线程已发起主资源请求
 新问题：初始化快于网络返回 → WebKit 就绪后仍要等待数据
 解决：WebKit 支持边下边渲染 → 用 BridgeStream 中间层桥接

 流程：
 1）子线程请求主资源，网络流持续写入内存缓冲
 2）WebView 初始化完成，BridgeStream 连接 WebKit 与数据流
 3）WebKit 读数据时，先返回内存已缓冲部分，再继续读网络流

 【2. 动态缓存 + 动静分离】
 BridgeStream 边读边缓存完整响应
 页面拆分为：模板（静态 HTML/JS/CSS 骨架）+ 数据块（频繁变化的内容）
 HTML 用注释标记数据块边界：<!-- sonicdiff-xxx --> ... <!-- endsonicdiff-xxx -->
 模板 = 抠掉数据块后的 HTML

 【3. 协议头增量更新】
 etag：整页内容哈希，判断页面是否有变化
 template-tag：模板哈希，判断模板是否有变化
 客户端本地校验 or 服务端比对，决定更新粒度

 【4. 四种加载模式】
 首次加载：无本地缓存，etag/template-tag 为空 → 全量下载
 完全缓存：etag 一致 → 直接用本地缓存，零网络
 数据更新：etag 不一致 + template-tag 一致 → 只更新数据块，模板复用
 模板更新：etag 不一致 + template-tag 不一致 → 模板+数据全量更新


 ============================================================
 三、VasSonic 实现原理与模块
 ============================================================

 核心思路：Native 传输通道取代 WebKit 自身网络通道，初始化与主资源请求并行 + 流式拦截
 页面模型：模板 + 数据 = 完整网页，按场景分别更新

 模块职责：
 SonicSession      单次页面加载会话，sonic 线程完成网络加载与状态流转
 SonicClient       管理所有 Session，按 URL 创建/复用
 SonicURLProtocol  拦截 WebView 主资源请求，将 Session 网络流桥接给 WebKit
 SonicCache        缓存读写、模板拆分与更新、内存缓存管理
 SonicConnection   可继承基类，支持离线资源等自定义加载源

 数据流：
 Native 子线程拉主资源 → BridgeStream 缓冲 → SonicURLProtocol 拦截 → WebKit 流式消费
                                                              ↓
                                                         SonicCache 落盘/读缓存


 ============================================================
 四、Sonic 与 WKWebView 适配问题
 ============================================================

 【为何 Sonic 原生基于 UIWebView】
 - UIWebView 支持 NSURLProtocol 拦截 http/https 主资源请求
 - WKWebView 网络在 Network Process，App 进程 NSURLProtocol 不生效
 - WK 回调均 IPC 跨进程，首屏渲染通常慢于 UIWebView

 【WKWebView 替代方案】
 1）GCDWebServer 本地代理：WebView 请求 localhost，Native 拦截后返回缓存/网络数据
 2）loadHTMLString 加载本地模板：首次仍会浪费一次全量网络请求
 3）私有 API registerSchemeForCustomProtocol：可拦 http/https，但 POST body 易丢失，审核风险
 4）iOS 11+ WKURLSchemeHandler：仅支持自定义 scheme，http/https 仍不可拦

 【WKWebView 其他系统级问题】
 Cookie 同步（WK 与 NSHTTPCookieStorage 隔离，iOS 11+ 有 API 改善）
 POST 参数在拦截方案中易丢失
 JS 异步执行时序与 Native 回调竞态
 可通过业务层适配：Cookie 手动同步、GET 化、JSBridge 约定时序


 ============================================================
 五、WKWebView 白屏问题与监控
 ============================================================

 【常见白屏原因（技术层）】
 JS 语法不兼容（可选链/空值合并在低版本 WebKit 报错）
 核心 JS/CSS 加载失败（CDN/弱网/缓存穿透）
 WebView 进程 OOM 崩溃（大图/Canvas/DOM 过多）
 WKWebView 缓存异常（App 内嵌 H5 高频场景）
 Promise 未捕获导致渲染中断
 SPA 路由 chunk 懒加载失败（发版后 hash 变更旧缓存命中）

 【常见白屏原因（业务层）】
 登录态失效：Token/Cookie 未注入或过期，接口 401 后页面无兜底直接白屏
 JSBridge 未就绪：H5 在 bridge 注入完成前调用 Native 能力，初始化逻辑中断
 入参缺失：userId/roomId/activityId 等 Native 未拼进 URL，H5 校验失败不渲染
 接口空数据无占位：列表/详情接口返回空，前端未做 empty 态，页面看起来是白的
 活动下线/权限不足：页面已过期或用户无资格，服务端返回空 HTML 或跳转失败
 混合内容拦截：HTTPS 页面加载 HTTP 资源，iOS ATS 静默拦截
 App 与 H5 版本不匹配：新 H5 依赖新 JSBridge 方法，旧 App 未实现导致调用崩溃

 【监控策略（H5 + Native 双通道）】
 H5 侧：window.onerror / unhandledrejection / 资源 onerror / 框架 mount 成功标记
 Native 侧：navigation 失败回调 / evaluateJavaScript 探活 / 定时截图 / WebContent 进程终止通知

 【检测能力互补】
 Native 强于：主文档失败、DNS/SSL/网络错误、HTTP 状态码、进程崩溃、内存杀、切后台恢复
 H5 强于：JS 运行时错误、Promise 异常、框架渲染失败、路由 chunk 失败、用户行为路径
 最佳实践：H5 埋点通过 JSBridge 上报 Native，Native 兜底网络层与进程层监控


 ============================================================
 面试题：VasSonic & WKWebView 进阶
 ============================================================

 Q：VasSonic BridgeStream 解决了什么问题？
 A：解决并行加载时 WebKit 就绪但数据未返回的空等问题。子线程预拉数据写入内存，WebKit 通过 BridgeStream 先读缓冲再读网络，实现边下边渲染。

 Q：VasSonic 四种缓存模式如何判断？分别怎么更新？
 A：看 etag 和 template-tag：etag 一致→完全缓存；etag 不同+template-tag 相同→只更数据块；两者都不同→模板+数据全更；无缓存→首次全量。

 Q：sonicdiff 注释标记的作用？
 A：在 HTML 中标注数据块边界，服务端/客户端据此拆分模板与数据，实现动静分离和增量更新，避免每次全量下载 HTML。

 Q：Sonic 五大模块各自职责？数据怎么流转？
 A：SonicClient 管 Session；Session 在子线程拉资源；URLProtocol 拦截 WebKit 请求桥接数据流；Cache 负责缓存/模板拆分；Connection 支持离线等自定义源。

 Q：为什么 VasSonic 难以直接用于 WKWebView？
 A：WK 网络请求在独立 Network Process，NSURLProtocol 无法拦截 http/https；并行桥接和流式拦截的核心能力依赖 Protocol 拦截。

 Q：WKWebView 下如何实现类似 Sonic 的离线/缓存能力？
 A：GCDWebServer 本地代理（WebView 请求 localhost）、WKURLSchemeHandler 拦自定义 scheme、loadHTMLString 注入本地模板+JSBridge 填数据、离线包+版本管理。

 Q：registerSchemeForCustomProtocol 私有 API 的风险？
 A：可拦 http/https 但 POST body 丢失；依赖私有 API 有审核风险；系统升级可能失效。

 Q：WKWebView Cookie 问题和解决方案？
 A：WK 与 NSHTTPCookieStorage 默认隔离，登录态不同步。iOS 11+ 用 WKHTTPCookieStore 读写；或请求前手动注入 Cookie header。

 Q：SPA 页面在 WebView 白屏的常见原因？
 A：路由懒加载 chunk hash 变更后旧缓存 404；核心 JS 加载失败；Vue/React mount 前 JS 报错；WebContent 进程 OOM 被杀。

 Q：H5 和 Native 白屏监控如何配合？
 A：H5 负责 JS 层（onerror/unhandledrejection/chunk 失败/mount 标记），通过 JSBridge 上报；Native 负责网络层（navigation 失败/HTTP 状态）和进程层（崩溃/内存杀/后台恢复），双向互补。

 Q：WKWebView 进程崩溃如何感知？App 会崩吗？
 A：监听 webViewWebContentProcessDidTerminate:；WebContent 进程崩溃不会拖垮 App（多进程隔离），但页面白屏，需 reload 或重建 WebView。

 Q：VasSonic vs 纯离线包方案区别？
 A：VasSonic 侧重主文档并行+模板数据增量更新（适合 SSR 直出页）；离线包侧重静态资源全量本地化（适合活动页）。可组合：离线包管 JS/CSS，Sonic 管 HTML 模板增量。
 
 ============================================================
 App 中 WKWebView 应用场景
 ============================================================

 WKWebView 四种加载 API，按数据源分两类：

 加载 URL（远程/在线）：
 loadRequest:          请求远程 URL，最常用
 loadFileURL:allowingReadAccessToURL:  加载沙盒/Bundle 本地 HTML

 加载数据（内存注入）：
 loadHTMLString:baseURL:  注入 HTML 字符串，baseURL 决定相对路径解析
 loadData:MIMEType:...     加载 NSData（PDF/图片等）

 【两种业务场景与优化重点】
 页面直出（loadRequest）：
 - 场景：运营活动、广告落地页、外链 H5
 - 优化：并行预拉、离线包、DNS 预解析、Sonic 模板缓存

 模板渲染（loadHTMLString）：
 - 场景：资讯详情、协议页、本地模板+接口数据
 - 优化：模板本地化、接口数据 JS 注入、避免重复下载静态资源

 选型原则：内容频繁变更走直出+缓存；结构固定内容动态走模板渲染+数据注入


 ============================================================
 前端渲染模式（CSR / SSR / SSG）
 ============================================================

 模式      渲染时机          HTML 内容        首屏速度    交互性    App 内适用
 CSR      客户端（浏览器）    空壳+JS 渲染      慢         强       活动页/复杂交互
 SSR      服务端（请求时）    完整 HTML         快         中       资讯/详情（推荐）
 SSG      构建时（部署前）    预生成静态 HTML    最快       弱       协议/帮助/固定页

 CSR：服务端返回空 HTML → 下载执行 JS/CSS → 动态构建 DOM（Vue/React SPA）
 SSR：服务端按请求数据拼好完整 HTML → 客户端直接展示 → JS  hydration 接管交互
 SSG：构建工具（Hugo/Gatsby）预生成静态页 → CDN 直出，无需实时渲染

 App 内 H5 选型建议：
 - 首屏敏感（详情/列表）→ SSR 或模板直出 + Native 缓存（VasSonic/离线包）
 - 强交互（抽奖/游戏）→ CSR + 离线包兜底 JS/CSS
 - 固定内容（用户协议）→ SSG 打包进离线包，零网络依赖

 参考：https://github.com/yacan8/blog/issues/30


 ============================================================
 面试题：加载方式 & 渲染模式选型
 ============================================================

 Q：WKWebView 四种加载 API 区别？怎么选？
 A：loadRequest 加载远程 URL（活动页）；loadFileURL 加载本地文件；loadHTMLString 注入 HTML 字符串（模板渲染）；loadData 加载二进制。
    在线页用 loadRequest；模板+数据注入用 loadHTMLString+baseURL。

 Q：页面直出和模板渲染分别适合什么场景？
 A：直出适合运营活动/外链 H5，优化重点是并行请求和缓存；模板渲染适合资讯详情等结构固定、内容动态的页面，模板本地化+接口注入。

 Q：CSR/SSR/SSG 核心区别？App 内 H5 怎么选？
 A：CSR 客户端渲染首屏慢交互强；SSR 服务端出完整 HTML 首屏快；SSG 构建时生成静态页最快但内容固定。
    App 内：详情页 SSR+缓存；活动页 CSR+离线包；协议页 SSG+离线包。
 
 */
