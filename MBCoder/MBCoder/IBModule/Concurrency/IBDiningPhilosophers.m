// IBDiningPhilosophers.m
// 哲学家就餐问题
//
// 每把叉子对应一把 NSLock
// 哲学家 i 的左叉 = fork[i]，右叉 = fork[(i+1) % N]
//
// 资源有序分配规则：
//   先锁 min(左叉, 右叉)，再锁 max(左叉, 右叉)
//   → 所有哲学家的加锁顺序统一，不会形成循环等待

#import "IBDiningPhilosophers.h"

@implementation IBDiningPhilosophers

+ (void)runDemoWithPhilosophers:(NSInteger)N {
    NSLog(@"\n=== 哲学家就餐（资源有序分配，N=%ld）===", (long)N);

    // 初始化 N 把叉子（每把叉子对应一把锁）
    NSMutableArray<NSLock *> *forks = [NSMutableArray arrayWithCapacity:N];
    for (NSInteger i = 0; i < N; i++) {
        NSLock *lock = [[NSLock alloc] init];
        lock.name = [NSString stringWithFormat:@"Fork-%ld", (long)i];
        [forks addObject:lock];
    }

    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    for (NSInteger i = 0; i < N; i++) {
        NSInteger pid = i;
        dispatch_async(q, ^{
            for (NSInteger round = 0; round < 3; round++) {   // 每位哲学家就餐 3 次

                // ── 思考 ──
                NSLog(@"[哲学家 %ld] 思考中...", (long)pid);
                [NSThread sleepForTimeInterval:arc4random_uniform(100) / 1000.0];

                // ── 拿叉子（有序加锁，防死锁）──
                NSInteger left  = pid;
                NSInteger right = (pid + 1) % N;
                NSInteger first  = MIN(left, right);
                NSInteger second = MAX(left, right);

                [forks[first] lock];
                NSLog(@"[哲学家 %ld] 拿起叉子 %ld", (long)pid, (long)first);
                [NSThread sleepForTimeInterval:0.01];         // 模拟拿第二把叉前的短暂间隔
                [forks[second] lock];
                NSLog(@"[哲学家 %ld] 拿起叉子 %ld，开始就餐", (long)pid, (long)second);

                // ── 就餐 ──
                [NSThread sleepForTimeInterval:arc4random_uniform(150) / 1000.0];
                NSLog(@"[哲学家 %ld] 就餐完毕，放下叉子", (long)pid);

                // ── 放叉子（逆序释放，与加锁顺序无关，但对称更清晰）──
                [forks[second] unlock];
                [forks[first]  unlock];
            }
            NSLog(@"[哲学家 %ld] 结束", (long)pid);
        });
    }
}

@end
