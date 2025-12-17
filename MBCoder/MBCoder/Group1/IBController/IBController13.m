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
 注意的是:元类(meteClass)也是类，它也是对象。元类也有isa指针,它的isa指针最终指向的是一个根元类(root meteClass)。根元类的isa指针指向本身，这样形成了一个封闭的内循环。

 1、isa、superclass总结
 1）instance的isa指向class
 2）class的isa指向meta-class
 3）meta-class的isa指向基类的meta-class
 4）class的superclass指向父类的class，如果没有父类，superclass指针为nil
 5）meta-class的superclass指向父类的meta-class，基类的meta-class的superclass指向基类的class
 6）instance调用对象方法的轨迹：isa找到class，方法不存在，就通过superclass找父类
 7）class调用类方法的轨迹：isa找meta-class，方法不存在，就通过superclass找父类

 注意：从64bit开始，isa需要进行一次位运算（&ISA_MASK），才能计算出真实地址
 
 2、引用计数的存储
 在arm64架构之前，isa就是一个普通的指针，存储着Class、Meta-Class对象的内存地址
 从arm64架构开始，对isa进行了内存优化，变成了一个共用体（union）结构，还使用位域来存储更多的信息
 union isa_t {
    Class cls;
    uintptr_t bits;
    struct {
        uintptr_t nonpointer        : 1; 0代表普通指针，存储类，元类对象的内存地址；1代表优化过，使用位域存储引用计数，析构状态等信息
        uintptr_t has_assoc         : 1; 是否有设置过关联对象，如果没有，释放时会更快
        uintptr_t has_cxx_dtor      : 1; 是否有C++的析构函数（.cxx_destruct），如果没有，释放时会更快
        uintptr_t shiftcls          : 44;存储着Class、Meta-Class对象的内存地址信息
        uintptr_t magic             : 6; 用于在调试时分辨对象是否未完成初始化
        uintptr_t weakly_referenced : 1; 用于在调试时分辨对象是否未完成初始化
        uintptr_t deallocating      : 1; 对象是否正在释放
        uintptr_t has_sidetable_rc  : 1; 引用计数器是否过大无法存储在isa中,如果为1，那么引用计数会存储在一个叫SideTable的类的属性中
        uintptr_t extra_rc          : 8  里面存储的值是引用计数
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
 1) 在没有一个类的实现源码的情况下，想改变其中一个方法的实现，除了继承它重写、和借助类别重名方法暴力抢先之外，还有更加灵活的方法 Method Swizzle。
 2) Method Swizzle 指的是改变一个已存在的选择器对应的实现的过程。OC中方法的调用能够在运行时通过改变，通过改变类的调度表中选择器到最终函数间的映射关系。
 3) 在OC中调用一个方法，其实是向一个对象发送消息，查找消息的唯一依据是selector的名字。利用OC的动态特性，可以实现在运行时偷换selector对应的方法实现。
 4) 每个类都有一个方法列表，存放着selector的名字和方法实现的映射关系。IMP有点类似函数指针，指向具体的方法实现。
 5) 我们可以利用 method_exchangeImplementations 来交换2个方法中的IMP。
 6) 我们可以利用 class_replaceMethod 来修改类。
 7) 我们可以利用 method_setImplementation 来直接设置某个方法的IMP。
 8) 归根结底，都是偷换了selector的IMP。
 
 四、_objc_msgForward 函数是做什么的，直接调用它将会发生什么？
 答：_objc_msgForward是 IMP 类型，用于消息转发的：当向一个对象发送一条消息，但它并没有实现的时候，_objc_msgForward会尝试做消息转发。
    函数：id _Nullable _objc_msgForward(id _Nonnull receiver, SEL _Nonnull sel, ...)
 
 拓展：_objc_msgForward_stret 代替 _objc_msgForward 两者区别
 
 大多数 CPU 在执行 C 函数时会把前几个参数放进寄存器里，对 obj_msgSend 来说前两个参数固定是 self / _cmd，
 它们会放在寄存器上，在最后执行完后返回值也会保存在寄存器上，取这个寄存器的值就是返回值：
 -(int) method:(id)arg;
     r3 = self
     r4 = _cmd, @selector(method:)
     r5 = arg
     (on exit) r3 = returned int
 
 普通的返回值(int/pointer)很小，放在寄存器上没问题，但有些 struct 是很大的，寄存器放不下，所以要用另一种方式，
 在一开始申请一段内存，把指针保存在寄存器上，返回值往这个指针指向的内存写数据，所以寄存器要腾出一个位置放这个指针，self / _cmd 在寄存器的位置就变了：
  -(struct st) method:(id)arg;
     r3 = &struct_var (in caller's stack frame)
     r4 = self
     r5 = _cmd, @selector(method:)
     r6 = arg
     (on exit) return value written into struct_var
 
 objc_msgSend 不知道 self / _cmd 的位置变了，所以要用另一个方法 objc_msgSend_stret 代替
 
 遇到的问题：
 如果替换方法的返回值是某些 struct，在 iOS 架构中非 arm64，使用 _objc_msgForward 会 crash
 
 旧的 32 位架构（armv7、x86_64-32 等）上，一般：
 返回结构体体积较大（> 8 / 16 字节，具体依 ABI 定义）→ 用 _objc_msgForward_stret
 小结构体或标量 → _objc_msgForward
 
 64 位 iOS 上（arm64）：
 苹果在新 ABI 中对结构体返回有调整，很多情况下都不再区分 _stret；
 在现代 iOS（arm64）上，通常可以直接使用 _objc_msgForward，_objc_msgForward_stret 甚至可能被标记为废弃实现或别名。
 但为了兼容老架构 / 老系统，很多框架仍保留「根据返回类型判断是否用 _stret」的逻辑。
 
 五、应用
 总结起来，iOS中的RunTime的作用有以下几点：
 1.发送消息(obj_msgSend)
 2.方法交换(method_exchangeImplementations)
 3.消息转发
 4.动态添加方法
 5.给分类添加属性
 6.获取到类的成员变量及其方法
 7.动态添加类
 8.解档与归档
 9.字典转模型
  
 六、runtime如何通过selector找到对应的IMP地址？（分别考虑类方法和实例方法）
 实例方法 IMP 查找：
 - 从对象的 isa 指向的类对象开始，沿 superclass（父类）链，查找 selector 对应的方法，并返回其 IMP（函数指针）。
 类方法 IMP 查找：
 - 从类对象的 isa 指向的元类开始，沿元类的 superclass 链查找 selector 的方法，找到后返回 IMP。
 
 方法列表：数组，不是哈希表，用于存储所有方法定义。
 方法缓存（cache）：哈希表，用于加速 selector 到 IMP 的查找。
 
 七、使用runtime Associate方法关联的对象，需要在主对象dealloc的时候释放么？
    无论在MRC下还是ARC下均不需要，被关联的对象在生命周期内要比对象本身释放的晚很多，它们会在被 NSObject -dealloc调用的object_dispose()方法中释放
 
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
`1、结构
 struct objc_super {
     id receiver;
     Class super_class;
 };
 objc_msgSendSuper2(struct objc_super * _Nonnull super, SEL _Nonnull op, ...)

 1、[super class]为什么打印当前类？
 1）消息接收者仍是子类对象
 2）从父类开始查找方法的实现
 3）class实现：
 - (Class)class {
     return object_getClass(self);
 }
 
 十一、为什么实例变量不允许运行时添加，方法可以
 对象的内存布局在编译期就基本确定了，而方法分发是在运行时通过表结构查找完成的，两者的机制完全不同
 实例变量（ivar）
 - 是对象内存布局的一部分；
 - 偏移在编译期 / 类注册前就确定；
 - 类一旦注册并创建实例，布局就不能变，所以不能在运行时随意添加。
 
 方法
 - 存在类对象/元类对象的方法列表中，不占实例内存；
 - 查找在运行时通过 objc_msgSend 动态完成；
 - 修改方法列表只改“类的数据”，不动对象内存，所以可以在运行时添加/替换。
 
 如果你想“运行时给对象加属性”，正确做法是：关联对象（Associated Object），本质上是 runtime 维护的一个额外哈希表，而不是改对象自身的 ivar 布局。
 
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
 
 - isMemberOfClass: 仅检查直接类关系，不遍历继承链
 - isKindOfClass: 检查类关系并遍历完整继承链
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
    
    [mother setValue:@"2012" forKey:mother.birthday];
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
