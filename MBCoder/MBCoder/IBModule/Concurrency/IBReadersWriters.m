// IBReadersWriters.m
// 读者-写者问题

#import "IBReadersWriters.h"
#import <pthread.h>

// ─────────────────────────────────────────────
// 方案 A：dispatch_barrier_async
//   使用自定义并发队列：
//     读 → dispatch_async（可并发）
//     写 → dispatch_barrier_async（独占，写时所有读/写都等待）
// ─────────────────────────────────────────────

@implementation IBReadersWriters

+ (void)runDemoBarrier {
    NSLog(@"\n=== 读者-写者 方案A: dispatch_barrier ===");

    dispatch_queue_t queue = dispatch_queue_create("com.ib.rw", DISPATCH_QUEUE_CONCURRENT);
    __block NSInteger sharedData = 0;

    // 3 个读者
    for (NSInteger r = 0; r < 3; r++) {
        NSInteger rid = r;
        dispatch_async(queue, ^{
            // 读操作：并发执行，多个读者同时读
            NSLog(@"[读者 %ld] 读取 data=%ld", (long)rid, (long)sharedData);
            [NSThread sleepForTimeInterval:0.1];
        });
    }

    // 1 个写者（barrier 保证写时独占）
    dispatch_barrier_async(queue, ^{
        sharedData = 100;
        NSLog(@"[写者  ] 写入 data=%ld（独占）", (long)sharedData);
    });

    // 再次读取（barrier 完成后才执行）
    for (NSInteger r = 0; r < 2; r++) {
        NSInteger rid = r;
        dispatch_async(queue, ^{
            NSLog(@"[读者 %ld] 写后读 data=%ld", (long)rid, (long)sharedData);
        });
    }
}

// ─────────────────────────────────────────────
// 方案 B：pthread_rwlock_t
//   rdlock：多个读者可同时持有
//   wrlock：写者独占，其余读写全部阻塞
// ─────────────────────────────────────────────

+ (void)runDemoPthreadRWLock {
    NSLog(@"\n=== 读者-写者 方案B: pthread_rwlock ===");

    static pthread_rwlock_t rwlock;
    pthread_rwlock_init(&rwlock, NULL);
    __block NSInteger sharedData = 0;

    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // 3 个读者
    for (NSInteger r = 0; r < 3; r++) {
        NSInteger rid = r;
        dispatch_async(q, ^{
            pthread_rwlock_rdlock(&rwlock);     // 加读锁（可与其他读者共享）
            NSLog(@"[读者 %ld] 读取 data=%ld", (long)rid, (long)sharedData);
            [NSThread sleepForTimeInterval:0.05];
            pthread_rwlock_unlock(&rwlock);
        });
    }

    // 1 个写者
    dispatch_async(q, ^{
        [NSThread sleepForTimeInterval:0.02];   // 稍等，让读者先启动
        pthread_rwlock_wrlock(&rwlock);         // 加写锁（独占，等读者全部释放后才能获得）
        sharedData = 200;
        NSLog(@"[写者  ] 写入 data=%ld（独占）", (long)sharedData);
        pthread_rwlock_unlock(&rwlock);
    });

    // 写后读
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), q, ^{
        pthread_rwlock_rdlock(&rwlock);
        NSLog(@"[读者 X] 写后读 data=%ld", (long)sharedData);
        pthread_rwlock_unlock(&rwlock);
        pthread_rwlock_destroy(&rwlock);
    });
}

@end
