// IBSleepingBarberCV.h
// 唤醒-等待经典模型 — 理发师问题（条件变量方案）
//
// 使用 NSCondition 实现等待/唤醒：
//   condition.wait   → 顾客等待（释放锁 + 挂起线程）
//   condition.signal → 理发师唤醒一位顾客
//
// 与信号量方案的区别：
//   信号量方案：每个顾客持有独立信号量，一对一唤醒
//   条件变量方案：顾客排队（NSMutableArray），理发师处理完 signal 唤醒下一位

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBSleepingBarberCV : NSObject

/// 启动演示：chairs = 等待座位数，customers = 顾客总数
+ (void)runDemoWithChairs:(NSInteger)chairs customers:(NSInteger)customers;

@end

NS_ASSUME_NONNULL_END
