//
//  IBController13.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/8.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController13.h"
#import <objc/runtime.h>
#import <objc/message.h>
/*
 一、isa指针问题
 isa：是一个Class类型的指针。
 当调用对象方法时，通过instance的isa找到class，然后调用对象方法的实现；如果没有，通过superclass找到父类的class，最后找到对象方法的实现进行调用
 当调用类方法时，通过class的isa找到meta-class，然后调用类方法的实现；如果没有，通过superclass找到父类的meta-class，最后找到类方法的实现进行调用
 注意的是:元类(metaClass)也是类，它也是对象。元类也有isa指针,它的isa指针最终指向的是一个根元类(root metaClass)。根元类的isa指针指向本身，这样形成了一个封闭的内循环。

 1、isa、superclass总结
 1）instance的isa指向class
 2）class的isa指向meta-class
 3）meta-class的isa指向基类的meta-class
 4）class的superclass指向父类的class，如果没有父类，superclass指针为nil
 5）meta-class的superclass指向父类的meta-class，基类的meta-class的superclass指向基类的class

 注意：从64bit开始，isa需要进行一次位运算（&ISA_MASK），才能计算出真实地址
 
 2、引用计数的存储
 在arm64架构之前，isa就是一个普通的指针，存储着Class、Meta-Class对象的内存地址
 从arm64架构开始，对isa进行了内存优化，变成了一个共用体（union）结构，还使用位域来存储更多的信息
 union isa_t {
    Class cls;
    uintptr_t bits;
    struct {
        uintptr_t nonpointer        : 1;  // 0=普通指针，存类/元类地址；1=优化位域，存引用计数等信息
        uintptr_t has_assoc         : 1;  // 是否设置过关联对象，没有则释放时更快
        uintptr_t has_cxx_dtor      : 1;  // 是否有 C++ 析构函数（.cxx_destruct），没有则释放更快
        uintptr_t shiftcls          : 44; // 存储 Class/Meta-Class 的内存地址（需 & ISA_MASK 取出）
        uintptr_t magic             : 6;  // 调试用，判断对象是否完成初始化
        uintptr_t weakly_referenced : 1;  // 是否有弱引用指向，没有则释放更快
        uintptr_t deallocating      : 1;  // 对象是否正在释放
        uintptr_t has_sidetable_rc  : 1;  // 引用计数是否溢出到 SideTable
        uintptr_t extra_rc          : 8;  // 引用计数 - 1（实际引用计数 = extra_rc + 1）
    };
 };
 
 在64bit中，引用计数可以直接存储在优化过的isa指针中，也可能存储在SideTable类中
 struct SideTable {
    spinlock_t slock;
    RefcountMap refcnts; refcnts是一个存放着对象引用计数的散列表
    weak_table_t weak_table; weak_table 弱引用哈希表
 }
 
 二、Runtime实现的机制是什么
 Objective-C的Runtime是一个运行时库（libobjc），它在程序运行时对类、对象、方法等信息进行管理。核心思想就是把很多编译期间确定的行为，转移到运行期间实现。比如：
 - 方法调用是通过查找方法列表，再通过IMP指针跳转。
 - 对象的声明、属性等在运行时都以数据结构存在。
 - 在运行时得到类的属性、方法、协议等信息。
 - 可以动态添加类、方法、属性、交换方法实现等。
 本质： Runtime是一套C语言的API，是Objective-C面向对象特性的基础。
 
 三、什么是 Method Swizzle（黑魔法），什么情况下会使用？
 Method Swizzling 是利用 Runtime 动态交换两个方法的 IMP（实现） 的技术
 核心思想：Method Swizzling 本质是 AOP（面向切面编程） 思想的体现，在不修改原有代码的情况下，动态插入新的逻辑。
 常用方法：
            method_exchangeImplementations     class_replaceMethod    method_setImplementation
操作         互换两个方法IMP                      替换指定SEL的IMP         直接设置Method的IMP
参数         两个 Method                         Class + SEL + 新IMP    Method + 新IMP
旧IMP        自动保留（互换）                      返回旧IMP               返回旧IMP
类没有该方法   ❌ 不适用                           ✅ 自动添加             ❌ 不适用
常用场景     标准 Swizzling                       动态添加/替换方法        底层直接修改
 
 四、_objc_msgForward 函数是做什么的，直接调用它将会发生什么？

 是什么：
 _objc_msgForward 是一个 IMP（函数指针），作用是触发消息转发流程。
 正常情况下，当对象找不到方法实现时，Runtime 会自动把 IMP 替换为 _objc_msgForward，进入转发流程：
   forwardingTargetForSelector: -> methodSignatureForSelector: -> forwardInvocation:

 直接调用会怎样：
 直接调用等于手动跳过消息查找，强制进入转发流程。
 如果没有实现转发方法，最终会调用 doesNotRecognizeSelector: 抛出异常崩溃。
 实际应用：JSPatch / Aspects 等框架用它来拦截方法，把调用统一转发到自定义处理逻辑。

 _objc_msgForward vs _objc_msgForward_stret（了解即可）：
 - 返回普通值（int / 指针）：用 _objc_msgForward
 - 返回大结构体（32位架构）：需用 _objc_msgForward_stret，否则 crash
   原因：大结构体返回时寄存器布局不同，self/_cmd 位置发生偏移，普通版本读错参数
 - arm64 起：ABI 统一，两者基本等价，_stret 版本已废弃
 
 五、应用
 总结起来，iOS中的RunTime的作用有以下几点：
 1.发送消息(objc_msgSend)
 2.方法交换(method_exchangeImplementations)
 3.消息转发
 4.动态添加方法
 5.给分类添加属性
 6.获取到类的成员变量及其方法
 7.动态添加类
 8.解档与归档
 9.字典转模型
  
 六、runtime如何通过selector找到对应的IMP地址？

 两种方法的查找入口不同，流程一致：
 实例方法：从 对象.isa -> 类对象 开始查找
 类方法：  从 类对象.isa -> 元类 开始查找

 查找流程（每一级都重复以下步骤）：
 1. 先查当前类的 cache_t（哈希表）   命中 -> 直接返回 IMP
 2. 未命中 -> 遍历当前类的 method_list_t（方法列表）
            已排序 -> 二分查找；未排序 -> 线性遍历
 3. 找到 -> 写入 cache_t 缓存 -> 返回 IMP
 4. 未找到 -> 沿 superclass 指针到父类，重复 1~3
 5. 到 NSObject 仍未找到 -> 进入动态解析 / 消息转发流程
 
 七、使用runtime Associate方法关联的对象，需要在主对象dealloc的时候释放么？
    无论在MRC下还是ARC下均不需要。宿主对象 dealloc 时，Runtime 会在 object_dispose() 中自动遍历并按 policy 释放所有关联对象，与宿主对象同步销毁，并非"晚很多"。
 
 八、Method / IMP / SEL
 SEL：方法选择器，本质上是方法名的唯一标识（C 字符串映射）
 IMP：函数指针，方法真正的实现
 Method：runtime 中对一个方法的结构描述（包含 SEL + IMP + type encoding）
 
 九、类结构
 1、
 struct objc_object {
 private:
     isa_t isa;
 };
 2、
 struct objc_class : objc_object {
    Class superclass;
    cache_t cache;
    class_data_bits_t bits;
 };
 3、
 struct class_data_bits_t {
    uintptr_t bits;
 public:
     class_rw_t* data() {
         return (class_rw_t *)(bits & FAST_DATA_MASK);
     }
 };
 4、
 struct class_rw_t {
    uint32_t flags;
    uint32_t version;

    const class_ro_t *ro;

    method_array_t methods;
    property_array_t properties;
    protocol_array_t protocols;

 };
 5、
 struct class_ro_t {
     uint32_t flags;
     uint32_t instanceStart;
     uint32_t instanceSize;

     const uint8_t * ivarLayout;
     
     const char * name;
     method_list_t * baseMethodList;
     protocol_list_t * baseProtocols;
     const ivar_list_t * ivars;

     const uint8_t * weakIvarLayout;
     property_list_t *baseProperties;
 };
 6、
 struct property_t {
     const char *name;
     const char *attributes;
 };
7、
 struct ivar_t {
    int32_t *offset;
    const char *name;
    const char *type;
    uint32_t alignment_raw;
    uint32_t size;
 };
 8、
 struct method_t {
     SEL name;          // 函数名
     const char *types; // 编码（返回值和参数类型）
     MethodListIMP imp; // 函数指针
 };
 9、
 struct cache_t {
    struct bucket_t *_buckets; // 散列表
    mask_t _mask;              // 散列表长度
    mask_t _occupied;          // 已缓存的方法数量
 };
 10、
 struct bucket_t {
    cache_key_t _key;    // SEL作为key
    MethodCacheIMP _imp; // 函数的内存地址
 };
 
 十、super
 1、结构
 struct objc_super {
     id receiver;     // 消息接收者，仍是 self（子类对象）
     Class super_class;
 };
 objc_msgSendSuper2(struct objc_super * _Nonnull super, SEL _Nonnull op, ...)

 2、[super class]为什么打印当前类？
 1）消息接收者仍是子类对象
 2）从父类开始查找方法的实现
 3）class实现：
 - (Class)class {
     return object_getClass(self);
 }
 
 十一、为什么实例变量不允许运行时添加，方法可以

 核心原因：两者的存储位置完全不同。

 实例变量（ivar）存在对象内存里
 - 每个对象的大小 = 所有 ivar 的大小之和，编译期就固定
 - 访问 ivar 依赖偏移量（offset），偏移在类注册时写死
 - 类注册后一旦有实例存在，再改内存布局会破坏已有实例 -> 禁止添加

 方法存在类对象/元类的方法列表里，与实例内存无关
 - 无论有多少实例，方法列表只有一份，存在类对象上
 - 添加/替换方法只修改类对象的数据，不影响任何实例的内存
 - objc_msgSend 每次动态查找，改了列表下次自然生效 -> 允许添加

 想运行时给对象"加属性"：用关联对象（Associated Object）
 - 本质是 Runtime 维护的全局哈希表，与对象内存完全独立，不改 ivar 布局

 十二、class_rw_t 与 class_ro_t

 class_ro_t（read-only，Clean Memory，编译期固定）
 - 存储编译期确定的原始信息：基础方法列表、协议、ivar、属性等
 - 映射到只读段，系统需要时可丢弃并从磁盘重新读取（节省内存）

 class_rw_t（read-write，Dirty Memory，运行期可修改）
 - 运行时创建，包含 class_ro_t 的指针以及可扩展的方法/属性/协议数组
 - Category 加载、动态添加方法均写入 rw_t，而非 ro_t
 - iOS 14+ 引入 class_rw_ext_t（仅在需要时才创建扩展表），减少 Dirty Memory 占用

 关系：class_rw_t.ro = &class_ro_t（运行时读取 ro 中的基础数据，按需拷贝到 rw 可扩展数组）

 ============================================================
 十五、常见面试问答
 ============================================================

 Q：[super class] 返回什么？原理？
 A：返回当前类（子类）。
    super 只改变方法查找起点（从父类开始），但消息接收者 receiver 仍是 self。
    class 方法实现为 return object_getClass(self)，self 是子类实例，故返回子类。
    底层：[super class] → objc_msgSendSuper({self, [super class]}, @selector(class))

 Q：Method Swizzle 为什么要先 class_addMethod 再 class_replaceMethod？
 A：若本类没有该方法（实现在父类），直接 method_exchangeImplementations 会修改父类的 Method，
    导致所有子类调用该方法时都走 swizzled 版本，影响范围超出预期。
    先 class_addMethod：若本类无该方法，直接将 swizzled IMP 注册为本类该 SEL 的实现，
    再 class_replaceMethod 将 swizzled SEL 指向原 IMP，相当于只在本类范围内完成交换。
    若本类已有该方法（addMethod 返回 NO），再 method_exchangeImplementations 是安全的。
 */

@interface Mother: NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *age;
@property (nonatomic, copy, readonly) NSString *birthday;


- (void)run;
+ (void)run;


@end

@implementation Mother

- (instancetype)init
{
    self = [super init];
    if (self) {
        _birthday = @"1962";
    }
    return self;
}

+ (BOOL)accessInstanceVariablesDirectly {
    return NO;
}

- (void)goodMother:(NSString *)name {
    NSLog(@"%s--%@",__func__, name);
}

- (void)run {
    NSLog(@"%s",__func__);
}

+ (void)run {
    NSLog(@"%s",__func__);
}

- (void)sleep {
    NSLog(@"%s",__func__);
}

///演示对象，类，元类，根元类地址内存
- (void)print {
    NSLog(@"This object is %p.", self);
    NSLog(@"Class is %@, and super is %@.", [self class], [self superclass]);
    const char *name = object_getClassName(self);
    Class metaClass = objc_getMetaClass(name);
    NSLog(@"MetaClass is %p",metaClass);
    Class currentClass = [self class];
    for (int i = 1; i < 5; i++)
    {
        NSLog(@"Following the isa pointer %d times gives %p", i, currentClass);
        unsigned int countMethod = 0;
        NSLog(@"---------------**%d start**-----------------------",i);
        Method * methods = class_copyMethodList(currentClass, &countMethod);
        [self printMethod:countMethod methods:methods ];
        NSLog(@"---------------**%d end**-----------------------",i);
        currentClass = object_getClass(currentClass);
    }
    NSLog(@"NSObject's class is %p", [NSObject class]);
    NSLog(@"NSObject's meta class is %p", object_getClass([NSObject class]));
}

- (void)printMethod:(int)count methods:(Method *) methods {
    for (int j = 0; j < count; j++) {
        Method method = methods[j];
        SEL methodSEL = method_getName(method);
        const char * selName = sel_getName(methodSEL);
        if (methodSEL) {
            NSLog(@"sel------%s", selName);
        }
    }
}

@end

@interface Mother(ext)

@property (nonatomic, copy) NSString *son;

@end

@implementation Mother(ext)

- (void)goodMother:(NSString *)name {
    NSLog(@"%s--%@",__func__, name);
}

- (void)setSon:(NSString *)son {
    // 第一个参数：给哪个对象添加关联
    // 第二个参数：关联的key，通过这个key获取
    // 第三个参数：关联的value
    // 第四个参数：关联的策略，无弱引用
    objc_setAssociatedObject(self, "bowen", son, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)son {
    // 根据关联的key，获取关联的值。
    return objc_getAssociatedObject(self, "bowen");
}

@end

@interface Mother(ext2)

@end

@implementation Mother(ext2)

- (void)goodMother:(NSString *)name {
    [self callOriginalMethod:_cmd param:name];
    NSLog(@"%s--%@",__func__, name);
}


/*
 分类重写原类方法时，调用原类方法
 1.使用下面这个方法
 2.使用Aspects方法
 3._cmd 表示当前方法
 */
- (void)callOriginalMethod:(SEL)selector param:(NSString *)param {
    unsigned int count;
    unsigned int index = 0;
    
    //获得指向该类所有方法的指针
    Method *methods = class_copyMethodList([self class], &count);
    
    for (int i = 0; i < count; i++) {
        //获得该类的一个方法指针
        Method method = methods[i];
        //获取方法
        SEL methodSEL = method_getName(method);
        if (methodSEL == selector) {
            index = i;
        }
    }
    SEL fontSEL = method_getName(methods[index]);
    IMP fontIMP = method_getImplementation(methods[index]);
    ((void (*)(id, SEL, NSString *))fontIMP)(self,fontSEL,param);
    
    free(methods);
}

/*
 Class cls = NSClassFromString(@"LinkHandler");
 SEL selector = @selector(handleLink:source:from:);
 IMP imp = [cls methodForSelector:selector];
 ((id(*)(id, SEL, NSString *, id, int))imp)(cls, selector, linkUrl, room.roomInnerWebVC, 0);
 */


@end



@interface IBController13 ()

@end


@implementation IBController13

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//    [self accessToMemberVariable];

//    [self accessToMemberVariable];
//    [self accessToProperty];
//    [self accessToMethod];
//    [self accessToProtocol];
//    [self sendMsg];
//    [self addMethod];
//    [self exchangeMethod];
//    [self addCategoryProperty];
//    [self createClass];
    [self forbidKVC];
    
}

/*
 // isMemberOfClass 和 isKindOfClass 类方法和实例方法实现逻辑
 
 - isMemberOfClass: 仅检查直接类关系
 - isKindOfClass: 当前类 + 所有父类
 - 实例方法: 操作对象的类（isa指向的类）
 - 类方法: 操作类的元类（类对象的isa指向的元类）

 // 获取对象的类
 Class object_getClass(id obj) {
     if (obj) {
         return obj->isa;
     }
     return Nil;
 }
 
 // 实例方法 - 判断对象是否是指定类的直接实例
 - (BOOL)isMemberOfClass:(Class)cls {
     return [self class] == cls;
 }

 // 类方法 - 判断类对象是否是指定元类的直接实例
 + (BOOL)isMemberOfClass:(Class)cls {
     return object_getClass((id)self) == cls;
 }

 // 实例方法 - 判断对象是否是指定类或其子类的实例
 - (BOOL)isKindOfClass:(Class)cls {
     for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
         if (tcls == cls) return YES;
     }
     return NO;
 }

 // 类方法 - 判断类对象是否是指定元类或其父元类的实例
 + (BOOL)isKindOfClass:(Class)cls {
     for (Class tcls = object_getClass((id)self); tcls; tcls = tcls->superclass) {
         if (tcls == cls) return YES;
     }
     return NO;
 }
 */
- (void)kindClass {
    // 类与元类
    NSLog(@"%d", [NSObject isKindOfClass:[NSObject class]]); // 1
    NSLog(@"%d", [NSObject isMemberOfClass:[NSObject class]]); // 0
    NSLog(@"%d", [IBController13 isKindOfClass:[NSObject class]]); // 1
    NSLog(@"%d", [IBController13 isKindOfClass:[IBController13 class]]); // 0
    NSLog(@"%d", [IBController13 isMemberOfClass:[IBController13 class]]); // 0
    NSLog(@"%d", [IBController13 isKindOfClass:object_getClass([IBController13 class])]); // 1
    NSLog(@"%d", [IBController13 isMemberOfClass:object_getClass([IBController13 class])]); // 1
    
    NSLog(@"++++++++++++++++++++++++++++++++++++++++++++++");
    // 实例与对象
    NSLog(@"%d", [[[NSObject alloc] init] isKindOfClass:[NSObject class]]); // 1
    NSLog(@"%d", [[[NSObject alloc] init]  isMemberOfClass:[NSObject class]]); // 1
}

- (void)forbidKVC {
    Mother *mother = [[Mother alloc] init];
    NSLog(@"母亲生日:%@", mother.birthday);
    Ivar _birthday = class_getInstanceVariable([Mother class], "_birthday");
    object_setIvar(mother, _birthday, @"1992");
    NSLog(@"母亲生日:%@", mother.birthday);
    
    // birthday 是 readonly，且 accessInstanceVariablesDirectly = NO，KVC 会抛出 NSUnknownKeyException
    [mother setValue:@"2012" forKey:@"birthday"];
    NSLog(@"母亲生日:%@", mother.birthday);
}

- (void)print {
    [[[Mother alloc] init] print];
    [[[Mother alloc] init] goodMother:@"fang"]; //测试在分类重写方法中调用原类方法
}


///创建类
- (void)createClass {
    //使用objc_allocateClassPair创建一个类Class
    const char *ClassName = "Bowen";
    Class kClass = objc_getClass(ClassName);
    
    if (!kClass) {
        Class superClass = [NSObject class];
        kClass = objc_allocateClassPair(superClass, ClassName, 0);
    }
    
    //使用class_addIvar添加一个成员变量
    class_addIvar(kClass, "_name", sizeof(NSString*), log2(sizeof(NSString*)), @encode(NSString*));
    //使用class_addMethod添加成员方法
    class_addMethod(kClass, @selector(food:), (IMP)food, "v@:*");
    //注册到运行时环境
    objc_registerClassPair(kClass);
    //实例化类
    id instance = [[kClass alloc] init];
    //获取变量名
    Ivar nameIvar = class_getInstanceVariable(kClass, "_name");
    //给变量复制
    object_setIvar(instance, nameIvar, @"面条");
    //调用函数
    [instance performSelector:@selector(food:) withObject:object_getIvar(instance, nameIvar)];

    
}


///给分类添加属性
- (void)addCategoryProperty {
    Mother *mama = [[Mother alloc] init];
    mama.son = @"YinLong";
    NSLog(@"%@",mama.son);
}

///交换方法实现
- (void)exchangeMethod {
    SEL runSEL = @selector(run);
    SEL sleepSEL = @selector(sleep);
    
    Method runMethod = class_getInstanceMethod([Mother class], runSEL);
    Method sleepMethod = class_getInstanceMethod([Mother class], sleepSEL);
    
    BOOL isAdd = class_addMethod([Mother class], sleepSEL, method_getImplementation(sleepMethod), "v@:");
    
    if (isAdd) {
        class_replaceMethod([Mother class], runSEL, method_getImplementation(sleepMethod), "v@:");
    } else {
        method_exchangeImplementations(runMethod, sleepMethod);
    }
    Mother *mama = [[Mother alloc] init];
    [mama run];
    
}

///添加方法
- (void)addMethod {
    class_addMethod([Mother class], @selector(eat:), (IMP)food, "v@:*");
    Mother *mama = [[Mother alloc] init];
    [mama performSelector:@selector(eat:) withObject:@"饺子"];
}

void food(id self, SEL _cmd, NSString *food) {
    NSLog(@"%s %@",__func__, food);
}

///发送消息
- (void)sendMsg {
    Mother *mama = [[Mother alloc] init];
    
    // 调用对象方法
    [mama run];
    
    // 本质：让对象发送消息
    ((void(*)(id,SEL))objc_msgSend)(mama, @selector(run));
    
    // 调用类方法的方式：两种
    // 第一种通过类名调用
    [Mother run];
    // 第二种通过类对象调用
    [[Mother class] run];
    // 用类名调用类方法，底层会自动把类名转换成类对象调用
    // 本质：让类对象发送消息
    ((void(*)(id,SEL))objc_msgSend)([Mother class], @selector(run));
}

///获得成员变量
- (void)accessToMemberVariable {
    NSLog(@"成员变量");
    unsigned int count;
    Ivar *ivars = class_copyIvarList([UIResponder class], &count);
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        const char *nameC = ivar_getName(ivar);
        NSString *nameOC = [NSString stringWithUTF8String:nameC];
        NSLog(@"%@",nameOC);
    }
    free(ivars);
}

///获得属性
- (void)accessToProperty
{
    NSLog(@"属性");
    unsigned int count;
    //获得指向该类所有属性的指针
    objc_property_t *properties = class_copyPropertyList([Mother class], &count);
    
    for (int i = 0; i < count; i++) {
        //获得该类一个属性的指针
        objc_property_t property = properties[i];
        
        //获得属性的名称
        const char *nameC = property_getName(property);
        //C的字符串转成OC字符串
        NSString *nameOC = [NSString stringWithUTF8String:nameC];
        NSLog(@"%@",nameOC);
    }
    free(properties);
}
///获得方法
- (void)accessToMethod
{
    NSLog(@"方法");
    unsigned int count;
    //获得指向该类所有方法的指针
    Method *methods = class_copyMethodList([UIView class], &count);
    
    for (int i = 0; i < count; i++) {
        
        //获得该类的一个方法指针
        Method method = methods[i];
        //获取方法
        SEL methodSEL = method_getName(method);
        //将方法名转化成字符串
        const char *methodC = sel_getName(methodSEL);
        //C的字符串转成OC字符串
        NSString *methodOC = [NSString stringWithUTF8String:methodC];
        //获得方法参数个数
        int arguments = method_getNumberOfArguments(method);
        NSLog(@"%@方法的参数个数：%d",methodOC, arguments);
    }
    free(methods);
}
///获得协议
- (void)accessToProtocol
{
    NSLog(@"协议");
    unsigned int count;
    //获取指向该类遵循的所有协议的指针
    __unsafe_unretained Protocol **protocols = class_copyProtocolList([Mother class], &count);
    
    for (int i = 0; i < count; i++) {
        //获取指向该类遵循的一个协议的指针
        Protocol *protocol = protocols[i];
        
        //获得属性的名称
        const char *nameC = protocol_getName(protocol);
        //C的字符串转成OC字符串
        NSString *nameOC = [NSString stringWithUTF8String:nameC];
        NSLog(@"%@",nameOC);
        
    }
    free(protocols);
}



@end

/*
#import <Foundation/Foundation.h>

@interface Test: NSObject

@property (nonatomic, copy) NSString *name;

- (void)test;

@end

@implementation Test

- (void)test
{
    NSLog(@"%@", self.name);
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
         // NSObject *object = [[NSObject alloc] init];
        id cls = [Test class];
        void *obj = &cls;
        [(__bridge Test*)obj test];
    }
    return 0;
}
 不加object会在打印的时候崩溃
 
 加object就打印object
 当触发NSLog(@"my name is %@",self.name); 的时候self内部查找name变量进行打印，因为在栈空间中内存是连续的，isa后面接着就是_name变量，
 所以instance跳过isa8个字节找到name进行打印。回到原题我们可以看出，cls此时就是充当的实例对象，obj就是充当的指向该实例对象的指针，
 所以此时调用self.name相当于在cls内部跳过8个字节来找到进行输出，因为栈控件在内存中连续并且是从高地址开始分配内存，
 所以obj跳过8个字节就找到了NSObject *object

*/
