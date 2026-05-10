// IBSleepingBarberCV.m
// 唤醒-等待经典模型 — 理发师问题（NSCondition 条件变量方案）
//
// waitingQueue：等待理发的顾客队列（先到先服务）
// condition   ：协调理发师与顾客之间的唤醒/等待
//
// 流程：
//   顾客到来 → 队列未满则入队 + condition.signal 唤醒理发师
//            → 队列已满则直接离开
//   理发师循环 → condition.wait（队列空时休眠）
//              → 取出队首顾客 → 理发 → 继续循环

#import "IBSleepingBarberCV.h"

@implementation IBSleepingBarberCV

+ (void)runDemoWithChairs:(NSInteger)chairs customers:(NSInteger)customers {
    NSLog(@"\n=== 理发师问题（NSCondition 方案，seats=%ld，customers=%ld）===",
          (long)chairs, (long)customers);

    NSCondition *condition = [[NSCondition alloc] init];
    NSMutableArray<NSNumber *> *waitingQueue = [NSMutableArray array];
    __block BOOL shopOpen = YES;

    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // ── 理发师线程 ──
    dispatch_async(q, ^{
        while (YES) {
            [condition lock];

            // 队列为空时休眠（等待顾客到来）
            while (waitingQueue.count == 0 && shopOpen) {
                NSLog(@"[理发师] 无客，休眠等待...");
                [condition wait];
            }

            // 营业结束且队列清空 → 退出
            if (!shopOpen && waitingQueue.count == 0) {
                [condition unlock];
                break;
            }

            // 取出队首顾客
            NSInteger cid = [waitingQueue.firstObject integerValue];
            [waitingQueue removeObjectAtIndex:0];
            NSLog(@"[理发师] 叫号顾客 %ld，剩余等待 %ld 人", (long)cid, (long)waitingQueue.count);
            [condition unlock];

            // 理发（在锁外执行，不阻塞其他顾客入队）
            [NSThread sleepForTimeInterval:0.2];
            NSLog(@"[理发师] 顾客 %ld 理发完毕", (long)cid);
        }
        NSLog(@"[理发师] 今日结束");
    });

    // ── 顾客线程（依次到来）──
    for (NSInteger i = 0; i < customers; i++) {
        NSInteger cid = i;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.07 * NSEC_PER_SEC)), q, ^{
            [condition lock];
            if ((NSInteger)waitingQueue.count < chairs) {
                [waitingQueue addObject:@(cid)];
                NSLog(@"[顾客 %ld] 入队等待（队列 %ld/%ld）", (long)cid, (long)waitingQueue.count, (long)chairs);
                // 唤醒理发师（如果正在休眠）
                [condition signal];
            } else {
                NSLog(@"[顾客 %ld] 队列已满（%ld/%ld），离开", (long)cid, (long)waitingQueue.count, (long)chairs);
            }
            [condition unlock];
        });
    }

    // 所有顾客到来后关闭营业，唤醒理发师让其退出
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(customers * 0.07 * NSEC_PER_SEC + 0.5 * NSEC_PER_SEC)), q, ^{
        [condition lock];
        shopOpen = NO;
        [condition signal];
        [condition unlock];
    });
}

@end
