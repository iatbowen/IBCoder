// IBProducerConsumer.m
// 生产者-消费者问题
//
// 核心机制：
//   emptySlots（初值=缓冲区容量）：生产前 wait，消费后 signal，防止溢出
//   fullSlots （初值=0）          ：消费前 wait，生产后 signal，防止空读
//   NSLock 保护缓冲区数组和计数器，防止数据竞争
//
// 消费者退出策略（信号链）：
//   最后一个 item 被消费时，将 allConsumed 置为 YES，
//   并额外 signal(fullSlots) 一次，唤醒下一个阻塞消费者；
//   被唤醒的消费者发现 allConsumed=YES 后继续传递信号再退出，
//   直到所有消费者线程正常退出，不留阻塞线程。

#import "IBProducerConsumer.h"

@implementation IBProducerConsumer

+ (void)runDemoWithProducers:(NSInteger)producerCount
                  consumers:(NSInteger)consumerCount
                 bufferSize:(NSInteger)bufferSize
                  itemsEach:(NSInteger)itemsEach {

    if (producerCount <= 0 || consumerCount <= 0 || bufferSize <= 0 || itemsEach <= 0) {
        NSLog(@"[生产者-消费者] 参数无效：producers=%ld consumers=%ld bufferSize=%ld itemsEach=%ld",
              (long)producerCount, (long)consumerCount, (long)bufferSize, (long)itemsEach);
        return;
    }

    NSMutableArray<NSNumber *> *buffer = [NSMutableArray array];
    NSLock *bufferLock = [[NSLock alloc] init];

    // 空槽信号量：初值 = 缓冲区容量，生产前 wait，消费后 signal
    dispatch_semaphore_t emptySlots = dispatch_semaphore_create(bufferSize);
    // 满槽信号量：初值 = 0，消费前 wait，生产后 signal
    dispatch_semaphore_t fullSlots  = dispatch_semaphore_create(0);

    __block NSInteger producedTotal = 0;
    __block NSInteger consumedTotal = 0;
    __block BOOL allConsumed = NO;
    const NSInteger totalItems = producerCount * itemsEach;

    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // ── 生产者线程 ──
    for (NSInteger p = 0; p < producerCount; p++) {
        NSInteger producerID = p;
        dispatch_async(q, ^{
            for (NSInteger i = 0; i < itemsEach; i++) {
                // 等待空槽（缓冲区已满则阻塞）
                dispatch_semaphore_wait(emptySlots, DISPATCH_TIME_FOREVER);

                [bufferLock lock];
                NSInteger item = ++producedTotal;
                [buffer addObject:@(item)];
                NSLog(@"[生产者 %ld] 生产 item=%-3ld  缓冲区=%ld/%ld",
                      (long)producerID, (long)item, (long)buffer.count, (long)bufferSize);
                [bufferLock unlock];

                dispatch_semaphore_signal(fullSlots);      // 通知消费者有数据了
                [NSThread sleepForTimeInterval:0.05];      // 模拟生产耗时
            }
        });
    }

    // ── 消费者线程 ──
    for (NSInteger c = 0; c < consumerCount; c++) {
        NSInteger consumerID = c;
        dispatch_async(q, ^{
            while (YES) {
                // 等待数据（缓冲区为空则阻塞）
                dispatch_semaphore_wait(fullSlots, DISPATCH_TIME_FOREVER);

                [bufferLock lock];

                // 信号链退出：发现 allConsumed 则将信号传给下一个消费者后退出
                if (allConsumed) {
                    [bufferLock unlock];
                    dispatch_semaphore_signal(fullSlots);  // 唤醒下一个阻塞消费者
                    break;
                }

                NSNumber *item = buffer.firstObject;
                if (item) [buffer removeObjectAtIndex:0];
                NSInteger consumed = ++consumedTotal;
                BOOL done = (consumed >= totalItems);
                if (done) allConsumed = YES;

                NSLog(@"[消费者 %ld] 消费 item=%-3@  已消费=%ld/%ld",
                      (long)consumerID, item, (long)consumed, (long)totalItems);
                [bufferLock unlock];

                dispatch_semaphore_signal(emptySlots);     // 空出一个槽位

                if (done) {
                    // 触发信号链，唤醒其余阻塞消费者
                    dispatch_semaphore_signal(fullSlots);
                    break;
                }

                [NSThread sleepForTimeInterval:0.08];      // 模拟消费耗时
            }
            NSLog(@"[消费者 %ld] 退出", (long)consumerID);
        });
    }
}

@end
