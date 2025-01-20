//
//  IBGroup3Controller4.m
//  MBCoder
//
//  Created by 叶修 on 2025/1/3.
//  Copyright © 2025 inke. All rights reserved.
//

#import "IBGroup3Controller4.h"

@interface IBGroup3Controller4 ()

@end

@implementation IBGroup3Controller4

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end

/**
 
 系统信息、CPU、Memory(OOM和泄漏)、FPS(卡顿)、温度，崩溃，线程，IO，网络、启动时间
 
 网速
 iperf3
 SimplePing
 GCDWebServer处理视频边下载边播放

 iOS 流量监控分析
 http://zhoulingyu.com/2018/05/30/ios-network-traffic/#more

 iOS 如何进行网络测速
 https://juejin.im/post/5a62c2416fb9a01ca713893d

 iOS 网速监控 学习篇
 http://chenqihui.github.io/2018/09/05/iOS-%E7%BD%91%E9%80%9F%E7%9B%91%E6%8E%A7-%E5%AD%A6%E4%B9%A0%E7%AF%87/#jump

 iOS APM (性能监控) - 数据采集实现调研
 https://fengs.online/2019/02/ios-apm-monitor-research/#111-httpdns
 
 性能优化
 http://www.cocoachina.com/articles/896783?filter=rec

 iOS - 性能优化
 https://www.jianshu.com/p/fe566ec32d28

 性能调优和监控体系
 https://github.com/ShannonChenCHN/iOSDevLevelingUp/issues/26

 微信读书 iOS 性能优化总结
 https://wereadteam.github.io/2016/05/03/WeRead-Performance/

 iOS性能检测指标
 https://www.jianshu.com/p/0b454b3ed37f

 iOS网络性能监控
 https://www.jianshu.com/p/1c34147030d1

 iOS 覆盖率检测原理与增量代码测试覆盖率工具实现
 https://tech.meituan.com/2018/12/27/ios-increment-coverage.html

 美团外卖iOS App冷启动治理
 https://tech.meituan.com/2018/12/06/waimai-ios-optimizing-startup.html

 大众点评千人移动研发团队怎样做持续集成？
 https://mp.weixin.qq.com/s/XY3u-bMgsg3rKI_DHZmSTg

 客户端自动化测试研究
 https://tech.meituan.com/2017/06/23/mobile-app-automation.html

 基于 KIF 的 iOS UI 自动化测试和持续集成
 https://tech.meituan.com/2016/09/02/ios-uitest-kif.html

 美团点评移动网络优化实践
 https://tech.meituan.com/2017/03/17/shark-sdk.html

 美团点评前端无痕埋点实践
 https://tech.meituan.com/2017/03/02/mt-mobile-analytics-practice.html

 日活超过 3 亿的快手是怎么进行性能优化的？
 https://www.infoq.cn/article/MXZMatJX6RMompVIgRo5


 后台下载趟坑
 https://juejin.im/post/5cf7eb0351882576710e5c15

 卡顿
 https://www.kancloud.cn/digest/smooth_user_interfaces_for_ios/82287
 https://juejin.im/post/5c0931d451882531b81b20fa
 https://blog.csdn.net/u013602835/article/details/79414403
 https://wjerry.com/2019/02/02/iOS%E9%A1%B5%E9%9D%A2%E5%8D%A1%E9%A1%BF%E5%8F%8A%E6%80%A7%E8%83%BD%E4%BC%98%E5%8C%96/

 iOS下音视频通信的实现-基于WebRTC
 http://www.cocoachina.com/articles/18837
 http://www.enkichen.com/2017/05/12/webrtc-ios-build/
 https://depthlove.github.io/2019/05/02/webrtc-development-2-source-code-download-and-build/
 https://skylerlee.github.io/codelet/2017/03/08/build-v8/

 直播疑难杂症排查
 https://blog.csdn.net/u010646653/category_6875831.htm

 iOS 性能监控方案
 https://github.com/aozhimin/iOS-Monitor-Platform

 反调试及绕过
 https://jmpews.github.io/2017/08/09/darwin/%E5%8F%8D%E8%B0%83%E8%AF%95%E5%8F%8A%E7%BB%95%E8%BF%87/

 SQLite线程模式探讨
 https://wereadteam.github.io/2016/08/19/SQLite/

 https://github.com/WeMobileDev/article/blob/master/%E5%BE%AE%E4%BF%A1iOS%20SQLite%E6%BA%90%E7%A0%81%E4%BC%98%E5%8C%96%E5%AE%9E%E8%B7%B5.md


 质量监控-卡顿检测
 https://www.jianshu.com/p/ea36e0f2e7ae


 内存优化
 iOS内存泄漏静态分析：Analyze的使用
 https://gorpeln.com/article/4
 iOS 内存调试篇 —— memgraph | 七日打卡
 https://juejin.cn/post/6917439747489005576
 你真的了解OOM吗？——京东iOS APP内存优化实录
 http://www.cocoachina.com/articles/485753
 深入探索 iOS 内存优化
 https://juejin.cn/post/6864492188404088846
 iOS性能优化实践：头条抖音如何实现OOM崩溃率下降50%+
 https://mp.weixin.qq.com/s/4-4M9E8NziAgshlwB7Sc6g
 深入了解iOS中的OOM(低内存崩溃)
 https://blog.csdn.net/TuGeLe/article/details/104004692
 - 深入解析iOS内存 iOS Memory Deep Dive
 http://blog.culeo.cn/archives/2019062811225186969
 OOM探究：XNU 内存状态管理
 https://www.jianshu.com/p/4458700a8ba8
 iOS内存abort(Jetsam) 原理探究
 https://satanwoo.github.io/2017/10/18/abort/
 从 OOM 到 iOS 内存管理 | 创作者训练营
 https://www.mdeditor.tw/pl/glr6
 iOS Memory 内存详解 (长文)
 https://juejin.cn/post/6844903902169710600
 iOS微信内存监控
 https://wetest.qq.com/lab/view/367.html
 iOS Out-Of-Memory 原理阐述及方案调研
 https://www.jianshu.com/p/2a283df2e839
 带你打造一套 APM 监控系统 之 OOM 问题
 https://cloud.tencent.com/developer/article/1662232
 iOS Memory 内存详解
 https://mp.weixin.qq.com/s/YpJa3LeTFz9UFOUcs5Bitg
 IOS——Memory 温故而知新
 https://www.jianshu.com/p/be94426b2960
 正确地获取 iOS 应用占用的内存
 https://github.com/ifelseboyxx/xx_Notes/blob/master/contents/Memory_Get/memory_get.md
 iOS-Monitor-Platform
 https://aozhimin.github.io/iOS-Monitor-Platform/#app-%E4%BD%BF%E7%94%A8%E7%9A%84%E5%86%85%E5%AD%98
 iOS 内存管理研究
 https://zhuanlan.zhihu.com/p/49829766
 iOS内存深入探索之VM Tracker
 https://www.jianshu.com/p/f82e2b378455
 macOS 内核之内存占用信息
 https://justinyan.me/post/3982
 让人懵逼的 iOS 系统内存分配问题
 https://www.jianshu.com/p/fcbb9a472633
 一些内存相关的名词
 http://kmanong.top/kmn/qxw/form/article?id=76516&cate=63
 高德地图驾车导航内存优化原理与实战
 https://zhuanlan.zhihu.com/p/347388400
 先弄清楚这里的学问，再来谈 iOS 内存管理与优化（一）
 https://www.jianshu.com/p/deab6550553a
 正确地获取 iOS 应用占用的内存
 http://www.samirchen.com/ios-app-memory-usage/
 深入浅出iOS系统内核（3）— 内存管理
 https://www.jianshu.com/p/b25e33bf4ea2
 译文 Mach: the core of Apple’s OS X
 https://zhuanlan.zhihu.com/p/57656644
 iOS 内存相关梳理
 https://blog.jonyfang.com/2020/04/08/2020-04-08-about-ram/
 XNU之四：iOS虚拟内存限制（一）
 https://satanwoo.github.io/2018/01/14/iOS-virtual/
 OOM的原理和治理
 http://www.chenzhipeng.net/article/10/read
 冻结后的应用将暂停运行，以此来节省内存、网络的占用，并且起到省电的作用。
 iOS中的内存布局与管理
 https://hello-david.github.io/archives/e94ffa1c.html
 CSAPP虚拟内存
 https://jasonxqh.github.io/2020/11/24/CSAPP%E8%99%9A%E6%8B%9F%E5%86%85%E5%AD%98/
 iOS OOM处理
 https://www.jianshu.com/p/c2e2e53ffb16
 深入了解iOS中的OOM(低内存崩溃)
 https://blog.csdn.net/TuGeLe/article/details/104004692

 OOM设备
 https://stackoverflow.com/questions/5887248/ios-app-maximum-memory-budget/15200855#15200855

 
 https://github.com/didi/DoKit
 https://github.com/Tencent/OOMDetector
 Matrix
 GodEye
 Herz
 GT
 MTHawkeye
 火山引擎APMPlus
 
 */
