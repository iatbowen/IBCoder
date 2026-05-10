// IBReadersWriters.m
// 读者-写者问题

#import "IBReadersWriters.h"
#import <pthread.h>

// ─────────────────────────────────────────────
// 方案 A：dispatch_barrier_async
//   使用自定义并发队列：
//     读 → dispatch_async（可并发，多读者同时执行）
//     写 → dispatch_barrier_async（独占，写时等待所有在途读写完成）
// ─────────────────────────────────────────────

@implementation IBReadersWriters

+ (void)runDemoBarrier {
    NSLog(@"\n=== 读者-写者 方案A: dispatch_barrier ===");

    dispatch_queue_t queue = dispatch_queue_create("com.ib.rw.barrier", DISPATCH_QUEUE_CONCURRENT);
    __block NSInteger sharedData = 0;

    // 3 个读者并发读
    for (NSInteger r = 0; r < 3; r++) {
        NSInteger rid = r;
        dispatch_async(queue, ^{
            NSLog(@"[读者 %ld] 读取 data=%ld（可与其他读者并发）", (long)rid, (long)sharedData);
            [NSThread sleepForTimeInterval:0.1];
        });
    }

    // 写者：barrier 保证此时无任何读/写在执行
    dispatch_barrier_async(queue, ^{
        sharedData = 100;
        NSLog(@"[写者  ] 写入 data=%ld（独占）", (long)sharedData);
    });

    // barrier 完成后才会执行的读操作
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
//
//   使用堆分配避免 static 多次调用时重复 init 的问题
// ─────────────────────────────────────────────

+ (void)runDemoPthreadRWLock {
    NSLog(@"\n=== 读者-写者 方案B: pthread_rwlock ===");

    // 堆分配：保证每次调用使用独立的锁实例
    pthread_rwlock_t *rwlock = malloc(sizeof(pthread_rwlock_t));
    pthread_rwlock_init(rwlock, NULL);

    __block NSInteger sharedData = 0;
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_group_t group = dispatch_group_create();

    // 3 个读者
    for (NSInteger r = 0; r < 3; r++) {
        NSInteger rid = r;
        dispatch_group_async(group, q, ^{
            pthread_rwlock_rdlock(rwlock);          // 加读锁（与其他读者共享）
            NSLog(@"[读者 %ld] 读取 data=%ld", (long)rid, (long)sharedData);
            [NSThread sleepForTimeInterval:0.05];
            pthread_rwlock_unlock(rwlock);
        });
    }

    // 1 个写者（稍后到，演示等待读者释放后独占）
    dispatch_group_async(group, q, ^{
        [NSThread sleepForTimeInterval:0.02];      // 确保读者先启动
        pthread_rwlock_wrlock(rwlock);             // 加写锁（等所有读者释放）
        sharedData = 200;
        NSLog(@"[写者  ] 写入 data=%ld（独占）", (long)sharedData);
        pthread_rwlock_unlock(rwlock);
    });

    // 所有操作完成后清理资源
    dispatch_group_notify(group, q, ^{
        pthread_rwlock_rdlock(rwlock);
        NSLog(@"[读者 X] 写后读 data=%ld", (long)sharedData);
        pthread_rwlock_unlock(rwlock);

        pthread_rwlock_destroy(rwlock);
        free(rwlock);
        NSLog(@"[rwlock] 资源释放完毕");
    });
}

@end
