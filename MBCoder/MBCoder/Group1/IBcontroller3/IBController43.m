//
//  IBController43.m
//  IBCoder1
//
//  Created by Bowen on 2019/4/15.
//  Copyright © 2019 BowenCoder. All rights reserved.
//

#import "IBController43.h"

/*

 ============================================================
 寄存器、volatile、atomic 与线程安全 面试题总结
 ============================================================

 一、寄存器与内存访问
 ──────────────────────────────────────────

 【寄存器的工作流程】
 CPU 的所有运算必须在寄存器中进行，无法直接操作内存：
 1. 从内存（或 I/O 端口）将数据读取到寄存器
 2. 在寄存器中执行运算（加减乘除、逻辑运算等）
 3. 将寄存器中的结果回写到内存（或 I/O 端口）

 【线程的私有数据】
 同一进程中的多条线程共享：虚拟地址空间、文件描述符、信号处理等
 每条线程各自独有：
 - 调用栈（Call Stack）：函数调用链、局部变量
 - 寄存器环境（Register Context）：程序计数器、通用寄存器等
 - 线程本地存储（Thread-Local Storage, TLS）


 ============================================================
 二、volatile 关键字
 ============================================================

 【作用】
 volatile 告诉编译器：每次访问该变量时必须直接从内存地址读取，
 禁止编译器将其缓存到寄存器中进行优化。

 【解决的问题：可见性】
 多线程场景下，每个线程的寄存器可能缓存了某全局变量的副本。
 当线程 A 修改该变量后，线程 B 的寄存器缓存不感知变化，仍使用旧值，
 导致同一变量在不同线程间出现不一致。

 使用 volatile 后：
 a. 写操作：强制将修改后的值刷新到主内存
 b. 读操作：强制从主内存读取最新值，跳过寄存器缓存
 c. 效果：保证变量的"可见性"，其他线程能及时读到最新值

 【volatile 的局限性】
 ⚠️ volatile 只保证可见性，不保证原子性
 例：i++ 在 CPU 层面是"读-改-写"三步操作，volatile 无法使其变成原子操作，
 多线程并发执行 i++ 仍然可能导致数据丢失（竞态条件）。
 若需原子性，应使用锁或原子操作函数。

 【与 block 的关联】
 block 捕获外部变量时会对其值进行"快照"（copy），
 volatile 的"禁止缓存"语义与 block 值捕获的"锁定"行为类似，
 但两者机制不同：block 是语言层面的捕获，volatile 是 CPU/编译器层面的内存约束。


 ============================================================
 三、原子操作（Atomic Operation）
 ============================================================

 【概念】
 原子操作是"不可被中断的一个或一系列操作"。
 在多线程环境中，原子操作执行期间不会被上下文切换打断，
 要么完整执行，要么完全不执行，不存在中间状态。

 【CPU 层面的原子性保障】
 - 单个内存对齐的读/写操作在大多数 CPU 架构上天然是原子的
 - 复合操作（如 i++）需要硬件指令支持（如 x86 的 LOCK 前缀、ARM 的 LDREX/STREX）

 【iOS 中的原子操作 API】
 - OSAtomic 系列（已废弃）：OSAtomicIncrement32、OSAtomicCompareAndSwap32 等
 - C11 标准 stdatomic.h（推荐）：atomic_fetch_add、atomic_compare_exchange 等
 - Swift 中暂无内置原子类型，通常用 DispatchQueue 或 NSLock 替代


 ============================================================
 四、atomic 与 nonatomic
 ============================================================

 【nonatomic：直接内存访问】
 直接从内存地址读/写属性值，不加任何保护。
 - 速度快，无锁开销
 - 不保证多线程下读写的原子性
 - 适用场景：UI 属性（仅在主线程操作），或已通过其他机制保证线程安全的场景

 【atomic：属性读写的原子性保障】
 ObjC 默认属性关键字（default），底层通过 objc_getProperty / objc_setProperty 实现。
 具体实现：在 getter/setter 中使用 os_unfair_lock（旧版本为 spinlock）保护读写操作，
 保证单次 get 或 set 是完整的原子操作。

 ⚠️ atomic 的两个常见误解：
 1. atomic 不等于线程安全
    atomic 只保证单次属性读或写的原子性，不保证"读-判断-写"等复合操作的线程安全。
    例：两个线程同时执行 if (arr.count > 0) { [arr removeLastObject]; }
    atomic 的 count 和 removeLastObject 各自是原子的，但两步合起来仍有竞态条件。

 2. atomic 没有内存"加锁"的说法
    atomic 是寄存器层面的操作保护，确保每次 get/set 得到的是一个完整计算后的值，
    而非从内存中读到"写了一半"的中间态数据。

 【对比】
 性能    ：nonatomic 更快（无锁开销）
 安全性  ：atomic 只保证单次读/写原子；nonatomic 完全无保护
 使用建议：iOS 开发中几乎所有属性都用 nonatomic，线程安全由更上层的机制（锁/队列）保证


 ============================================================
 五、线程安全三要素
 ============================================================

 【原子性（Atomicity）】
 操作要么完整执行，要么完全不执行，不存在中间状态被其他线程观察到。
 保障方式：互斥锁、原子操作指令

 【可见性（Visibility）】
 一个线程对共享变量的修改，另一个线程能及时读到最新值。
 保障方式：volatile、内存屏障（Memory Barrier）、锁的 unlock 触发内存屏障

 【有序性（Ordering）】
 编译器和 CPU 可能对指令进行重排序优化，有序性保证执行顺序的正确性。
 保障方式：内存屏障、volatile（防止编译器重排）、锁（隐式内存屏障）

 ⚠️ volatile 只保证可见性和禁止编译器重排，不保证原子性；
    atomic 属性只保证原子性；
    完整的线程安全需要三者同时满足。


 ============================================================
 六、iOS 常见锁与同步机制
 ============================================================

 （各类锁详解、性能排行、死锁场景详见 IBController19）

*/

@interface IBController43 ()

@property (nonatomic, strong) NSThread *thread1;
@property (nonatomic, strong) NSThread *thread2;
@property (nonatomic, strong) NSThread *thread3;

@end

@implementation IBController43
{
//    volatile BOOL flag;
    BOOL flag;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    flag = NO;
}

/*
 test1：演示 BOOL flag 在多线程并发读写时的可见性问题。
 线程 A 循环读取 flag，线程 B sleep(1) 后将 flag 设为 YES。
 若未加 volatile，编译器优化可能导致线程 A 始终读取寄存器缓存值而无法退出循环。
 改为 volatile BOOL flag 可保证可见性，但仍不保证原子性。
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self test];
    [self test1];
}

- (void)test1 {
    dispatch_queue_t queue = dispatch_queue_create("bowen", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        while (1) {
            if (self->flag) {
                NSLog(@"--------");
                break;
            } else {
                NSLog(@"========");
            }
        }
    });
    
    dispatch_async(queue, ^{
        sleep(1);
        self->flag = YES;
        NSLog(@"Flag is %d", self->flag);
    });
}

/*
 test：演示 __block int i 在多线程并发自增时的竞态条件。
 三个并发任务同时对 i 进行 i++ 操作，由于 i++ 非原子（读-改-写三步），
 最终 i 的值可能小于 3（数据丢失）。
 使用 volatile 只能保证可见性，不能解决原子性问题；
 正确做法应使用 OSAtomicIncrement32 或加锁。
 */
- (void)test {
    __block int i = 0;
//    __block volatile int i = 0;
    dispatch_queue_t queue = dispatch_queue_create("bowen", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"---1取值：%d", i);
        i++;
        NSLog(@"----1----新值：%d",i);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"---2取值：%d", i);
        i++;
        NSLog(@"----2----新值：%d",i);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"---3取值：%d", i);
        i++;
        NSLog(@"----3----新值：%d",i++);
    });
}

@end
