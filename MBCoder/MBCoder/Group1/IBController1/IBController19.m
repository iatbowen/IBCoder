//
//  IBController19.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/13.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController19.h"
#import <pthread.h>
#import "MBProducerConsumerQueue.h"
#import <Foundation/Foundation.h>

@interface IBReaderWriter : NSObject

- (void)startReading;
- (void)endReading;
- (void)startWriting;
- (void)endWriting;

@end

@implementation IBReaderWriter {
    dispatch_semaphore_t _readLock;
    dispatch_semaphore_t _writeLock;
    NSInteger _readCount;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _readLock = dispatch_semaphore_create(1);
        _writeLock = dispatch_semaphore_create(1);
        _readCount = 0;
    }
    return self;
}

- (void)startReading {
    dispatch_semaphore_wait(_readLock, DISPATCH_TIME_FOREVER);
    _readCount++;
    if (_readCount == 1) {
        dispatch_semaphore_wait(_writeLock, DISPATCH_TIME_FOREVER);
    }
    dispatch_semaphore_signal(_readLock);
}

- (void)endReading {
    dispatch_semaphore_wait(_readLock, DISPATCH_TIME_FOREVER);
    _readCount--;
    if (_readCount == 0) {
        dispatch_semaphore_signal(_writeLock);
    }
    dispatch_semaphore_signal(_readLock);
}

- (void)startWriting {
    dispatch_semaphore_wait(_writeLock, DISPATCH_TIME_FOREVER);
}

- (void)endWriting {
    dispatch_semaphore_signal(_writeLock);
}

@end


@interface IBController19 ()

@property (nonatomic, strong) MBProducerConsumerQueue *queue;

@end

@implementation IBController19

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.queue = [[MBProducerConsumerQueue alloc] init];
    UIButton *btn = [[UIButton alloc] init];
    btn.frame = CGRectMake(0, 100, 50, 44);
    btn.backgroundColor = [UIColor orangeColor];
    [btn addTarget:self action:@selector(producer) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *btn1 = [[UIButton alloc] init];
    btn1.frame = CGRectMake(0, 200, 50, 44);
    btn1.backgroundColor = [UIColor orangeColor];
    [btn1 addTarget:self action:@selector(consumer) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
}

- (void)producer {
    [self.queue scheduleProducerQueue];
    [self.queue scheduleConsumerQueue];
}

- (void)consumer {
    [self.queue scheduleConsumerQueue];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self testReaderWriter];
}

- (void)testReaderWriter {
    // 示例使用
    IBReaderWriter *readerWriter = [[IBReaderWriter alloc] init];

    // 读者线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [readerWriter startReading];
        // 读取共享资源
        NSLog(@"Reading...");
        [readerWriter endReading];
    });

    // 写者线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [readerWriter startWriting];
        // 写入共享资源
        NSLog(@"Writing...");
        [readerWriter endWriting];
    });
}

- (void)mutexLock{
    //pthread_mutex
    pthread_mutex_t mutex;
    pthread_mutex_init(&mutex,NULL);
    pthread_mutex_lock(&mutex);
    pthread_mutex_unlock(&mutex);

    //NSLock
    NSLock *lock = [[NSLock alloc] init];
    lock.name = @"lock";
    [lock lock];
    [lock unlock];
    
    //synchronized
    @synchronized (self) {
        
    }
    
}

- (void)RecursiveLock{
    NSRecursiveLock *lock = [NSRecursiveLock alloc];
    [lock lock];
    [lock lock];
    
    [lock unlock];
    [lock unlock];

}

- (void)conditionLock{
    __block NSCondition *condition;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        condition = [[NSCondition alloc] init];
        [condition wait];
        NSLog(@"finish----");
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [NSThread sleepForTimeInterval:5.0];
        [condition signal];
    });
}

- (void)semaphore{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"semaphoreFinish---");
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [NSThread sleepForTimeInterval:5.0];
        dispatch_semaphore_signal(semaphore);
    });
}

@end


/*

 ============================================================
 iOS 锁与线程同步 面试题总结
 ============================================================

 一、各类锁详解
 ──────────────────────────────────────────

 【互斥锁（Mutex）】

 1. @synchronized(obj)
    最简单的互斥锁，传入任意 ObjC 对象作为锁标识，底层使用 pthread_mutex（递归模式）。
    自动处理加锁/解锁，支持异常安全（@try/@finally 包裹）。
    ⚠️ 性能最差：① 全局哈希表查找 SyncData；② 双重锁结构；③ 递归锁判断；④ 引用计数维护。
    适合低频、简单同步场景，不建议在高性能路径使用。

 2. NSLock
    对 pthread_mutex 的 ObjC 封装，提供 -lock / -unlock / -tryLock 接口。
    ⚠️ 不支持递归加锁（同一线程重复 lock 会死锁）。
    适合非递归、普通互斥场景。

 3. NSRecursiveLock
    支持同一线程递归加锁，底层为 pthread_mutex（递归模式）。
    适用于递归函数或嵌套调用同一临界区的场景。

 4. pthread_mutex_t
    POSIX 标准互斥锁，最底层的锁 API，无 ObjC 对象开销，性能优于 NSLock。
    支持普通、递归、错误检测三种模式（pthread_mutex_init 时通过 attr 设置）。

 【自旋锁（Spinlock）】

 5. OSSpinLock（已废弃，iOS 10+）
    等待时不让出 CPU，忙等（busy-wait），适合临界区极短的场景。
    废弃原因：优先级反转——低优先级线程持锁时，高优先级线程忙等占满 CPU，
    低优先级线程无法获得 CPU 时间片执行并释放锁，形成死锁式等待。

 6. os_unfair_lock（iOS 10+，OSSpinLock 的替代品）
    等待时让出 CPU 休眠（非忙等），并通过优先级继承解决优先级反转问题。
    性能接近 OSSpinLock，是目前 iOS 中性能最高的锁。
    ObjC atomic 属性底层即使用 os_unfair_lock。

    Q：为什么叫"不公平"？
    A：等待线程不按 FIFO 顺序唤醒，由内核调度决定，可能出现饥饿。
       这种设计避免了维护等待队列的开销，以换取极致性能。

    Q：os_unfair_lock 性能为什么高？
    A：① 数据结构仅 4 字节；② 无竞争时仅一次 CAS 原子操作；
       ③ 不支持递归，无重入判断；④ 直接 C 接口无 ObjC 消息发送开销。

    Q：什么是优先级继承？
    A：当高优先级线程等待低优先级线程持有的锁时，系统临时将低优先级线程的优先级
       提升到与高优先级线程相同，使其尽快执行完毕并释放锁。

 【读写锁（Read-Write Lock）】

 7. pthread_rwlock_t
    允许多个线程同时读，写操作独占（读写互斥、写写互斥、读读共享）。
    适合读多写少的场景（如配置读取、缓存访问）。

 8. dispatch_barrier_async（配合并发队列，推荐替代方案）
    读操作用 dispatch_async，写操作用 dispatch_barrier_async。
    barrier 任务执行时阻塞队列中其他任务，实现写独占；
    非 barrier 任务可并发执行，实现读并发。纯 GCD 方案，无额外锁开销。

 【信号量（Semaphore）】

 9. dispatch_semaphore_t
    计数信号量，可控制同时访问资源的线程数量。
    dispatch_semaphore_create(n)：初始计数值（n=1 相当于互斥锁，n>1 限制并发数）
    dispatch_semaphore_wait：计数 -1，为 0 时阻塞当前线程
    dispatch_semaphore_signal：计数 +1，若有等待线程则唤醒一个
    常用场景：限制并发数、实现互斥、异步转同步等待

    Q：dispatch_semaphore 为什么性能高？
    A：① 数据结构简单；② 直接 C 接口无 ObjC 消息发送开销；③ 无竞争时仅一次原子操作。

 【条件变量（Condition）】

 10. NSCondition / NSConditionLock
     基于条件的等待与通知机制，适合生产者-消费者模型。
     -wait：释放锁并挂起线程，等待条件满足（需在 while 循环中调用，防止虚假唤醒）
     -signal：唤醒一个等待线程
     -broadcast：唤醒所有等待线程

 【队列串行化（无锁方案）】

 11. 串行队列（Serial Queue）
     将对共享资源的所有访问派发到同一串行队列，天然保证顺序执行，无需显式加锁。
     简单、安全，适合大多数数据保护场景。


 ============================================================
 二、自旋锁 vs 互斥锁 选择原则
 ============================================================

 使用自旋锁更合适的场景：
 - 预计等待时间极短（临界区代码量少）
 - 多核 CPU，持锁线程可以在另一核上运行
 - 临界区经常被调用但竞争很少发生
 - CPU 资源充裕

 使用互斥锁更合适的场景：
 - 预计等待时间较长
 - 单核 CPU（自旋无意义，持锁线程无法被调度）
 - 临界区有 I/O 操作或复杂计算
 - 竞争激烈，线程等待频繁

 Q：自旋锁和互斥锁本质区别？
 A：自旋锁等待时忙等（while 循环消耗 CPU），适合短临界区；
    互斥锁等待时休眠（让出 CPU 进入内核等待队列），适合长临界区。
    现代 os_unfair_lock 属于互斥锁。


 ============================================================
 三、性能排行（由快到慢）
 ============================================================

 os_unfair_lock > OSSpinLock > dispatch_semaphore > pthread_mutex >
 NSCondition > NSLock > pthread_mutex(recursive) > NSRecursiveLock > NSConditionLock > @synchronized


 ============================================================
 四、锁的选择建议
 ============================================================

 简单互斥、低频访问      → @synchronized 或 NSLock
 高性能互斥              → os_unfair_lock 或 dispatch_semaphore
 递归调用中加锁          → NSRecursiveLock
 读多写少                → pthread_rwlock_t 或 dispatch_barrier_async
 控制最大并发数          → dispatch_semaphore（初始值设为 N）
 生产者-消费者模型       → NSCondition
 数据保护（通用）        → 串行队列（dispatch_queue serial）


 ============================================================
 五、iOS 常见死锁场景
 ============================================================

 1. 串行队列中同步派发自身（GCD）
    dispatch_queue_t queue = dispatch_queue_create("com.test.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        dispatch_sync(queue, ^{   // 死锁：queue 等自己完成才能执行 inner
            NSLog(@"inner");
        });
        NSLog(@"outer");
    });

 2. 非递归锁重入（NSLock / pthread_mutex 普通模式）
    NSLock *lock = [[NSLock alloc] init];
    - (void)methodA {
        [lock lock];
        [self methodB];    // methodB 内再次 lock，同一线程重入 → 死锁
        [lock unlock];
    }
    - (void)methodB {
        [lock lock];       // 同一线程二次加锁，非递归锁会永久阻塞
        [lock unlock];
    }
    解决方案：改用 NSRecursiveLock

 3. 多线程循环等待（AB-BA 锁顺序问题）
    // 线程 1            // 线程 2
    [lockA lock];        [lockB lock];
    [lockB lock];        [lockA lock];   // 互相持有对方需要的锁 → 循环等待
    解决方案：所有线程按固定顺序加锁

 4. 信号量 + 主队列同步嵌套死锁
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);   // 持有信号量
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER); // 主线程再等信号量 → 死锁
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_signal(semaphore);
    });

 */



