//
//  IBController4.m
//  IBCoder1
//
//  Created by Bowen on 2018/4/26.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController4.h"
#import <objc/runtime.h>

#ifndef weakify
#if __has_feature(objc_arc)
#define weakify(object) __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) __block __typeof__(object) block##_##object = object;
#endif
#endif

#ifndef strongify
#if __has_feature(objc_arc)
#define strongify(object) __typeof__(object) object = weak##_##object; if (!object) return;
#else
#define strongify(object) __typeof__(object) object = block##_##object; if (!object) return;
#endif
#endif


/*

 ============================================================
 Block 原理与实践 面试题总结
 ============================================================


 ============================================================
 一、Block 的本质
 ============================================================

 Block 是一个 OC 对象，继承链：
 __NSMallocBlock__  → __NSMallocBlock  → NSBlock → NSObject（堆 Block）
 __NSStackBlock__   → __NSStackBlock   → NSBlock → NSObject（栈 Block）
 __NSGlobalBlock__  → __NSGlobalBlock  → NSBlock → NSObject（全局 Block）

 底层结构（Block_layout）：
 struct Block_layout {
     void *isa;             // 指向所在内存区域的类（Stack/Malloc/Global）
     int flags;             // 按位标记附加信息（引用计数、是否有 copy/dispose 等）
     int reserved;          // 保留字段
     void (*invoke)(void *, ...); // 函数指针，指向 block 代码实现
     struct Block_descriptor *descriptor; // 描述信息（大小、copy/dispose 函数）
     // Captured variables...
 };

 Block = 函数指针（invoke）+ 捕获变量的结构体，兼具"回调"和"闭包"两种特性。
 回调 (Callback)：调用时机
 闭包 (Closure)：捕获环境

 ============================================================
 二、Block 三种类型与存储位置
 ============================================================

 __NSGlobalBlock__（全局区/静态区）
   条件：没有捕获任何自动变量（局部变量）
   包括：无捕获 / 只捕获全局变量 / 只捕获静态变量（static）
   特点：生命周期与 App 相同，不需要 copy/dispose

 __NSStackBlock__（栈区）
   条件：捕获了自动变量，且没有被强指针引用（无 copy 操作）
   MRC：有外部变量即为栈 Block
   ARC：被 weak 修饰或仅作为临时变量（不赋给 strong/copy 属性）
   特点：随栈帧销毁，使用前需 copy 到堆

 __NSMallocBlock__（堆区）
   条件：栈 Block 被 copy 到堆
   ARC 下触发：被 strong/copy 属性持有 / 作为函数返回值 / 被强变量引用
   特点：引用计数管理，最常见

 【内存分布规律】
 无捕获外部变量                  → 全局区
 捕获全局变量/全局静态/局部静态    → 全局区（变量本身不在栈上）
 捕获普通局部变量 + strong/copy持有 → 堆区（ARC）
 捕获普通局部变量 + weak 修饰     → 栈区（ARC）


 ============================================================
 三、变量捕获规则
 ============================================================

 局部变量（auto，默认）
   捕获方式：值拷贝（capture by value）
   Block 内获得的是创建时的快照，修改不影响外部，外部修改也不影响 Block 内部
   无法在 Block 内部直接修改（编译错误），需用 __block 修饰

 静态局部变量（static）
   捕获方式：指针拷贝（capture by reference）
   Block 捕获变量地址，可在 Block 内读写，始终获取最新值
   不需要 __block 修饰

 全局变量 / 全局静态变量
   不需要捕获，Block 直接访问（作用域全局可见）

 对象类型（OC 对象，ARC）
   捕获方式：strong 引用（等同于 retain）
   Block 会对被捕获的对象持有强引用，这是循环引用的根源

 __block 修饰的变量
   捕获方式：捕获结构体指针（__Block_byref_xxx）
   通过 __forwarding 指针间接访问，支持在 Block 内读写
   ARC：赋值时触发 copy，__block 结构体从栈拷贝到堆
   MRC：只有显式 [block copy] 时才拷贝到堆


 ============================================================
 四、__block 原理与 __forwarding 指针
 ============================================================

 __block 变量被编译器转换为结构体：
 struct __Block_byref_i_0 {
     void *__isa;
     __Block_byref_i_0 *__forwarding; // 关键：指向"有效"位置的自身
     int __flags;
     int __size;
     int i;                           // 实际变量值
 };

 __forwarding 的设计目的：
 栈上的 __block 结构体被 copy 到堆后，栈上结构体的 __forwarding 指向堆上的结构体，
 堆上结构体的 __forwarding 指向自己。
 无论访问栈上还是堆上的 __block 变量，统一通过 (var->__forwarding->val) 访问，
 始终操作的是堆上的最新值，避免栈/堆双份数据不一致。


 ============================================================
 五、Block copy 触发时机（4 种）
 ============================================================

 1. 手动调用 [block copy]
 2. Block 作为函数返回值
 3. Block 被强引用（strong/copy 属性持有，或赋给 __strong 变量）
 4. 调用系统 API 时参数中含有 usingBlock 的方法（如 enumerateObjectsUsingBlock:）
 5. GCD 函数

 ARC 下编译器会自动在适当时机插入 copy，大多数情况无需手动调用。
 MRC 下必须手动 [block copy]，否则栈 Block 随作用域销毁后访问会崩溃。


 ============================================================
 六、Block 与循环引用
 ============================================================

 【循环引用产生条件】
 对象 A 强持有 Block，Block 内部捕获了对象 A 的强引用
 → A → Block → A，形成保留环，双方引用计数无法归零，内存泄漏。

 【典型场景】
 self.block = ^{ NSLog(@"%@", self); };  // self 持有 block，block 捕获 self → 循环

 【解决方案一：__weak + __strong（推荐）】
 __weak typeof(self) weakSelf = self;
 self.block = ^{
     __strong typeof(weakSelf) strongSelf = weakSelf; // block 内临时强引用
     if (!strongSelf) return;
     NSLog(@"%@", strongSelf);
 };

 为什么需要 __strong：
 - __weak 确保不持有 self，打破循环引用
 - __strong 确保 block 执行期间 self 不被释放（防止执行到一半 self 变 nil 导致逻辑异常）
 - strongSelf 是 block 内的局部变量，block 执行完毕即释放，不会造成新的循环引用

 【两种边界情况】
 ① block 执行前 self 已释放
    weakSelf 为 nil → strongSelf = nil → if 判断直接 return → 安全
 ② block 执行过程中 self 被释放
    strongSelf 临时持有 → 对象存活直到 block 结束 → strongSelf 出作用域释放 → 对象销毁 → 安全

 【解决方案二：事后弥补（在 block 内置空引用）】
 [self.student addBlock:^{
     NSLog(@"%@", self);
     self.student.arr = nil;  // 手动打断循环
 }];
 缺点：需要在 block 内手动管理，容易遗漏。

 【weakify / strongify 宏解析（见文件顶部宏定义）】
 weakify(self)：
   ARC: __weak __typeof__(self) weak_self = self;
   展开为一个局部弱引用变量 weak_self

 strongify(self)：
   ARC: __typeof__(self) self = weak_self; if (!self) return;
   展开为局部强引用变量 self（遮蔽外部 self），并在 self 为 nil 时提前 return

 注意：strongify 中的 if (!self) return 只能防范 void 返回值的 block，
 有返回值的 block 中使用需自行处理。


 ============================================================
 七、属性修饰 Block 的选择
 ============================================================

 ARC 下：
 copy/strong：均将 block 持有在堆上（效果相同），推荐用 copy 以明确语义
 assign     ：持有栈 block 地址，作用域结束后指针悬空 → 野指针崩溃（不推荐）
 weak       ：弱引用，不会 copy，block 可能随时被释放（不推荐用于持久持有）

 MRC 下：
 copy/strong：copy 到堆，安全
 assign/retain：assign 持有栈 block 会崩溃；retain 不会 copy，同 assign 危险


 ============================================================
 八、常见面试问答
 ============================================================

 Q：Block 和函数指针的区别？
 A：函数指针只是指向一段代码，无法捕获上下文变量。
    Block 是一个对象（结构体），除函数指针外还包含捕获的变量快照（闭包），
    可以在定义时"封闭"所需的上下文，延迟或跨作用域执行。

 Q：为什么 Block 内部修改外部 auto 变量需要 __block？
 A：auto 变量捕获是值拷贝，Block 持有的是创建时的副本，与外部变量已经是两个独立存储。
    __block 将变量包装成 __Block_byref 结构体并捕获其指针，通过 __forwarding 间接访问，
    Block 和外部代码操作的始终是同一份值，因此可以相互修改。

 Q：__block 修饰的对象在 ARC 下会有什么额外行为？
 A：ARC 下，__block 修饰对象时，Block 被 copy 到堆后，
    __Block_byref 结构体会对该对象进行强引用（retain），
    直到 Block 销毁时才 release。
    MRC 下，__block 不会 retain 对象，只是指针的复制。

 Q：下面代码会不会循环引用？
    [self.student addBlock:^{ NSLog(@"%@", self); }];
 A：取决于 student 是否将 block 存起来，且 student 又被 self 持有。
    如果 self → student → block → self，形成循环引用；
    如果 block 只是被调用执行后不被持有（一次性），则不会循环引用。

 Q：dispatch_after 的 block 需要用 weakSelf 吗？
 A：dispatch_after 的 block 被 GCD 持有，不被 self 持有，不形成循环引用，
    理论上不需要 weakSelf。但如果希望 block 执行时若 self 已释放就跳过执行，
    则可以用 weakSelf + strongSelf 模式做安全判断。

 */

@implementation Student

+ (instancetype)shareInstance {
    static Student *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[Student alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _arr = @[].mutableCopy;
    }
    return self;
}

- (void)addBlock:(void (^)(void))block {
    [self.arr addObject:block];
    block();
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
}

- (NSString *)description
{
    return @"123456";
}


+ (void)performBlock:(dispatch_block_t)block
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();
    });
}

@end


typedef void (^Block)(void);

@interface IBController4 ()

@property (nonatomic, assign) Block block;
@property (nonatomic, strong) Student *student;
@property (nonatomic, copy) dispatch_block_t block1;
@property (nonatomic, copy) dispatch_block_t block2;
@property (nonatomic, copy) dispatch_block_t block3;

@end

@implementation IBController4

static int count = 0;

// Ref: https://www.jianshu.com/p/d96d27819679
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.student = [Student shareInstance];
    weakify(self)
    self.block1 = ^{
        strongify(self)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"执行中 strongify %@", self);
        });
    };
    self.block2 = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"执行中 weakify %@", weak_self);
        });
    };
    
    self.block3 = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self)
            NSLog(@"当前对象调用 没执行 strongify %@", self);
        });
    };
    [Student shareInstance].pblock = ^{
        strongify(self)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"其他对象调用 没执行 strongify %@", self);
        });
    };
    
    [Student performBlock:^{
        NSLog(@"bowen %d", count);
        count++;
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self test1];
//    [self test2];
//    [self test3];
//    [self testBlock];
//    [self testWeak];
//    [self test4];
//    [self test5];
    [self test6];
}

/**
 test6 陷阱：__block key 被 Block 赋值时从栈 copy 到堆，&key 地址发生变化。
 第一次 setAssociatedObject 用的是栈地址，Block 内用的是堆地址——两个不同的 key。
 结果：m = nil（堆地址无关联值），n = @2（Block 内写入堆地址对应的关联值）。
 */
- (void)test6
{
    __block char key = 0;  // 初始在栈区
    objc_setAssociatedObject(self, &key, @1, OBJC_ASSOCIATION_ASSIGN);
    
    // Block 赋值触发 copy：__block key 迁移到堆，&key 地址变更
    void (^block)(void) = ^{
        objc_setAssociatedObject(self, &key, @2, OBJC_ASSOCIATION_ASSIGN); // 堆地址
    };
    
    id m = objc_getAssociatedObject(self, &key); // 此时 &key 已是堆地址，找不到之前设的 @1 → nil
    block();
    id n = objc_getAssociatedObject(self, &key);
    NSLog(@"m= %@ n=%@", m, n); // nil 和 2
}

/// test5：obj = nil 后再调 block，strongobj = nil（weakobj 已归零），但 &strongobj（局部指针地址）仍存在。
- (void)test5
{
    NSObject *obj = [[NSObject alloc] init];
    NSLog(@"%@--%p", obj, &obj);
    __weak typeof(obj)weakobj = obj;
    void(^block)(void) = ^{
        __strong typeof(weakobj) strongobj = weakobj;
        NSLog(@"%@--%p",strongobj, &strongobj);
    };
    block();
    obj = nil;
    block();
}


/// test4：Block 强引用 obj，obj = nil 后对象未释放，两次调用均有值。
- (void)test4
{
    NSObject *obj = [[NSObject alloc] init];
    NSLog(@"%@--%p", obj, &obj);
    void(^block)(void) = ^{
        NSLog(@"%@--%p",obj, &obj);
    };
    block();
    obj = nil;
    block();
}

- (void)testWeak
{
    /*
     block1：weakSelf + strongSelf，block 执行前 self 若已释放则 strongSelf = nil 直接 return，
            执行中 strongSelf 临时持有保证不中途变 nil，执行完毕 strongSelf 销毁，不造成循环引用。
     block2：只用 weakSelf，block 执行过程中 self 可能随时变 nil。
     block3/pblock：strongSelf 在嵌套 dispatch_after 内，外层 block 退出后 strongSelf 已销毁，
                   嵌套 block 内的 self 重新变为 weak，若此时 self 已释放则为 nil。
     */
    self.block1(); // block走完
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.block3();
    });
    
    self.block2(); // block走一半空了
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [Student shareInstance].pblock();
    });
}

/**
 test3：两种设置自定义队列 QoS/优先级的方式：
 方式一 dispatch_set_target_queue：将自定义队列目标设为全局队列，继承其 QoS
 方式二 dispatch_queue_attr_make_with_qos_class：创建时直接指定 QoS 等级
 A、B、C 执行顺序由队列优先级和系统调度决定，非确定性。
 */
- (void)test3 {
    
    //方法1
    dispatch_queue_t queue = dispatch_queue_create("abc123", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_set_target_queue(queue, global);
    
    //方法2
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, DISPATCH_QUEUE_PRIORITY_HIGH);
    dispatch_queue_t queueAttr = dispatch_queue_create("com.starming.gcddemo.qosqueue", attr);
    
    dispatch_async(queue, ^{
        NSLog(@"A");
    });
    dispatch_async(queueAttr, ^{
        NSLog(@"B");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"C");
    });
    sleep(3);
    NSLog(@"D");
}

/**
 如果参数block被Person对象引用就会产生循环引用，否则不会
 解决办法：事前避免，事后弥补，传值(置空一端引用，断开循环)
 */
- (void)test2 {
    //循环引用
//    [self.student addBlock:^{
//        NSLog(@"%s--%@",__func__,self);
//    }];
    
    __weak typeof(self) weakself = self;
    [[Student shareInstance] addBlock:^{
        __strong typeof(weakself) strongself = weakself;
        NSLog(@"%s--%@",__func__,strongself);
    }];
    
//    [self.student addBlock:^{
//        NSLog(@"%s--%@",__func__,self);
//        self.student.arr = nil;
//    }];
    
}



/**
 需要切换MRC(-fno-objc-arc)测试
 */
- (void)test1 {
    
    // __NSGlobalBlock__：无外部自动变量捕获，ARC/MRC 相同
    void (^block1)(void) = ^{
        NSLog(@"block1");
    };
    NSLog(@"%@",block1);
    
    // 捕获局部变量 i：ARC 有强引用 → __NSMallocBlock__；MRC → __NSStackBlock__
    int i = 10;
    void (^block2)(void) = ^{
        NSLog(@"block2 -- %d", i);
    };
    NSLog(@"%@",block2);
    
    // MRC：[block2 copy] → __NSMallocBlock__
    NSLog(@"%@", [block2 copy]);
    
    [self testBlock];
    sleep(1);
    
    // Block 属性修饰：MRC 用 copy（assign/retain 导致野指针），ARC 用 strong 或 copy 均可（assign 导致野指针）
    NSLog(@"%@",self.block);
    
}


/**
 Block不允许修改外部变量的值，这里所说的外部变量的值，指的是栈中指针的内存地址
 嵌套block使用self，__weak, __strong.自己测试没影响
 
 解析：strongSelf 只在 block 执行期间临时持有 self，执行完立即释放，不会造成循环引用。
 两种情况：
 ① block 执行前 self 已释放
 weakSelf → nil
 strongSelf = nil → block 直接 return
 ✅ 无任何问题
 
 ② block 执行中 self 被释放
 block 开始 → strongSelf 临时持有 self（暂时强引用）
 block 执行中 → 即使外部 self 释放，对象仍存活，保证 block 安全执行
 block 结束 → strongSelf 出作用域销毁 → self 释放 → block 释放
 ✅ 全部正常释放
 
 一句话总结
 weakSelf 防循环引用，strongSelf 防执行中途释放。 临时强引用只活在 block 内部，结束即销毁，所以安全且无循环。

 */
- (void)testBlock {
    int i = 5;
    int *a = &i;
    __block NSString *name = @"bowen";
    NSMutableString *nickname = @"ios".mutableCopy;
    static NSString *weakname = @"OC";
    __weak typeof(self) weakSelf = self;
    self.block = ^{
        __strong typeof(self) strongSelf = weakSelf;
        int b = 10;
        *a = b;
//        a = &b; //不允许
//        nickname = @"OC"; //不允许
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            name = @"b";
            weakname = @"Objective - C";
            [nickname appendString:@"swift"]; //允许
            NSLog(@"test -- %@%d", name,i);
            NSLog(@"弱引用%@---强引用%@", weakSelf, strongSelf);
        });
    };
    [self.student addBlock:self.block];
    NSLog(@"test -- %@ -- %li",self.block,CFGetRetainCount((__bridge CFTypeRef)(self.block)));
}

- (void)run {
    NSLog(@"%s", __func__);
}


- (void)dealloc {
    NSLog(@"%s",__func__);
}


/*
1、block数据结构体
struct Block_descriptor {
    unsigned long int reserved;
    unsigned long int size;
    void (*copy)(void *dst, void *src);
    void (*dispose)(void *);
};
struct Block_layout {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor *descriptor;
    // Imported variables.
};
// 结构体字段说明见文件头部注释"一、Block 的本质"和"四、__block 原理"。

2、NSConcreteGlobalBlock类型的block的实现
int main()
{
    ^{ printf("Hello, World!\n"); } ();
    return 0;
}

int main()
{
    (void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA) ();
    return 0;
}

struct __block_impl {
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};
struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0* Desc;
    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
        impl.isa = &_NSConcreteStackBlock;
        impl.Flags = flags;
        impl.FuncPtr = fp;
        Desc = desc;
    }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    printf("Hello, World!\n");
}
static struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0) };
// 解析：无捕获变量时 isa = &_NSConcreteStackBlock（clang），但最终优化为 _NSConcreteGlobalBlock。
// impl 字段等同于 invoke（函数指针），descriptor 记录大小及 copy/dispose 指针。

3、NSConcreteStackBlock类型的block的实现
int main() {
    int a = 100;
    void (^block2)(void) = ^{
        printf("%d\n", a);
    };
    block2();
    return 0;
}
int main()
{
    int a = 100;
    void (*block2)(void) = (void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, a);
    ((void (*)(__block_impl *))((__block_impl *)block2)->FuncPtr)((__block_impl *)block2);
    return 0;
}

struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0* Desc;
    int a;
    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _a, int flags=0) : a(_a) {
        impl.isa = &_NSConcreteStackBlock;
        impl.Flags = flags;
        impl.FuncPtr = fp;
        Desc = desc;
    }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    int a = __cself->a; // bound by copy
    printf("%d\n", a);
}
static struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};

// 解析：isa = _NSConcreteStackBlock，捕获的变量 a 作为字段加入结构体（值拷贝），
// Block 内通过 __cself->a 访问副本，修改不影响外部原变量。

4、Block中__block实现原理
int main()
{
    __block int i = 1024;
    void (^block1)(void) = ^{
        printf("%d\n", i);
        i = 1023;
    };
    block1();
    return 0;
}
int main()
{
    __attribute__((__blocks__(byref))) __Block_byref_i_0 i = {(void*)0,(__Block_byref_i_0 *)&i, 0, sizeof(__Block_byref_i_0), 1024};
    void (*block1)(void) = (void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_i_0 *)&i, 570425344);
    ((void (*)(__block_impl *))((__block_impl *)block1)->FuncPtr)((__block_impl *)block1);
    return 0;
}

struct __Block_byref_i_0 {
    void *__isa;
    __Block_byref_i_0 *__forwarding;
    int __flags;
    int __size;
    int i;
};
struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0* Desc;
    __Block_byref_i_0 *i; // by ref
    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_i_0 *_i, int flags=0) : i(_i->__forwarding) {
        impl.isa = &_NSConcreteStackBlock;
        impl.Flags = flags;
        impl.FuncPtr = fp;
        Desc = desc;
    }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    __Block_byref_i_0 *i = __cself->i; // bound by ref
    printf("%d\n", (i->__forwarding->i));
    (i->__forwarding->i) = 1023;
}
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->i, (void*)src->i,);}
static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->i,);}
static struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
    void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
    void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct _main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
// 解析：__block 变量包装为 __Block_byref 结构体，Block 捕获其指针（by ref）。
// descriptor 增加 copy/dispose 指针管理结构体引用计数。
// __forwarding：栈上副本指向堆上副本，堆上副本指向自己。
// 无论 Block 在栈/堆，始终通过 i->__forwarding->i 访问同一份数据。
*/

@end
