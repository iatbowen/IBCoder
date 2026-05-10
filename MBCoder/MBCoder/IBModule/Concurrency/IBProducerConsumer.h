// IBProducerConsumer.h
// 生产者-消费者问题
// 方案：空槽信号量 + 满槽信号量 控制节奏，NSLock 保护共享缓冲区

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 生产者-消费者演示
/// 缓冲区容量固定，生产者写满后阻塞，消费者读空后阻塞
@interface IBProducerConsumer : NSObject

/// 启动演示：producerCount 个生产者，consumerCount 个消费者，bufferSize 缓冲区大小
+ (void)runDemoWithProducers:(NSInteger)producerCount
                  consumers:(NSInteger)consumerCount
                 bufferSize:(NSInteger)bufferSize;

@end

NS_ASSUME_NONNULL_END
