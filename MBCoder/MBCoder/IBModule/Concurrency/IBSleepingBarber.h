// IBSleepingBarber.h
// 理发师问题（Sleeping Barber）
//
// 方案 A：信号量 + 互斥锁（经典 Dijkstra 方案）
//   waitingSeats：计数信号量，初值 = 等待座位数
//   barberReady ：二值信号量，理发师准备好时 signal
//   customerReady：二值信号量，顾客坐下时 signal
//   mutex：保护 waitingCount 变量
//
// 方案 B：NSCondition（条件变量方案）
//   见 IBSleepingBarberCV.h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBSleepingBarber : NSObject

/// 启动演示：chairs = 等待座位数，customers = 顾客总数
+ (void)runDemoWithChairs:(NSInteger)chairs customers:(NSInteger)customers;

@end

NS_ASSUME_NONNULL_END
