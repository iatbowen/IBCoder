// IBReadersWriters.h
// 读者-写者问题
//
// 方案 A：dispatch_barrier_async（推荐 iOS 方案）
//   读操作 dispatch_async  → 多个读者并发执行
//   写操作 dispatch_barrier_async → 独占队列，写时无读
//
// 方案 B：pthread_rwlock_t（POSIX 底层方案）
//   pthread_rwlock_rdlock / pthread_rwlock_wrlock

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBReadersWriters : NSObject

/// 方案 A：dispatch_barrier_async 演示
+ (void)runDemoBarrier;

/// 方案 B：pthread_rwlock_t 演示
+ (void)runDemoPthreadRWLock;

@end

NS_ASSUME_NONNULL_END
