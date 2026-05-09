//
//  IBController12.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/8.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController12.h"

@interface IBController12 ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) dispatch_source_t gcdtimer;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

/*
 RunLoop 是线程相关的底层基础，本质是一个 do-while 事件处理循环。

 一、RunLoop 作用

 1. 保持程序持续运行（主线程 RunLoop 不退出 = App 不退出）
 2. 处理各类事件：触摸事件、NSTimer、performSelector、Source0/Source1
 3. 节省 CPU：无事件时线程自动休眠，有事件时及时唤醒
 4. 驱动 UI 渲染：CADisplayLink、Core Animation 事务提交均依赖主线程 RunLoop

 二、RunLoop 与线程的关系

 - 一一对应：每条线程有且仅有一个 RunLoop
 - 懒加载：不能手动 alloc/init，首次调用 currentRunLoop 时自动创建（以线程为 key 存入全局字典）
 - 主线程：系统在 UIApplicationMain 内自动创建并启动
 - 子线程：默认不启动，需手动获取并添加 Source/Timer 后调用 run 启动，否则立即退出
 - 销毁：随线程结束自动销毁，不能手动销毁

 三、核心类关系

 CFRunLoopRef          RunLoop 本身（__CFRunLoop 结构体，核心方法 __CFRunLoopRun）
 CFRunLoopModeRef      运行模式，一次只能在一种 Mode 下运行；Mode 为空则直接退出
 CFRunLoopSourceRef    事件源（Source0 / Source1）
 CFRunLoopTimerRef     定时器（NSTimer / CADisplayLink 底层即此，toll-free bridged）
 CFRunLoopObserverRef  状态观察者

 结构：一个 RunLoop 包含多个 Mode，每个 Mode 包含若干 Source / Timer / Observer。

 四、RunLoop Mode

 NSDefaultRunLoopMode       默认模式，主线程空闲时运行
 UITrackingRunLoopMode      ScrollView 滑动时自动切换到此模式，与其他事件隔离
 UIInitializationRunLoopMode App 启动时短暂使用，启动完即退出
 NSRunLoopCommonModes       伪模式（标记集合），加入此模式的 item 会同步到所有 Common Mode
                            默认包含 DefaultMode + UITrackingMode

 NSTimer 加入 DefaultMode 后，滑动时 RunLoop 切换到 UITrackingMode 导致 Timer 暂停。
 解决：将 Timer 加入 NSRunLoopCommonModes，在两种 Mode 下均可触发。

 五、Source 事件源

 Source0  非端口事件，不由内核驱动。如触摸事件分发、performSelector 系列。
          需手动调用 CFRunLoopSourceSignal + CFRunLoopWakeUp 才能触发。
 Source1  基于 Mach Port 的端口事件，由内核驱动。如系统硬件事件、线程间通信。
          Source1 处理时可将部分操作派发给 Source0 处理。

 六、Observer 状态回调

 kCFRunLoopEntry          即将进入 RunLoop
 kCFRunLoopBeforeTimers   即将处理 Timer
 kCFRunLoopBeforeSources  即将处理 Source
 kCFRunLoopBeforeWaiting  即将进入休眠
 kCFRunLoopAfterWaiting   从休眠中唤醒
 kCFRunLoopExit           即将退出 RunLoop

 七、RunLoop 运行逻辑（一次循环）

 [进入]  通知 Observer: Entry
 [准备]  通知 Observer: BeforeTimers -> BeforeSources
 [执行]  处理 Source0（触摸分发、performSelector 等非端口事件）
         执行待处理的 Block
 [判断]  有 Source1 就绪？
         是 -> 跳过休眠，直接跳到 [处理]
         否 -> 通知 Observer: BeforeWaiting -> 线程进入休眠
 [唤醒]  被以下事件唤醒：
         Timer 到期 / Source1（端口事件）到达 / 手动调用 CFRunLoopWakeUp
         通知 Observer: AfterWaiting
 [处理]  Timer     -> 触发 Timer 回调
         主队列    -> 执行 dispatch_async(main) 的 block
         Source1   -> 处理端口事件
         执行待处理的 Block
 [循环?] CFRunLoopStop 被调用 / 超时 / Mode 为空 -> 退出
         否则回到 [准备] 继续下一轮
 [退出]  通知 Observer: Exit
 
 要能用语言描述出“检查 → 处理 → 休眠 → 唤醒”的循环过程。

 八、RunLoop 与 Autorelease Pool

 主线程 RunLoop 注册了两个 Observer：
 Observer1  监听 Entry -> _objc_autoreleasePoolPush()，order 最高（-2147483647），最先执行
 Observer2  监听 BeforeWaiting -> Pop 旧池 + Push 新池
            监听 Exit -> Pop 最终池，order 最低（2147483647），最后执行
 效果：每个 RunLoop 循环对应一个自动释放池的生命周期。

 九、PerformSelector 与 RunLoop

 performSelector:afterDelay:    内部创建 Timer 加入当前线程 RunLoop，子线程无 RunLoop 则失效
 performSelector:onThread:      内部创建 Source1 加入目标线程，目标线程无 RunLoop 则失效

 十、定时器对比

 NSTimer / CADisplayLink  依赖 RunLoop，受 Mode 影响，存在误差（Tolerance 宽容度）
 GCD dispatch_source      不依赖 RunLoop，精度更高，适合对时间要求严格的场景
 CADisplayLink            与屏幕刷新率同步（60/120Hz），适合动画、视频渲染

 十一、常见应用场景

 1. 常驻子线程       添加 Port/Source 后调用 [runLoop run] 保活（见 -work 方法）
 2. 滑动暂停任务     ImageView 加入 DefaultMode，滑动时自动暂停，不干扰 UI
 3. 空闲加载         监听 BeforeWaiting，RunLoop 空闲时分批执行耗时任务
 4. AutoreleasePool  RunLoop 每次循环自动 push/pop，控制对象生命周期
 5. 卡顿检测         注册 Observer 监听 BeforeSources/AfterWaiting，统计两次回调间隔
*/


@implementation IBController12

- (NSThread *)thread {
    static NSThread *_thread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(work) object:nil];
        [_thread setName:@"bowen"];
        [_thread start];
    });
    return _thread;
}

// 常驻子线程：添加 Port 保持 RunLoop 有 Source，防止退出
- (void)work {
    NSLog(@"%s", __func__);
    @autoreleasepool {
        [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
//    [self registerObserver];
}

- (void)registerObserver
{
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopEntry:           NSLog(@"kCFRunLoopEntry");          break;
            case kCFRunLoopBeforeTimers:    NSLog(@"kCFRunLoopBeforeTimers");   break;
            case kCFRunLoopBeforeSources:   NSLog(@"kCFRunLoopBeforeSources");  break;
            case kCFRunLoopBeforeWaiting:   NSLog(@"kCFRunLoopBeforeWaiting");  break;
            case kCFRunLoopAfterWaiting:    NSLog(@"kCFRunLoopAfterWaiting");   break;
            case kCFRunLoopExit:            NSLog(@"kCFRunLoopExit");           break;
            default: break;
        }
    });
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    CFRelease(observer);
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self test1];
//    [self test2];
//    [self test3];
//    [self test4];
//    [self test5];
//    [self test6];
//    [self test7];
    [self test8];
}

// Source0 自定义事件源示例
- (void)test8 {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            NSPort *port = [NSPort port];
            [runLoop addPort:port forMode:NSDefaultRunLoopMode];
            
            CFRunLoopSourceContext context = {0};
            context.perform = customEventCallback;
            CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
            
            // 手动触发 Source0
            CFRunLoopSourceSignal(source);
            CFRunLoopWakeUp(CFRunLoopGetCurrent());

            [runLoop run];
            
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
            CFRelease(source);
            NSLog(@"source Runloop ended");
        }
    });
}

void customEventCallback(void *info) {
    NSLog(@"Custom event fired");
}

// 子线程开启 RunLoop 后使用 NSTimer（两种方式）
- (void)test7 {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
            [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
            [runLoop run];
            NSLog(@"timer Runloop ended");
        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            NSRunLoop *runloop = [NSRunLoop currentRunLoop];
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
            [runloop run];
            NSLog(@"scheduledTimer Runloop ended");
        }
    });
}

- (void)timerFired:(NSTimer *)stopTimer {
    NSLog(@"timerFired");
    [stopTimer invalidate];
}

- (void)test6 {
    [self performSelector:@selector(runTest) onThread:[self thread] withObject:nil waitUntilDone:NO];
}

- (void)runTest {
    NSLog(@"%s",__func__);
}

/*
 CADisplayLink：与屏幕刷新率同步的定时器（默认 60Hz），加入 RunLoop 后每帧回调一次。
 适合：自定义动画引擎、视频渲染等需要逐帧更新的场景。
 停止时调用 invalidate 并置 nil，否则 RunLoop 持有 displayLink 导致内存泄漏。
*/
- (void)test5 {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(run)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopDisplayLink{
    [self.displayLink invalidate];
    self.displayLink = nil;
}

/*
 GCD 定时器：不依赖 RunLoop，基于内核计时，精度更高，不受 Mode 切换影响。
 dispatch_suspend / dispatch_resume 暂停/恢复；不能在 handler block 内调用 suspend。
 停止：dispatch_source_cancel，cancel 后不能再 resume，否则崩溃。
*/
- (void)test4 {
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    self.gcdtimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, global);
    // 参数：起始时间、间隔（NSEC_PER_SEC=秒，NSEC_PER_MSEC=毫秒）、精度（0=最高）
    dispatch_source_set_timer(self.gcdtimer, DISPATCH_TIME_NOW, NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.gcdtimer, ^{
        NSLog(@"%@", [NSThread currentThread]);
    });
    dispatch_resume(self.gcdtimer);
}

- (void)test3 {
    // ScrollView 滑动时 RunLoop 切换到 UITrackingMode，DefaultMode 的 Timer 暂停。
    // 加入 CommonModes 可同时在 DefaultMode + UITrackingMode 下触发。
    self.timer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(run) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)test2 {
    // 子线程默认无 RunLoop，scheduledTimer 不生效；需手动调用 [currentRunLoop run] 启动。
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"%s",__func__);
        self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(run) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] run];
    });
}

/*
 NSTimer = CFRunLoopTimerRef（toll-free bridged）。
 精度：RunLoop 为节省资源不保证精确触发，可通过 timer.tolerance 设置最大容忍误差。
 延迟：RunLoop 正在执行耗时操作时 Timer 会被推迟，误差累积不补偿。
 循环引用：scheduledTimer target:self 会强引用 self，需在合适时机调用 invalidate。
*/
- (void)test1 {
    // scheduledTimer 自动加入当前 RunLoop 的 DefaultMode
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(run) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)run {
    NSLog(@"run");
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

@end


/**
 CFRunLoopRunSpecific 伪代码（源码参考，理解 RunLoop 内部实现）

 void CFRunLoopRun(void) {
     CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
 }

 int CFRunLoopRunSpecific(runloop, modeName, seconds, stopAfterHandle) {
     CFRunLoopModeRef currentMode = __CFRunLoopFindMode(runloop, modeName, false);
     if (__CFRunLoopModeIsEmpty(currentMode)) return; // Mode 为空直接退出

     __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopEntry);

     __CFRunLoopRun(runloop, currentMode, seconds, returnAfterSourceHandled) {
         int retVal = 0;
         do {
             __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeTimers);
             __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeSources);
             __CFRunLoopDoBlocks(runloop, currentMode);

             // 处理 Source0
             sourceHandledThisLoop = __CFRunLoopDoSources0(runloop, currentMode, stopAfterHandle);
             __CFRunLoopDoBlocks(runloop, currentMode);

             // Source1 ready 则跳过休眠直接处理
             if (__Source0DidDispatchPortLastTime) {
                 if (__CFRunLoopServiceMachPort(dispatchPort, &msg)) goto handle_msg;
             }

             // 进入休眠
             __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeWaiting);
             mach_msg(msg, MACH_RCV_MSG, port); // 阻塞等待唤醒
             __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopAfterWaiting);

             handle_msg:
             if (msg_is_timer)         __CFRunLoopDoTimers(runloop, currentMode, mach_absolute_time());
             else if (msg_is_dispatch) __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
             else                      __CFRunLoopDoSource1(runloop, currentMode, source1, msg);

             __CFRunLoopDoBlocks(runloop, currentMode);

             // 检查退出条件
             if      (stopAfterHandle)                     retVal = kCFRunLoopRunHandledSource;
             else if (timeout)                             retVal = kCFRunLoopRunTimedOut;
             else if (__CFRunLoopIsStopped(runloop))       retVal = kCFRunLoopRunStopped;
             else if (__CFRunLoopModeIsEmpty(currentMode)) retVal = kCFRunLoopRunFinished;

         } while (retVal == 0);
     }

     __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);
 }
*/
