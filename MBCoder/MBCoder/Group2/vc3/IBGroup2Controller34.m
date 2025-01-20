//
//  IBGroup2Controller34.m
//  MBCoder
//
//  Created by 叶修 on 2024/12/13.
//  Copyright © 2024 inke. All rights reserved.
//

#import "IBGroup2Controller34.h"

@interface IBGroup2Controller34 ()

@end

@implementation IBGroup2Controller34

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

@end

/**
 
 hook方式：Swizzle，Aspects，Stinger，fishhook，Dobby
 
 一、Swizzle
 + (void)load
 {
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
         Class aClass = [self class];
         SEL originalSelector = @selector(method_original:);
         SEL swizzledSelector = @selector(method_swizzle:);
         Method originalMethod = class_getInstanceMethod(aClass, originalSelector);
         Method swizzledMethod = class_getInstanceMethod(aClass, swizzledSelector);
         BOOL didAddMethod =
         class_addMethod(aClass,
                         originalSelector,
                         method_getImplementation(swizzledMethod),
                         method_getTypeEncoding(swizzledMethod));
         if (didAddMethod) {
             class_replaceMethod(aClass,
                             swizzledSelector,
                             method_getImplementation(originalMethod),
                             method_getTypeEncoding(originalMethod));
         } else {
             method_exchangeImplementations(originalMethod, swizzledMethod);
         }
     });
 }
 
 1、 问题
 多次hook同一方法，只会生效最后一次
 
 2、参考
 Objective-C Method Swizzling
 https://yulingtianxia.com/blog/2017/04/17/Objective-C-Method-Swizzling/

 
 二、Aspects：https://github.com/steipete/Aspects
 1、原理：
 Aspects就是利用了消息转发机制，通过hook第三层的转发方法forwardInvocation:，然后根据切面的时机来动态调用block
 
 2、具体实现：
 - 类A的方法method被添加切面方法
 - 创建一个类A的子类B，并hook子类B的forwardInvocation:方法拦截消息转发，使forwardInvocation:的IMP指向__ASPECTS_ARE_BEING_CALLED__函数，此方法执行 block
 - 把类A的对象的 isa 指针指向B，把消息的处理转发到类B上，类似KVO的机制，同时更改B类的class方法的IMP指向A类的class方法，当调用class时获取的还是类A，并不知道中间类B的存在
 - 对于方法method，类B会直接把方法method的IMP指向_objc_msgForward()方法，这样当调用方法m时就会走消息转发流程，触发 __ASPECTS_ARE_BEING_CALLED__ 函数
 
 3、关键类结构
 - AspectOptions
 是个枚举，用来定义切面的时机，即原有方法调用前、调用后、替换原有方法、只执行一次（调用完就删除切面逻辑）
 typedef NS_OPTIONS(NSUInteger, AspectOptions) {
     AspectPositionAfter   = 0,            /// 原有方法调用前执行 (default)
     AspectPositionInstead = 1,            /// 替换原有方法
     AspectPositionBefore  = 2,            /// 原有方法调用后执行
     AspectOptionAutomaticRemoval = 1 << 3 /// 执行完之后就恢复切面操作，即撤销hook
 };
 
 - AspectIdentifier类
 简单理解话就是一个存储model，主要用来存储hook方法的相关信息，如原有方法、切面block、切面时机等
 @interface AspectIdentifier : NSObject
 ...其他省略
 @property (nonatomic, assign) SEL selector; // 原来方法的SEL
 @property (nonatomic, strong) id block; // 保存要执行的切面block，即原方法执行前后要调用的方法
 @property (nonatomic, strong) NSMethodSignature *blockSignature; // block的方法签名
 @property (nonatomic, weak) id object; // target，即保存当前对象
 @property (nonatomic, assign) AspectOptions options; // 是个枚举，表示切面执行时机，上面已经有介绍
 @end
 
 - AspectsContainer类
 容器类，以关联对象的形式存储在当前类或对象中，主要用来存储当前类或对象所有的切面信息
 @interface AspectsContainer : NSObject
 ...其他省略
 @property (atomic, copy) NSArray <AspectIdentifier *>*beforeAspects; // 存储原方法调用前要执行的操作
 @property (atomic, copy) NSArray <AspectIdentifier *>*insteadAspects;// 存储替换原方法的操作
 @property (atomic, copy) NSArray <AspectIdentifier *>*afterAspects;// 存储原方法调用后要执行的操作
 @end
 
 4、问题
 另外 Appects 的实现方式比较彻底，将调用都转移到 objc_msgForward 中，导致与其他 Hook 方式不兼容，
 例如对同一个函数先后使用 Aspects 和 class_replaceMethod，会导致 class_replaceMethod 获取的原方法为 objc_msgForward，导致异常甚至崩溃。
 
 三、Stinger：https://github.com/eleme/Stinger?tab=readme-ov-file
 Stinger 是一个实现 Objective-C AOP 功能的库，有着良好的兼容性。你可以使用它在原方法的 前/替换/后位置插入(或替换)代码，实现起来比常规的方法交换更容易和灵活
 
 1、底层原理
 Stinger 使用 libffi 及解析方法签名构建壳函数，替换原方法实现以感知方法调用和捕获参数；使用同一cif模板及函数指针直接执行原实现和所有切面block。

 2、libffi
 libffi 可以认为是实现了C语言上的runtime，简单来说，libffi 可根据 参数类型(ffi_type)，参数个数 生成一个 模板(ffi_cif)；
 可以输入 模板、函数指针 和 参数地址 来直接完成 函数调用(ffi_call)； 模板 也可以生成一个所谓的 闭包(ffi_closure)，并得到指针，
 当执行到这个地址时，会执行到自定义的void function(ffi_cif *cif, void *ret, void **args, void *userdata)函数，
 在这里，我们可以获得所有参数的地址(包括返回值)，以及自定义数据userdata。当然，在这个函数里我们可以做一些额外的操作。

 3、具体实现 ：
 - 将被 hook 的 selector 的实现交换为 stingerIMP。
 - 使用 libffi的创建函数闭包的能力，将 stingerIMP 和 _st_ffi_function 绑定在一起。
 - 执行被 hook 的 selector 的时候，转为执行 stingerIMP 方法，进而执行 _st_ffi_function。
 - 在 _st_ffi_function 中，通过 ffi_call来执行被 hook 的 selector 对应的原始实现，并根据设置在合适时机执行切面的逻辑。
 
 4、参考
 Hook方法的新姿势--Stinger (使用libffi实现AOP )
 https://juejin.cn/post/6844903552343605256
 Stinger--实践实现特定实例对象的AOP
 https://juejin.cn/post/6844903793696620551
 iOS AOP 利器- Stinger 源码分析
 https://juejin.cn/post/7038237056614531086
 
 四、fishhook: https://github.com/facebook/fishhook
 Fishhook 是 Facebook 开源的一款面向 iOS/macOS 平台的 符号动态重绑定 工具，允许开发者在运行时修改 Mach-O 中的符号（函数），从而实现 动态库 的函数 hook 能力
 1、原理基础：
 由于 iOS 系统中 UIKit / Foundation 库每个应用都会通过 dyld 加载到内存中 , 因此 , 为了节约空间 , 苹果将这些系统库放在了一个地方 : 动态库共享缓存区 (dyld shared cache)
 编译时：在 Mach-O 文件 _DATA 段的符号表中为每一个被引用的系统 C 函数建立一个指针（8字节的数据，放的全是0），这个指针用于动态绑定时重定位到共享库中的函数实现
 运行时： 当系统 C 函数被第一次调用时会动态绑定一次，然后将 Mach-O 中的 _DATA 段符号表中对应的指针，指向外部函数（其在共享库中的实际内存地址）。
 
 fishhook 正是利用了 PIC 技术做了这么两个操作：
 将编译后系统库函数所指向的符号 , 在运行时重绑定到用户指定的函数地址 , 然后将原系统函数的真实地址赋值到用户指定的指针上
 
 2、为什么能修改系统函数，不能修改自定义函数
 系统函数符号位于数据段，只有数据段内容才能被修改，自定义函数在代码段，代码段具有只读可执行权限
 
 3、参考：
 iOS优秀第三方源码解析（一、深入理解fishhook源码）
 https://juejin.cn/post/6844904094734237704
 fishhook的实现原理浅析
 https://juejin.cn/post/6844903789783154702
 fishHook源码分析
 https://juejin.cn/post/6897528762708000776
 
 五、Dobby： https://github.com/jmpews/Dobby
 内联钩子，所谓InlineHook就是直接修改目标函数的头部代码。让它跳转到我们自定义的函数里面执行我们的代码，从而达到Hook的目的。这种Hook技术一般用在静态语言的HOOK上面.

 1、Dobby原理:
 运行时对目标函数的汇编代码替换，修改的是内存中MachO的代码段（强制替换），原始MachO无变化
 
 2、步骤：
 - 将原函数的前 N 个字节搬运到 Hook 函数的前 N 个字节；
 - 然后将原函数的前 N 个字节填充跳转到 Hook 函数的跳转指令；
 - 在 Hook 函数末尾几个字节填充跳转回原函数 +N 的跳转指令；
 
 Dobby替换汇编代码时,对原始函数的调用,会影响栈的拉伸和平衡
 
 3、参考
 iOS逆向实验室｜如何Hook静态语言？- Dobby
 https://juejin.cn/post/7033349361174233119
 
 iOS逆向安防从入门到秃头--InlineHook
 https://juejin.cn/post/6961975579688042503
 
 iOS Hook 原理（三）- InlinehHook （Dobby）
 https://www.jianshu.com/p/bac77377b5cb
 
 13、fishhook原理&Dobby
 https://blog.csdn.net/SharkToping/article/details/130249309


 */
