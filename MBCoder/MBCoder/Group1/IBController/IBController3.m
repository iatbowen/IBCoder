//
//  IBController3.m
//  IBCoder1
//
//  Created by Bowen on 2018/4/25.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController3.h"
#import "IBProducerConsumer.h"
#import "IBReadersWriters.h"
#import "IBDiningPhilosophers.h"
#import "IBSleepingBarber.h"
#import "IBSleepingBarberCV.h"

@interface IBController3 ()

@property(nonatomic,assign) int filmTickets;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSThread *thread;

@end

/*

 ============================================================
 iOS 多线程 / GCD / NSOperation 面试题总结
 ============================================================


 ============================================================
 一、进程 vs 线程
 ============================================================

 进程：程序在操作系统中的一次执行实例，是系统资源分配的基本单位（独立内存空间）
 线程：进程内的执行单元，是 CPU 调度的基本单位，同进程内线程共享内存

 区别：
 地址空间   进程独立，互不影响；线程共享进程内存，需要同步机制
 通信方式   进程间：管道/信号/套接字/共享内存/消息队列（复杂）
            线程间：直接读写共享数据（简单但需加锁）
 切换开销   进程：需保存/加载完整上下文，开销大
            线程：共享大部分上下文，切换开销小


 ============================================================
 二、iOS 多线程方案概览
 ============================================================

 pthread          C 语言 POSIX 标准，跨平台，需手动管理生命周期，极少直接使用
 NSThread         OC 封装，面向对象，需手动管理生命周期
 GCD              苹果 C 语言 API，系统自动管理线程池，推荐首选
 NSOperation      GCD 的 OC 封装，支持依赖关系、状态监听、取消/暂停


 ============================================================
 三、GCD 核心概念
 ============================================================

 【概念】
 Grand Central Dispatch：苹果开发的底层 C API，自动利用多核并管理线程池。
 核心：任务（做什么）+ 队列（任务存放的地方）

 【同步 vs 异步】
 dispatch_sync  ：同步，等待 block 执行完毕才返回，不具备开启新线程的能力
 dispatch_async ：异步，提交 block 后立即返回，具备开启新线程的能力

 【串行 vs 并发】
 串行队列（Serial）  ：任务按 FIFO 顺序逐一执行，同一时刻只有一个任务在运行
 并发队列（Concurrent）：允许多个任务同时执行（并发功能仅在 async 下有效）

 【四种组合执行效果】
 async + 并发队列  → 开多线程，任务并发执行（最常用）
 async + 串行队列  → 开一条线程，任务顺序执行
 async + 主队列   → 不开新线程，等主线程空闲后在主线程串行执行
 sync  + 并发队列  → 不开新线程，在当前线程串行执行（并发失效）
 sync  + 串行队列  → 不开新线程，串行执行；若在当前串行队列中嵌套 sync → 死锁
 sync  + 主队列   → 在主线程调用时死锁（主线程等 block 完成，block 等主线程空闲）


 ============================================================
 四、队列类型
 ============================================================

 【全局并发队列（系统提供）】
 dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

 QoS 等级（iOS 8+ 推荐替代旧 PRIORITY 宏）：
 QOS_CLASS_USER_INTERACTIVE ：UI 交互，最高优先级
 QOS_CLASS_USER_INITIATED   ：用户发起，需立即结果
 QOS_CLASS_DEFAULT          ：默认
 QOS_CLASS_UTILITY          ：耗时操作，用户可感知进度（如下载）
 QOS_CLASS_BACKGROUND       ：后台，用户不感知（如同步/索引）

 【自定义队列】
 dispatch_queue_t serial = dispatch_queue_create("com.xxx", DISPATCH_QUEUE_SERIAL);
 dispatch_queue_t conc   = dispatch_queue_create("com.xxx", DISPATCH_QUEUE_CONCURRENT);

 【主队列】
 dispatch_queue_t main = dispatch_get_main_queue(); // 与主线程绑定的串行队列


 ============================================================
 五、GCD 常用 API
 ============================================================

 【dispatch_after — 延时执行】
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{ * 2秒后执行 * });
 注意：dispatch_after 只是延时提交 block，并非精准延时执行。

 【dispatch_once — 一次性代码（线程安全）】
 static dispatch_once_t onceToken;
 dispatch_once(&onceToken, ^{ * 整个进程生命周期只执行一次 * });

 底层原理：
 onceToken 本质是 long 型标志位，初始为 0。
 dispatch_once 用原子操作（atomic compare-and-swap）判断是否已执行，
 第一次执行时将 token 置为 ~0（全 1），后续调用直接跳过。
 线程安全：若多个线程同时首次调用，只有一个线程执行 block，其余自旋等待。
 常见用途：单例、全局资源初始化。

 【dispatch_group — 队列组，等待多个任务完成】

 方式一：dispatch_group_async + dispatch_group_notify（推荐，不阻塞线程）
 dispatch_group_t group = dispatch_group_create();
 dispatch_group_async(group, queue, ^{ * 耗时任务1 * });
 dispatch_group_async(group, queue, ^{ * 耗时任务2 * });
 dispatch_group_notify(group, dispatch_get_main_queue(), ^{ * 全部完成后回主线程 * });

 方式二：dispatch_group_enter / dispatch_group_leave（适合异步回调，如网络请求）
 enter 与 leave 必须严格配对，每次 enter 计数+1，leave 计数-1，归零时触发 notify。
 dispatch_group_enter(group);
 [self fetchDataWithCompletion:^{
     dispatch_group_leave(group); // 必须在异步回调中调用
 }];

 方式三：dispatch_group_wait（阻塞当前线程直到 group 完成，慎用）
 dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

 【dispatch_barrier_async — 读写隔离（多读单写）】
 barrier 之前的所有并发任务完成后，单独执行 barrier block，再继续后续并发任务。
 注意：只对【自定义并发队列】有效，对全局并发队列无效。
 dispatch_queue_t rwQueue = dispatch_queue_create("rw", DISPATCH_QUEUE_CONCURRENT);
 dispatch_async(rwQueue, ^{ * 读，并发 * });
 dispatch_barrier_async(rwQueue, ^{ * 写，排他 * });
 dispatch_async(rwQueue, ^{ * 读，并发 * });

 【dispatch_semaphore — 信号量】
 dispatch_semaphore_t sem = dispatch_semaphore_create(N); // 初始值 N
 dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);     // 值>0 则-1继续，否则阻塞
 dispatch_semaphore_signal(sem);                          // 值+1，唤醒等待线程

 三种用途：
 ① 控制最大并发数：初始值为 N，同时最多 N 个线程进入临界区
 ② 异步转同步  ：初始值为 0，回调中 signal，主线程 wait 等结果
 ③ 互斥锁     ：初始值为 1（等效于二值信号量）

 【dispatch_apply — 并行 for 循环】
 dispatch_apply(10, queue, ^(size_t i) { * 并行处理索引 i * });
 所有迭代完成后才返回，会阻塞当前线程；适合大数据并行处理（如图片批量处理）。


 ============================================================
 六、线程控制
 ============================================================

 【线程间通信（子线程回主线程）】
 dispatch_async(dispatch_get_main_queue(), ^{ * 更新 UI * });
 [[NSOperationQueue mainQueue] addOperationWithBlock:^{ }];
 [self performSelectorOnMainThread:@selector(xxx) withObject:nil waitUntilDone:NO];

 【终止线程】
 GCD：dispatch_block_cancel 只能取消尚未执行的 block，无法中止正在执行的。
      正在执行的 block 需通过 __block BOOL 标志位自行检查退出。
 NSThread：[thread cancel] 设置 isCancelled 标志，需在 work 方法中主动检测并调用 [NSThread exit]。

 【performSelector:withObject:afterDelay: 实现原理】
 内部创建一个 NSTimer 注册到当前线程的 RunLoop（NSDefaultRunLoopMode），
 延时到达后 Runtime 通过 SEL 查找方法列表并调用。
 注意：
 - 子线程默认无 RunLoop，Timer 不会触发（需手动开启 RunLoop）
 - performSelectorOnMainThread:waitUntilDone:YES 会阻塞当前线程

 【RunLoop 与线程的关系】
 主线程：系统自动创建并运行 RunLoop，App 的事件循环由此驱动
 子线程：默认没有 RunLoop，[NSRunLoop currentRunLoop] 调用时懒创建但不自动运行
 RunLoop 保活线程：[runloop run] 或 [runloop runUntilDate:] 让线程持续存活（常驻线程）
 没有 RunLoop 的子线程：任务执行完即销毁


 ============================================================
 七、线程安全
 ============================================================

 资源竞争（Race Condition）：多线程同时读写共享数据，导致结果不确定
 解决：加锁（NSLock/@synchronized/dispatch_semaphore）或放入串行队列

 死锁（Deadlock）：必须同时满足以下四个条件
 互斥条件  ：资源一次只能被一个线程占用
 请求与保持 ：线程已占有资源，又请求其他资源而被阻塞，但不释放已有资源
 不可剥夺  ：已占资源不能被强制剥夺，只能由持有者主动释放
 循环等待  ：多个线程形成循环等待资源的链路

 GCD 中的死锁场景：
 在当前串行队列中同步（sync）派发任务到同一串行队列 → 循环等待死锁
 主线程中 dispatch_sync(dispatch_get_main_queue(), ...) → 主线程等自己，死锁


 ============================================================
 八、经典并发问题
 ============================================================

 生产者-消费者（Producer-Consumer）
   场景：生产者向缓冲区写，消费者从缓冲区读，需防止溢出和空读
   方案：信号量（空槽信号量 + 满槽信号量）+ 互斥锁保护缓冲区
   iOS：dispatch_semaphore_t + NSLock / @synchronized

 读者-写者（Readers-Writers）
   场景：多读者可同时读，写者写时互斥
   方案：dispatch_barrier_async（写时独占）+ dispatch_async（读并发）
   iOS：pthread_rwlock_t 或 dispatch_barrier_async

 哲学家就餐（Dining Philosophers）
   场景：N 个哲学家争用 N 把叉子，需防止死锁和饥饿
   解法：资源有序分配（编号限制）、仲裁者模式、限制同时进餐人数（信号量）

 理发师问题（Sleeping Barber）
   场景：理发师无客则睡，有客则醒；客满则离开
   方案：信号量（等待席位计数）+ 互斥锁

 唤醒-等待经典模型 (Sleeping Barber Problem)
    问题描述：理发师和客户，客户到店后如果有空位就等待，否则离开；理发师没客人就休眠，有客人则唤醒。
    考点：条件变量、队列、信号量。


 ============================================================
 九、NSOperation 与 GCD 对比
 ============================================================

 GCD
   本质：C 语言 API，系统级线程池管理
   依赖：不支持（可用 barrier 模拟）
   状态查询：不支持（无 isExecuting/isCancelled 等 KVO）
   取消：dispatch_block_cancel（仅能取消未开始的任务）
   优先级：队列级别 QoS
   最大并发数：通过 semaphore 模拟
   适用场景：简单高性能并发、一次性短任务

 NSOperation
   本质：GCD 的 OC 封装，面向对象
   依赖：addDependency: 支持任务间依赖（有向无环图）
   状态查询：isReady / isExecuting / isFinished / isCancelled（支持 KVO）
   取消：cancelAllOperations / cancel（正在执行的需自行检测 isCancelled）
   优先级：queuePriority（任务级别）+ qualityOfService
   最大并发数：maxConcurrentOperationCount（直接设置）
   适用场景：复杂依赖关系、需要取消/暂停/状态监控的任务

 选型建议：
 简单并发、无依赖 → GCD（更高效）
 有依赖、需取消/KVO、面向对象管理 → NSOperation


 ============================================================
 十、线程与 CPU 的关系
 ============================================================

 物理限制：
 - CPU 核心数决定真正并行执行的线程数上限
 时间片轮转：
 - 单个核心通过快速切换执行多个线程
 任务类型：
 - CPU 密集型：最优线程数 = CPU 核心数
 - I/O 密集型：可以超过核心数
 - 系统调度：现代系统智能调度线程到合适的核心
 性能优化：
 - 使用 QoS 设置优先级
 - 避免过度创建线程
 - 监控 CPU 使用率
 - 让 GCD 管理线程池
 

 ============================================================
 十一、Core Foundation 与 Foundation 桥接
 ============================================================

 Foundation（OC）与 Core Foundation（C）可互相转换：
 NSString → CFStringRef ：(__bridge CFStringRef)str          （不转移所有权）
 CFStringRef → NSString  ：(__bridge NSString *)cfStr         （不转移所有权）
 CFStringRef → NSString  ：(__bridge_transfer NSString *)cfStr （CF 所有权转给 ARC）
 NSString → CFStringRef  ：(__bridge_retained CFStringRef)str  （ARC 所有权转给 CF）

 CF 对象内存管理（ARC 不接管）：
 函数名含 create/copy/retain/new → 需要手动 CFRelease()
 CFArrayRef arr = CFArrayCreate(...); CFRelease(arr);
 GCD 对象（dispatch_queue_t 等）在 ARC 下无需手动 release。


 ============================================================
 十二、常见面试问题
 ============================================================

 Q：dispatch_async 到主队列和 dispatch_sync 到主队列的区别？
 A：dispatch_async(main_queue)：异步提交，不阻塞当前线程，
    block 在主线程空闲后执行，不会死锁。
    dispatch_sync(main_queue)：同步提交，若在主线程调用则死锁——
    主线程等 block 完成才能继续，而 block 等主线程空闲才能执行，互相等待。

 Q：dispatch_group_enter/leave 与 dispatch_group_async 的区别？
 A：dispatch_group_async 只能包裹同步代码；若任务内部有异步回调（如网络请求），
    group 会在 block 执行完毕（而非回调完成）就认为该任务结束，导致 notify 提前触发。
    dispatch_group_enter/leave 手动控制计数，可在异步回调中调用 leave，
    确保真正完成后才触发 notify，适合异步嵌套场景。

 Q：dispatch_barrier_async 为什么对全局并发队列无效？
 A：全局并发队列由系统共享，其他模块也在向该队列提交任务。
    若 barrier 对全局队列有效，它必须等待全局队列中所有任务（包括其他模块的）完成，
    这会导致不可预期的性能问题和逻辑错误。
    因此 Apple 规定 barrier 只对自定义并发队列有效，开发者对该队列有完整控制权。

 Q：dispatch_once 是如何保证线程安全的？
 A：dispatch_once_t 是一个 long 型原子标志位（初始为 0）。
    首次调用时通过 atomic compare-and-swap 原子操作将状态置为"执行中"，
    执行 block 完毕后设置为"已完成"（~0L）。
    并发调用时，其他线程检测到"执行中"状态会自旋等待，
    直到状态变为"已完成"才返回（内存屏障保证可见性）。
    单例最佳实践：结合静态变量保证线程安全且高效。

 Q：NSOperationQueue 如何实现任务依赖？底层怎么实现的？
 A：调用 [opB addDependency:opA] 后，opB 的 isReady 依赖于 opA 的 isFinished。
    NSOperationQueue 内部通过 KVO 观察每个 Operation 的 isFinished，
    当被依赖的 Operation 完成时，依赖它的 Operation 的 isReady 变为 YES，
    队列才将其提交给底层 GCD 执行。
    依赖关系构成 DAG（有向无环图），有环则会死锁（队列永久阻塞）。

 */

@implementation IBController3

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.filmTickets = 100;
    self.lock = [[NSLock alloc] init];

    // 1. 生产者-消费者：2 个生产者，2 个消费者，缓冲区大小 5
    [IBProducerConsumer runDemoWithProducers:2 consumers:2 bufferSize:5];

    // 2. 读者-写者（两种方案）
//    [IBReadersWriters runDemoBarrier];
//    [IBReadersWriters runDemoPthreadRWLock];

    // 3. 哲学家就餐：5 位哲学家
//    [IBDiningPhilosophers runDemoWithPhilosophers:5];

    // 4. 理发师问题（信号量方案）：3 个座位，8 位顾客
//    [IBSleepingBarber runDemoWithChairs:3 customers:8];

    // 5. 理发师问题（NSCondition 方案）：3 个座位，8 位顾客
//    [IBSleepingBarberCV runDemoWithChairs:3 customers:8];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"-------------------------------------");
    
//    [self test0];
//    [self test1];
//    [self test1_1];
//    [self test2];
//    [self test3];
//    [self test4];
//    [self test4_1];
//    [self test4_2];
//    [self test4_3];
//    [self test5];
//    [self test6];
//    [self test7];
//    [self test8];
//    [self test9];
    [self test9_1];
//    [self test9_21];
//    [self test9_2];
//    [self test9_3];
//    [self test10];
//    [self test11];
//    [self test12];
//    [self test13];
//    [self test14];
//    [self test15];
//    [self test16];
    NSLog(@"++++++++++++++++++++++++++++++++++++");
    
}

- (void)test16 {
    dispatch_queue_t queue = dispatch_queue_create("b", DISPATCH_QUEUE_SERIAL); // abc134d5
//    dispatch_queue_t queue = dispatch_queue_create("b", DISPATCH_QUEUE_CONCURRENT); //abc3124d5
    
    dispatch_async(queue, ^{
        sleep(3);
        NSLog(@"1");
//        dispatch_sync(queue, ^{ // 串行队列会崩溃
//            NSLog(@"2");
//        });
    });
    
    NSLog(@"a");
    
    NSLog(@"b");
    
    dispatch_async(queue, ^{
        NSLog(@"3");
    });
    
    NSLog(@"c");
    
    dispatch_sync(queue, ^{
        sleep(5);
        NSLog(@"4");
    });
    
    NSLog(@"d");
    
    dispatch_async(queue, ^{
        NSLog(@"5");
    });
    
}

//解束正在执行的任务
- (void)test15 {
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(work) object:nil];
    [self.thread start];
    sleep(3);
    NSLog(@"结束线程");
    [self.thread cancel];//结束未执行的任务或者标记正在执行的任务要取消
}

- (void)work {
    for (long i=0; i<10; i++) {
        NSLog(@"i:%ld",i);
        sleep(1);
        if (self.thread.isCancelled) {
            [NSThread exit];
        }
    };
}

/**
 NSOperationQueue主线程更新UI和取消没有执行的任务
 */
- (void)test14 {
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 4;
    [operationQueue addOperationWithBlock:^{
        NSLog(@"任务一");
    }];
    NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(run) object:nil];
    NSOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"主线程更新UI......%@",[NSThread currentThread]);;
    }];
    [op addDependency:operationQueue.operations.firstObject];
    [op1 addDependency:op];
    [operationQueue addOperation:op];
    [[NSOperationQueue mainQueue] addOperation:op1];
    
//    [operationQueue cancelAllOperations]; //移除队列里面所有的操作，但正在执行的操作无法移除
//    operationQueue.suspended = YES; //正在执行的任务无法挂起
//    NSLog(@"结束");
}

- (void)run {
    NSLog(@"----耗时操作开始----");
    for (long i=0; i<10; i++) {
        NSLog(@"j:%ld",i);
        sleep(1);
        if (i == 6) {
            
            return;
        }
    };
    NSLog(@"----耗时操作完成----");
}

//结束没有执行的线程
- (void)test13 {
    
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_block_t block1 = dispatch_block_create(0, ^{
        NSLog(@"--1--");
    });
    dispatch_block_t block2 = dispatch_block_create(0, ^{
        NSLog(@"---2---");
    });
    dispatch_block_t block3 = dispatch_block_create(0, ^{
        for (long i=0; i<100000; i++) {
            NSLog(@"i:%ld",i);
            sleep(1);
        };
    });
    dispatch_async(queue, block1);
    dispatch_async(queue, block2);
    dispatch_async(queue, block3);
    dispatch_block_cancel(block2);//dispatch_block_cancel也只能取消尚未执行的任务，对正在执行的任务不起作用
}

//GCD结束正在执行的线程
- (void)test12 {
    __block BOOL gcdFlag = NO;

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_async(group, queue, ^{
        for (long i=0; i<100000; i++) {
            NSLog(@"i:%ld",i);
            if (i == 10) {
                gcdFlag = YES;
            }
            sleep(1);
            if (gcdFlag==YES) {
                NSLog(@"收到gcd停止信号");
                return;
            }
        };
    });
    dispatch_group_notify(group, queue, ^{
        NSLog(@"结束");
    });
    
}

static dispatch_queue_t safe_queue() {
    static dispatch_queue_t safe_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        safe_queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    });
    return safe_queue;
}

static void create_task_safely(dispatch_block_t block) {
    dispatch_sync(safe_queue(), block);
}

- (void)sellTickets {
    
    //方法二 放在串行队列中
    create_task_safely(^{
        self.filmTickets -= 1;
        NSLog(@"剩余票数----%d----",self.filmTickets);
    });
    
//    方法一
//    [self.lock lock];
//    [NSThread sleepForTimeInterval:0.02];
//    self.filmTickets -= 1;
//    NSLog(@"----%d----",self.filmTickets);
//    [self.lock unlock];
}

//测试锁
- (void)test11 {
    
    dispatch_queue_t queue = dispatch_queue_create("bowen", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i< self.filmTickets; i++) {
        dispatch_async(queue, ^{
            [self sellTickets];
        });
    }
}

/*
 分析：
 线程运行:
 - 固定先后：137
 - 相对固定：456
 - 不确定性：2在456任意位置插入
 */
- (void)test10 {
    dispatch_queue_t queue = dispatch_queue_create("b", DISPATCH_QUEUE_SERIAL);
    NSLog(@"----1----%@",[NSThread currentThread]);
    
    dispatch_async(dispatch_get_main_queue(), ^{ // 当前loop做完任务，下一个loop运行
        for (int i = 0; i < 10; i ++) {
            NSLog(@"----2----%@",[NSThread currentThread]);
        }
    });
    dispatch_queue_t queue1 = dispatch_queue_create("b", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue1, ^{
        NSLog(@"----3----%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"----4----%@",[NSThread currentThread]);
        NSLog(@"----5----%@",[NSThread currentThread]);
//        dispatch_sync(queue, ^{
//            NSLog(@"----特例----%@",[NSThread currentThread]);
//        });
    });
    
    dispatch_async(queue, ^{
        NSLog(@"----6----%@",[NSThread currentThread]);
    });
    NSLog(@"----7----%@",[NSThread currentThread]);
    
    NSLog(@"1111111111111111111111111111111111111");
}

/**
 不同串行队列，不死锁：
 顺序：begin1 -> end6 -> sync2 -> sync3 -> async5 -> sync4
 */
- (void)test9_3 {
    NSLog(@"----begin1----");
    dispatch_queue_t queue = dispatch_queue_create("123", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue1 = dispatch_queue_create("123", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"----sync2----%@",[NSThread currentThread]);
        });
        dispatch_sync(queue1, ^{
            NSLog(@"----sync3----%@",[NSThread currentThread]);
        });
        dispatch_async(dispatch_get_main_queue(), ^{ // 有个投递的流程，打印肯定在5后
            NSLog(@"----sync4----%@",[NSThread currentThread]);
        });
        NSLog(@"----async5----%@",[NSThread currentThread]);
    });
    NSLog(@"----end6----");
}

/*
 两种： 不确定的只有：sync4 与 async5 的相对顺序
 begin1，end6，sync2，async5，sync4，sync3
 begin1，end6，sync2，async4，sync5，sync3
 
 */
- (void)test9_21 {
    NSLog(@"----begin1----");
    dispatch_queue_t queue = dispatch_queue_create("123", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"----sync2----%@",[NSThread currentThread]);
        });
        dispatch_async(queue, ^{
            NSLog(@"----sync3----%@",[NSThread currentThread]);
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"----sync4----%@",[NSThread currentThread]);
        });
        NSLog(@"----async5----%@",[NSThread currentThread]);
    });
    NSLog(@"----end6----");
}

/**
 考察：sync3死锁
 */
- (void)test9_2 {
    NSLog(@"----begin1----");
    dispatch_queue_t queue = dispatch_queue_create("123", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue1 = dispatch_queue_create("234", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("345", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        dispatch_sync(queue1, ^{
            NSLog(@"----sync1----%@",[NSThread currentThread]);
        });
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"----sync2----%@",[NSThread currentThread]);
        });
        dispatch_sync(queue, ^{
            NSLog(@"----sync3----%@",[NSThread currentThread]);
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"----sync4----%@",[NSThread currentThread]);
        });
        dispatch_sync(queue2, ^{
            NSLog(@"----sync5----%@",[NSThread currentThread]);
        });
        NSLog(@"----async6----%@",[NSThread currentThread]);
    });
    NSLog(@"----end6----");
}

/**
 考察：sync2立马到主线程中执行
 固定顺序
 主线程内：begin1 先打印；end6 一定打印 10 次（顺序不变）。
 全局队列 block 内：sync1 -> sync2 -> sync3 -> (投递 sync4) -> async5(×10)
 且 sync4 只能在 sync3 之后才可能出现。
 可能穿插的位置
 sync1 可出现在 end6×10 的前/中/后（并发）。
 sync2（主队列同步执行）可插在 end6×10 的中间或在其后出现（取决于主线程何时处理主队列）。
 sync4 与 async5×10 无固定先后：可在 async5 前、插在中间、或在其后执行。

 */
- (void)test9_1 {
    NSLog(@"----begin1----");
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        NSLog(@"----sync1----%@",[NSThread currentThread]);
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"----sync2----%@",[NSThread currentThread]);
        });
        dispatch_sync(queue, ^{
            NSLog(@"----sync3----%@",[NSThread currentThread]);
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"----sync4----%@",[NSThread currentThread]);
        });
        for (int i = 0; i < 10; i++) {
            NSLog(@"----async5----%@",[NSThread currentThread]);
        }
    });
    for (int i = 0; i < 10; i++) {
        NSLog(@"----end6----");
    }
}

/**
 同步主队列 --- 不能用(死锁)
 在主线程中执行
 理解：主队列在同步任务的条件下,必须主线程空闲的时候,才可以添加任务到队列中
 */
- (void)test9 {
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_sync(queue, ^{
        NSLog(@"----1----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----2----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----3----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----4----%@",[NSThread currentThread]);
    });
}

/**
 * sync（同步） --串行队列
 * 会不会创建线程：不会
 * 线程的执行方法：串行（一个任务执行完毕后，再执行下一个任务）
 * 在主线程中执行串行队列，完成后回到主线程在执行主队列
 */
- (void)test8 {
    dispatch_queue_t queue = dispatch_queue_create("bowen", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(queue, ^{
        NSLog(@"----1----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----2----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----3----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----4----%@",[NSThread currentThread]);
    });
}

/**
 * sync（同步） --并发队列
 * 会不会创建线程：不会,在主线程中运行
 * 任务的执行方式：串行（一个任务执行完毕后，再执行下一个任务）
 * 并发队列失去并发功能
 * 在主线程中执行并发队列，完成后回到主线程执行主队列
 */
- (void)test7 {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        NSLog(@"----1----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----2----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----3----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"----4----%@",[NSThread currentThread]);
    });
}

/**
 * async（异步） --主队列（很常用）（特殊）
 * 会不会创建线程：不会
 * 任务的执行方式：串行
 * 一般用在线程之间的通讯
 * 理解：异步主队列，先把任务添加到主队列中，等主线程空闲执行任务
 */
- (void)test6 {
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        NSLog(@"----1----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----2----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----3----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----4----%@",[NSThread currentThread]);
    });
}

/**
 * async（异步） --串行队列（有时用）
 * 会不会创建线程：会，创建一条
 * 线程的执行方法：串行（一个任务执行完毕后，再执行下一个任务）
 */
- (void)test5 {
    dispatch_queue_t queue = dispatch_queue_create("bowen", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        NSLog(@"----1----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----2----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----3----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----4----%@",[NSThread currentThread]);
    });

}



/**
 * async（异步） --并发队列（最常用）
 * 会不会创建线程：会，并且创建多条线程，有复用执行完的线程可能
 * 任务的执行方式：并发执行
 */
- (void)test4 {
    
    dispatch_queue_t queue = dispatch_queue_create("bowen", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"----1----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----2----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----3----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----4----%@",[NSThread currentThread]);
    });
}


/**
 三个线程顺序重复执行,dispatch_semaphore_t 卡住 主线程
 */
- (void)test4_2 {
    
    dispatch_semaphore_t sema1 = dispatch_semaphore_create(1);
    dispatch_semaphore_t sema2 = dispatch_semaphore_create(0);
    dispatch_semaphore_t sema3 = dispatch_semaphore_create(0);
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 3;
    
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        [[NSThread currentThread] setName:@"thread1"];
        while (1) {
            dispatch_semaphore_wait(sema1, DISPATCH_TIME_FOREVER);
            NSLog(@"----1----%@",[NSThread currentThread]);
            dispatch_semaphore_signal(sema2);
        }
    }];
    
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        [[NSThread currentThread] setName:@"thread2"];
        while (1) {
            dispatch_semaphore_wait(sema2, DISPATCH_TIME_FOREVER);
            NSLog(@"----2----%@",[NSThread currentThread]);
            dispatch_semaphore_signal(sema3);
        }
    }];
    
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        [[NSThread currentThread] setName:@"thread3"];
        while (1) {
            dispatch_semaphore_wait(sema3, DISPATCH_TIME_FOREVER);
            NSLog(@"----3----%@",[NSThread currentThread]);
            dispatch_semaphore_signal(sema1);
        }
    }];

    [queue addOperations:@[op1, op2, op3] waitUntilFinished:NO];
}

- (void)test4_3 {
    
    __block BOOL thread1 = YES;
    __block BOOL thread2 = NO;
    __block BOOL thread3 = NO;
    
    dispatch_queue_t queue = dispatch_queue_create("bowen", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        [[NSThread currentThread] setName:@"thread1"];
        while (1) {
            if (thread1) {
                thread1 = NO;
                NSLog(@"----1----%@",[NSThread currentThread]);
                thread2 = YES;
            }
        }
    });
    
    dispatch_async(queue, ^{
        [[NSThread currentThread] setName:@"thread2"];
        while (1) {
            if (thread2) {
                thread2 = NO;
                NSLog(@"----2----%@",[NSThread currentThread]);
                thread3 = YES;
            }
        }
    });
    
    dispatch_async(queue, ^{
        [[NSThread currentThread] setName:@"thread3"];
        while (1) {
            if (thread3) {
                thread3 = NO;
                NSLog(@"----3----%@",[NSThread currentThread]);
                thread1 = YES;
            }
        }
    });
}

/// 监听网络统一返回，并行请求
- (void)test1_1
{
    dispatch_group_t group1 = dispatch_group_create();
    dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_enter(group1);
    dispatch_group_async(group1, queue1, ^{
        dispatch_group_leave(group1);
        NSLog(@"group1 --- 1---%@",[NSThread currentThread]);
    });
    NSLog(@"============ 分割线1 ==============");
    dispatch_group_enter(group1);
    dispatch_group_async(group1, queue1, ^{
        dispatch_group_leave(group1);
        NSLog(@"group1 --- 2---%@",[NSThread currentThread]);

    });
    NSLog(@"============ 分割线2 ==============");
    dispatch_group_enter(group1);
    dispatch_group_async(group1, queue1, ^{
        dispatch_group_leave(group1);
        NSLog(@"group1 --- 3---%@",[NSThread currentThread]);
    });
    NSLog(@"============ 分割线3 ==============");
    dispatch_group_enter(group1);
    dispatch_group_async(group1, queue1, ^{
        dispatch_group_leave(group1);
        NSLog(@"group1 --- 4---%@",[NSThread currentThread]);
    });
    
    dispatch_group_notify(group1, queue1, ^{
       NSLog(@"group1 --- 结束 ---%@",[NSThread currentThread]);
    });

}

/**
 组内并行，组间串行
 */
- (void)test1 {
    
    dispatch_group_t group1 = dispatch_group_create();
    dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_async(group1, queue1, ^{
        NSLog(@"group1 --- 1---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group1, queue1, ^{
        NSLog(@"group1 --- 2---%@",[NSThread currentThread]);

    });
    dispatch_group_async(group1, queue1, ^{
        NSLog(@"group1 --- 3---%@",[NSThread currentThread]);

    });
    dispatch_group_async(group1, queue1, ^{
        NSLog(@"group1 --- 4---%@",[NSThread currentThread]);

    });
    
    dispatch_group_wait(group1,DISPATCH_TIME_FOREVER);
    
    dispatch_group_t group2 = dispatch_group_create();
    dispatch_queue_t queue2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_group_async(group2, queue2, ^{
        NSLog(@"group2 --- 1---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group2, queue2, ^{
        NSLog(@"group2 --- 2---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group2, queue2, ^{
        NSLog(@"group2 --- 3---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group2, queue2, ^{
        NSLog(@"group2 --- 4---%@",[NSThread currentThread]);
    });
}


- (void)test2 {
    
    NSOperationQueue *oq = [[NSOperationQueue alloc] init];
    oq.maxConcurrentOperationCount = 1;
    [oq addOperationWithBlock:^{
        NSLog(@"1--%@",[NSThread currentThread]);
    }];
    [oq addOperationWithBlock:^{
        NSLog(@"2--%@",[NSThread currentThread]);
    }];
    [oq addOperationWithBlock:^{
        NSLog(@"3--%@",[NSThread currentThread]);
    }];
    [oq addOperationWithBlock:^{
        NSLog(@"4--%@",[NSThread currentThread]);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"----5----%@",[NSThread currentThread]);
        }];
    }];
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"6--%@",[NSThread currentThread]);
    }];
    [operation addExecutionBlock:^{
        NSLog(@"7--%@",[NSThread currentThread]);

    }];
    [operation addExecutionBlock:^{
        NSLog(@"8--%@",[NSThread currentThread]);
    }];
    [operation start];
}

/**
 组内串行，组间并行
 */
- (void)test3 {
    
    dispatch_group_t group1 = dispatch_group_create();
    dispatch_queue_t queue1 = dispatch_queue_create("leador", DISPATCH_QUEUE_SERIAL);
    dispatch_group_async(group1, queue1, ^{
        NSLog(@"group1 --- 1---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group1, queue1, ^{
        NSLog(@"group1 --- 2---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group1, queue1, ^{
        NSLog(@"group1 --- 3---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group1, queue1, ^{
        NSLog(@"group1 --- 4---%@",[NSThread currentThread]);
    });
    
    dispatch_group_notify(group1, queue1, ^{
        NSLog(@"123");
    });

    dispatch_group_t group2 = dispatch_group_create();
    dispatch_queue_t queue2 = dispatch_queue_create("leador1", DISPATCH_QUEUE_SERIAL);

    dispatch_group_async(group2, queue2, ^{
        NSLog(@"group2 --- 1---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group2, queue2, ^{
        NSLog(@"group2 --- 2---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group2, queue2, ^{
        NSLog(@"group2 --- 3---%@",[NSThread currentThread]);
    });
    dispatch_group_async(group2, queue2, ^{
        NSLog(@"group2 --- 4---%@",[NSThread currentThread]);
    });
}

/*
 通知，代理，KVO同步执行
 在哪个线程中发出通知或者代理回到就在哪个线程中执行
 */
- (void) test0 {//能收到
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        [[NSThread currentThread] setName:@"obseverrName"];
        NSLog(@"1--%@",[NSThread currentThread]);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti) name:@"hehe" object:nil];
    });
    
    dispatch_async(queue, ^{
        [[NSThread currentThread] setName:@"postName"];
        NSLog(@"2--%@",[NSThread currentThread]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hehe" object:nil];
        NSLog(@"123");
    });
    
    NSLog(@"456");
}
- (void)noti {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSLog(@"3--%@",[NSThread currentThread]);
    });
    NSLog(@"4--%@",[NSThread currentThread]);
}


@end
