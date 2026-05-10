// IBProducerConsumer.m
// 生产者-消费者问题
//
// 核心机制：
//   emptySlots（初值=缓冲区容量）：生产前 wait，表示"还有空位可写"
//   fullSlots （初值=0）          ：消费前 wait，表示"还有数据可读"
//   生产/消费后互相 signal，两个信号量合力保证不溢出、不空读
//   NSLock 保护缓冲区数组的读写，防止并发访问产生数据竞争

#import "IBProducerConsumer.h"

@implementation IBProducerConsumer

+ (void)runDemoWithProducers:(NSInteger)producerCount
                  consumers:(NSInteger)consumerCount
                 bufferSize:(NSInteger)bufferSize {

    NSMutableArray<NSNumber *> *buffer = [NSMutableArray array];
    NSLock *bufferLock = [[NSLock alloc] init];

    // 空槽信号量：初值 = 缓冲区容量，生产前 wait，消费后 signal
    dispatch_semaphore_t emptySlots = dispatch_semaphore_create(bufferSize);
    // 满槽信号量：初值 = 0，消费前 wait，生产后 signal
    dispatch_semaphore_t fullSlots  = dispatch_semaphore_create(0);

    __block NSInteger producedTotal  = 0;
    __block NSInteger consumedTotal  = 0;
    const NSInteger itemsPerProducer = 5;

    // --- 生产者线程 ---
    for (NSInteger p = 0; p < producerCount; p++) {
        NSInteger producerID = p;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (NSInteger i = 0; i < itemsPerProducer; i++) {
                // 等待空槽（缓冲区已满则阻塞）
                dispatch_semaphore_wait(emptySlots, DISPATCH_TIME_FOREVER);

                [bufferLock lock];
                NSInteger item = ++producedTotal;
                [buffer addObject:@(item)];
                NSLog(@"[生产者 %ld] 生产 item=%ld  缓冲区大小=%ld",
                      (long)producerID, (long)item, (long)buffer.count);
                [bufferLock unlock];

                // 通知消费者：缓冲区多了一个数据
                dispatch_semaphore_signal(fullSlots);

                // 模拟生产耗时
                [NSThread sleepForTimeInterval:0.05];
            }
        });
    }

    // --- 消费者线程 ---
    NSInteger totalItems = producerCount * itemsPerProducer;
    for (NSInteger c = 0; c < consumerCount; c++) {
        NSInteger consumerID = c;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (YES) {
                // 等待满槽（缓冲区为空则阻塞）
                dispatch_semaphore_wait(fullSlots, DISPATCH_TIME_FOREVER);

                [bufferLock lock];
                NSNumber *item = buffer.firstObject;
                if (item) [buffer removeObjectAtIndex:0];
                NSInteger consumed = ++consumedTotal;
                NSLog(@"[消费者 %ld] 消费 item=%@  已消费=%ld",
                      (long)consumerID, item, (long)consumed);
                BOOL done = (consumed >= totalItems);
                [bufferLock unlock];

                // 通知生产者：空出了一个槽位
                dispatch_semaphore_signal(emptySlots);

                if (done) break;

                // 模拟消费耗时
                [NSThread sleepForTimeInterval:0.08];
            }
        });
    }
}

@end
