// IBDiningPhilosophers.h
// 哲学家就餐问题（Dining Philosophers）
//
// 死锁根因：每个哲学家同时拿起左叉，等右叉 → 循环等待
//
// 解法：资源有序分配（Ordered Resource Allocation）
//   规定每位哲学家先拿编号较小的叉子，再拿编号较大的叉子
//   打破"循环等待"条件，从根本上消除死锁

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBDiningPhilosophers : NSObject

/// 启动 N 个哲学家的就餐演示（建议 N = 5）
+ (void)runDemoWithPhilosophers:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
