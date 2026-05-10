// IBSleepingBarber.m
// 理发师问题 — 信号量 + 互斥锁方案
//
// 信号量语义：
//   customerReady（初值 0）：有顾客坐下时 signal，理发师 wait 此信号后开剪
//   barberReady  （初值 0）：理发师空闲时 signal，顾客 wait 此信号后入座
//   seatMutex             ：保护 waitingCount，防止并发读写座位计数

#import "IBSleepingBarber.h"

@implementation IBSleepingBarber

+ (void)runDemoWithChairs:(NSInteger)chairs customers:(NSInteger)customers {
    NSLog(@"\n=== 理发师问题（信号量方案，seats=%ld，customers=%ld）===",
          (long)chairs, (long)customers);

    __block NSInteger waitingCount = 0;     // 当前等待座位的顾客数

    dispatch_semaphore_t customerReady = dispatch_semaphore_create(0);
    dispatch_semaphore_t barberReady   = dispatch_semaphore_create(0);
    NSLock *seatMutex = [[NSLock alloc] init];

    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // ── 理发师线程 ──
    dispatch_async(q, ^{
        NSInteger served = 0;
        while (served < customers) {
            // 等待顾客到来（无顾客则理发师"休眠"）
            NSLog(@"[理发师] 等待顾客...");
            dispatch_semaphore_wait(customerReady, DISPATCH_TIME_FOREVER);

            [seatMutex lock];
            waitingCount--;
            [seatMutex unlock];

            // 通知顾客：理发师准备好了，顾客可以坐到理发椅上
            dispatch_semaphore_signal(barberReady);

            // 理发
            NSLog(@"[理发师] 正在理发...（剩余等待 %ld 人）", (long)waitingCount);
            [NSThread sleepForTimeInterval:0.2];
            NSLog(@"[理发师] 理发完毕");
            served++;
        }
        NSLog(@"[理发师] 今日结束，共服务 %ld 位顾客", (long)served);
    });

    // ── 顾客线程（依次到来）──
    for (NSInteger i = 0; i < customers; i++) {
        NSInteger cid = i;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.08 * NSEC_PER_SEC)), q, ^{
            [seatMutex lock];
            if (waitingCount < chairs) {
                // 有空位：坐下等待
                waitingCount++;
                NSLog(@"[顾客 %ld] 入座等待（等待中 %ld 人）", (long)cid, (long)waitingCount);
                [seatMutex unlock];

                // 通知理发师：有顾客了
                dispatch_semaphore_signal(customerReady);

                // 等待理发师叫到自己
                dispatch_semaphore_wait(barberReady, DISPATCH_TIME_FOREVER);
                NSLog(@"[顾客 %ld] 坐上理发椅，开始理发", (long)cid);
            } else {
                // 座位满：顾客离开
                NSLog(@"[顾客 %ld] 座位已满（%ld/%ld），离开", (long)cid, (long)waitingCount, (long)chairs);
                [seatMutex unlock];
            }
        });
    }
}

@end
