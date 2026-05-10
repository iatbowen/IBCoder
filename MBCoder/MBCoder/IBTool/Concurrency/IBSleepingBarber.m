// IBSleepingBarber.m
// 理发师问题 — 信号量 + 互斥锁方案
//
// 信号量语义：
//   customerReady（初值 0）：顾客入座后 signal，理发师 wait 后开剪
//   queueLock              ：保护等待队列和关店标记
//
// 修正要点：
//   原方案用单一 barberReady 信号量对应多个等待顾客，无法保证一对一唤醒。
//   正确做法：用顾客队列 + NSCondition，或为每个入座顾客分配独立信号量。
//   此处采用"每顾客独立信号量"方案：顾客入座时创建自己的 ready 信号量，
//   理发师从队列取出后，对该顾客的信号量执行 signal，精确唤醒对应顾客。

#import "IBSleepingBarber.h"

@implementation IBSleepingBarber

+ (void)runDemoWithChairs:(NSInteger)chairs customers:(NSInteger)customers {
    NSLog(@"\n=== 理发师问题（信号量方案，seats=%ld，customers=%ld）===",
          (long)chairs, (long)customers);

    if (chairs <= 0 || customers <= 0) {
        NSLog(@"[理发师问题] 参数无效：chairs=%ld customers=%ld", (long)chairs, (long)customers);
        return;
    }

    // 等待队列：存放每位顾客的 [customerID, 其专属 barberReady 信号量]
    NSMutableArray<NSDictionary<NSString *, id> *> *waitingQueue = [NSMutableArray array];
    NSLock *queueLock = [[NSLock alloc] init];
    __block BOOL allCustomersArrived = NO;

    // 有顾客入座时 signal，理发师 wait 后取队首
    dispatch_semaphore_t customerReady = dispatch_semaphore_create(0);

    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t arrivalGroup = dispatch_group_create();

    // ── 理发师线程 ──
    dispatch_async(q, ^{
        NSInteger served = 0;
        while (YES) {
            NSLog(@"[理发师] 等待顾客...");
            dispatch_semaphore_wait(customerReady, DISPATCH_TIME_FOREVER);

            // 从队列取出队首顾客及其专属信号量
            [queueLock lock];
            NSDictionary<NSString *, id> *entry = waitingQueue.firstObject;
            if (entry) [waitingQueue removeObjectAtIndex:0];
            BOOL shouldClose = (!entry && allCustomersArrived);
            NSInteger remaining = waitingQueue.count;
            [queueLock unlock];

            if (shouldClose) break;
            if (!entry) continue;

            NSInteger cid = [entry[@"id"] integerValue];
            dispatch_semaphore_t seat = entry[@"seat"];

            NSLog(@"[理发师] 叫号顾客 %ld，剩余等待 %ld 人", (long)cid, (long)remaining);

            // 精确唤醒该顾客（告知可坐上理发椅）
            dispatch_semaphore_signal(seat);

            // 理发
            [NSThread sleepForTimeInterval:0.2];
            NSLog(@"[理发师] 顾客 %ld 理发完毕", (long)cid);
            served++;
        }
        NSLog(@"[理发师] 今日结束，共服务 %ld 位顾客", (long)served);
    });

    // ── 顾客线程（依次到来）──
    for (NSInteger i = 0; i < customers; i++) {
        NSInteger cid = i;
        dispatch_group_enter(arrivalGroup);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.08 * NSEC_PER_SEC)), q, ^{
            dispatch_semaphore_t mySeat = nil;

            [queueLock lock];
            if ((NSInteger)waitingQueue.count < chairs) {
                // 为自己创建专属信号量，入队等待
                mySeat = dispatch_semaphore_create(0);
                [waitingQueue addObject:@{@"id": @(cid), @"seat": mySeat}];
                NSLog(@"[顾客 %ld] 入座等待（队列 %ld/%ld）",
                      (long)cid, (long)waitingQueue.count, (long)chairs);
                [queueLock unlock];

                // signal 必须在 group_leave 之前：确保理发师在收到关店通知前
                // 已经知道此顾客存在，否则单顾客场景下关店 signal 会抢先到达。
                dispatch_semaphore_signal(customerReady);   // 先通知理发师有人了
                dispatch_group_leave(arrivalGroup);         // 再标记"到店决策完成"
                dispatch_semaphore_wait(mySeat, DISPATCH_TIME_FOREVER); // 等理发师叫号
                NSLog(@"[顾客 %ld] 坐上理发椅，开始理发", (long)cid);
            } else {
                NSLog(@"[顾客 %ld] 座位已满（%ld/%ld），离开",
                      (long)cid, (long)waitingQueue.count, (long)chairs);
                [queueLock unlock];
                dispatch_group_leave(arrivalGroup);
            }
        });
    }

    // 所有顾客都完成“到店决策”后，通知理发师：队列清空时即可下班。
    dispatch_group_notify(arrivalGroup, q, ^{
        [queueLock lock];
        allCustomersArrived = YES;
        [queueLock unlock];

        dispatch_semaphore_signal(customerReady);
    });
}

@end
