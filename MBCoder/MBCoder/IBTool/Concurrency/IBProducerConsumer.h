// IBProducerConsumer.h
// 生产者-消费者问题
// 方案：空槽信号量 + 满槽信号量 控制节奏，NSLock 保护共享缓冲区

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 生产者-消费者演示
/// 缓冲区容量固定，生产者写满后阻塞，消费者读空后阻塞
@interface IBProducerConsumer : NSObject

/// producerCount：生产者数量
/// consumerCount：消费者数量
/// bufferSize   ：缓冲区最大容量
/// itemsEach    ：每个生产者生产的 item 数
+ (void)runDemoWithProducers:(NSInteger)producerCount
                  consumers:(NSInteger)consumerCount
                 bufferSize:(NSInteger)bufferSize
                  itemsEach:(NSInteger)itemsEach;

@end

NS_ASSUME_NONNULL_END
