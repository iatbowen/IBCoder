//
//  IBGroup2Controller25.m
//  MBCoder
//
//  Created by BowenCoder on 2020/3/9.
//  Copyright © 2020 inke. All rights reserved.
//

#import "IBGroup2Controller25.h"

@interface G2Person25 : NSObject

@property (nonatomic, strong) id delegate;

@end

@implementation G2Person25

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

@end

@interface IBGroup2Controller25 ()

@property (nonatomic, strong) NSTimer *weakTimer;

@end

@implementation IBGroup2Controller25

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    G2Person25 *p = [G2Person25 new];
    p.delegate = p;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self case1];
}

/**
 检测结果：
 FBRetainCycleDetector 没有检测出结果（Timer → VC 的强引用不经过属性遍历路径）
 pop 时 ViewController 没有 dealloc，MLeaksFinder 报 leak
 原因：NSTimer 强引用 self（target），RunLoop 强引用 Timer，VC 强引用 Timer，形成环。
 解法：① 使用 block-based timer（iOS 10+）并在 block 内用 weakSelf；② 使用 NSProxy 弱代理。
 */
- (void)case1 {
    self.weakTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"case8 timer block%@", self);
    }];
}

/*

 ============================================================
 内存泄漏与循环引用 面试题总结
 ============================================================

 一、内存泄漏（Memory Leak）
 ──────────────────────────────────────────

 【概念】
 已分配的堆内存因失去所有引用而无法被释放，导致内存持续增长，最终触发系统 OOM Kill。

 【ARC 下常见内存泄漏原因】
 1. 循环引用（Retain Cycle）：最常见，双方互相持有强引用，引用计数永远不归零
 2. 单向强引用不释放：如注册了通知/KVO 后未移除，Observer 持有被观察对象
 3. Core Foundation 对象未调用 CFRelease：CF 对象不受 ARC 管理，需手动释放
 4. C/C++ malloc 内存未 free：混编场景中手动分配的内存
 5. 全局容器无限增长：将对象加入全局 NSMutableArray/NSMutableDictionary 却从不移除
 6. NSTimer 未 invalidate：Timer 被 RunLoop 持有，若不调用 invalidate 永远不释放


 ============================================================
 二、循环引用（Retain Cycle）
 ============================================================

 【本质】
 两个或多个对象互相持有对方的强引用，引用计数均不为 0，
 任何一方都无法在另一方释放前先释放，形成"死锁"式的内存泄漏。

 【判断方法】
 引用图中存在环（Cycle）：A → B → C → A，所有节点均无法被外部直接访问时发生泄漏。

 【解决通用原则】
 打断环中的某条强引用，改为 weak（或 unsafe_unretained）引用，使环中至少一个节点
 引用计数可以降为 0，触发 dealloc 链式释放。


 ============================================================
 三、常见循环引用场景与解决方案
 ============================================================

 【1. Block 循环引用】
 场景：VC 强引用 Block（self.block = ^{ [self doSomething]; }），
      Block 捕获了 self（强引用），形成 VC → Block → VC 的环。

 解法：__weak + __strong dance
   __weak typeof(self) weakSelf = self;
   self.block = ^{
       __strong typeof(weakSelf) strongSelf = weakSelf;
       if (!strongSelf) return;
       [strongSelf doSomething];
   };

 ⚠️ 注意：
 - 不是所有 Block 都有循环引用，只有 Block 被 self（或 self 持有的对象）强引用时才成环
 - Block 作为局部变量或方法参数传递，不会形成循环引用
 - __strong 的目的：防止 Block 执行期间 weakSelf 被释放（多线程场景）

 【2. Delegate 循环引用】
 场景：VC 强引用 View（self.view = view），View 的 delegate 若为 strong 则反向强引用 VC，成环。
 解法：delegate 属性声明为 weak（@property (nonatomic, weak) id<Protocol> delegate）
 原则：delegate 永远使用 weak，这是 iOS 开发的基本规范。

 【3. NSTimer 循环引用】
 场景：
   RunLoop → Timer（强引用）
   Timer → target/self（强引用，scheduledTimerWithTimeInterval:target:selector:）
   self → Timer（self.timer = timer，强引用）
   形成 self ↔ Timer 的环，且 RunLoop 也持有 Timer，导致 VC pop 后仍不释放。

 解法一：使用 iOS 10+ block-based API + weakSelf
   __weak typeof(self) weakSelf = self;
   self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
       [weakSelf doSomething];
   }];

 解法二：NSProxy 弱代理（兼容 iOS 10 以下）
   创建一个 NSProxy 子类，持有 weak 引用指向真实 target，Timer 的 target 设为 Proxy。
   Proxy 通过消息转发将方法调用转给真实 target，真实 target 释放后 Proxy 的 weak 为 nil，安全无崩溃。

 ⚠️ 无论哪种方案，都必须在适当时机调用 [self.timer invalidate]; self.timer = nil;
    否则 Timer 依然被 RunLoop 持有，仅仅打破 self-Timer 环还不够。

 【4. NSNotificationCenter 循环引用 / 泄漏】
 iOS 9 之前：NotificationCenter 对 Observer 持有强引用，必须手动调用 removeObserver:，
            否则 Observer 释放后调用其方法导致野指针崩溃。
 iOS 9+：NotificationCenter 改为弱引用 Observer，Observer 释放后自动移除，不再需要手动移除。
 ⚠️ 但使用 addObserverForName:object:queue:usingBlock: 的 block-based API 时，
    返回的 Observer 对象仍需手动 removeObserver:，否则泄漏。

 【5. KVO 未移除】
 KVO 注册后若不调用 removeObserver:，在被观察对象发送通知时访问已释放的 Observer 导致崩溃。
 解法：在 dealloc 中移除，或使用 KVOController（Facebook）自动管理生命周期。

 【6. 关联对象（Associated Object）循环引用】
 对象 A 通过 objc_setAssociatedObject 将对象 B 以 RETAIN 策略关联，
 若 B 同时持有 A 的强引用，则成环。
 解法：关联时使用 ASSIGN 策略（弱引用语义），或将 B 持有 A 的引用改为 weak。


 ============================================================
 四、内存泄漏检测工具
 ============================================================

 【1. MLeaksFinder（微信团队）】
 原理：
   通过 Method Swizzle 拦截 UIViewController 的 viewDidDisappear: 和 UIView 的 removeFromSuperview，
   延迟 2~3 秒后检查对象是否已释放（通过 weak 引用判断是否为 nil），
   若未释放则弹窗报告泄漏对象及其引用链。

 优点：
 - 轻量级，不侵入业务代码
 - 跑正常业务流程即可自动检测，无需额外操作
 - 可精确定位未释放的对象类型

 缺点：
 - 默认只检测 UIViewController 和 UIView（可扩展）
 - 无法检测非 UI 对象（如 ViewModel、Service 层）的泄漏
 - 延迟检测机制可能有误报（动画期间对象正常延迟释放）

 【2. FBRetainCycleDetector（Facebook）】
 原理：
   从候选对象出发，通过 ObjC Runtime 遍历其所有属性（包括 strong 属性、关联对象），
   递归构建引用图，若遍历过程中发现重复节点（已访问过的对象），则报告循环引用路径。
   对 Block 的检测：解析 Block 的内部结构，提取其捕获的变量列表并加入遍历。

 优点：
 - 能检测 NSObject 属性循环引用、关联对象循环引用、Block 循环引用
 - 可同时发现多条循环引用路径

 缺点：
 - 需要提供候选检测对象（入口），无法主动发现所有泄漏
 - 遍历引用图耗时，不适合大规模频繁检测
 - 某些循环引用路径（如 NSTimer target）无法通过属性遍历找到

 【两者配合使用】
 MLeaksFinder 发现"有对象未释放" → FBRetainCycleDetector 定位"是哪条引用链成环"

 【3. Instruments — Leaks】
 Xcode 内置工具，运行时扫描堆内存，找到无任何引用指向的孤立内存块（泄漏对象）。
 使用步骤：Xcode → Product → Profile → Leaks
 适合：检测 C/CF 层内存泄漏、偶发性泄漏场景

 【4. Instruments — Allocations】
 追踪所有对象的分配与释放，通过 Generation 快照对比，找到执行某操作后增量未释放的对象。
 使用步骤：Mark Generation → 执行操作 → 再 Mark → 查看 Generation 增量

 【5. Xcode Memory Graph Debugger】
 Xcode 运行时工具（Debug → Memory Graph），可视化展示当前堆中所有对象的引用关系图，
 支持导出 .memgraph 文件分析，能直观看到循环引用环。


 ============================================================
 五、常见内存问题对比
 ============================================================

 内存泄漏（Memory Leak）
   已分配内存失去引用而无法释放，进程内存持续增长，最终被系统 Kill（OOM）。

 野指针（Dangling Pointer）
   指针指向的对象已被释放（dealloc），但指针未置 nil，继续访问导致 EXC_BAD_ACCESS 崩溃。
   ARC 下 weak 引用在对象释放后自动置 nil，避免野指针；__unsafe_unretained 不会置 nil，有风险。

 内存溢出（Out of Memory, OOM）
   进程占用内存超出系统限制，被系统强制终止（不同于 Stack Overflow 栈溢出）。
   iOS 系统没有虚拟内存交换，物理内存不足时优先 Kill 内存占用大的进程。

 栈溢出（Stack Overflow）
   函数调用层级过深（无限递归），耗尽线程栈空间（默认主线程 8MB，子线程 512KB），
   导致 EXC_BAD_ACCESS 崩溃。

 内存抖动（Memory Thrashing）
   在短时间内大量创建和销毁临时对象，导致频繁内存分配/回收和 AutoreleasePool 排水，
   引起 CPU 和内存使用峰值，造成卡顿。解法：对象复用（复用池）、减少临时对象创建。

*/

@end
