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

/*

 ============================================================
 iOS Hook 技术全览 面试题总结
 ============================================================

 【Hook 方式概览】
 Swizzle    ：ObjC Runtime 方法交换，作用于 ObjC 方法
 Aspects    ：基于消息转发的 AOP 框架，支持 Before/Instead/After
 Stinger    ：基于 libffi 的 AOP 框架，兼容性更好
 fishhook   ：C 函数符号重绑定，作用于动态库导入的 C 函数
 Dobby      ：InlineHook，直接修改汇编指令，作用于任意函数（含静态 C）


 ============================================================
 零、AOP（面向切面编程）概念
 ============================================================

 AOP（Aspect-Oriented Programming）是一种编程范式，将与业务逻辑无关的横切关注点
 （日志、埋点、权限检查、性能监控、异常捕获等）从业务代码中剥离，统一在"切面"中处理。

 核心概念：
 - 切面（Aspect）：横切逻辑的封装单元
 - 连接点（JoinPoint）：程序执行中可以插入切面的点（如方法调用前后）
 - 切入时机：Before（方法执行前）/ After（方法执行后）/ Instead（替换方法）

 iOS 中的 AOP 实现基础：ObjC Runtime 的动态特性（消息转发、Method Swizzling）

 典型应用场景：
 - 全局埋点：无侵入地为所有 ViewController 的 viewDidAppear: 添加统计
 - 性能监控：hook 关键方法统计耗时
 - 异常防护：hook 危险方法（如数组越界）做保护
 - 权限拦截：统一拦截需要权限的操作入口


 ============================================================
 一、Method Swizzling（Swizzle）
 ============================================================

 【原理】
 利用 ObjC Runtime API 将两个 SEL 对应的 Method（IMP）互相交换，
 使调用原方法时实际执行自定义实现，在自定义实现中再调用"原方法名"即可回调原始逻辑。

 【标准实现模板】

 + (void)load {
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
         Class aClass = [self class];
         SEL originalSelector = @selector(method_original:);
         SEL swizzledSelector = @selector(method_swizzle:);
         Method originalMethod = class_getInstanceMethod(aClass, originalSelector);
         Method swizzledMethod = class_getInstanceMethod(aClass, swizzledSelector);

         // 先尝试 addMethod：若原方法是继承自父类而非本类定义，
         // 直接 exchangeImplementations 会影响父类，addMethod 可避免此问题
         BOOL didAddMethod = class_addMethod(aClass,
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

 【为什么先 class_addMethod？】
 若目标类没有直接定义该方法（继承自父类），class_getInstanceMethod 会返回父类的 Method。
 直接 exchangeImplementations 会修改父类的 IMP，影响所有子类。
 先 addMethod 将 IMP 复制到当前类，再 replaceMethod 替换，确保只影响当前类。

 【常见陷阱与最佳实践】
 1. 必须在 +load 中执行，且用 dispatch_once 保证只交换一次
    +load 在类加载时由 Runtime 调用，早于 main()，且不受 +initialize 懒加载影响
 2. 多次对同一方法 Swizzle，只会生效最后一次（IMP 链式覆盖）
    Aspects/Stinger 用链表管理多个 hook，可支持多次 hook 同一方法
 3. 不可 hook 类簇（NSArray、NSString 等）的公开接口，应 hook 具体的私有子类
    （如 __NSArrayI 而非 NSArray）
 4. Swizzle 后在自定义实现中调用"swizzledSelector"实为调用原始实现（IMP 已交换）
 5. 线程安全：+load 由 Runtime 保证串行调用，dispatch_once 保护多次调用场景


 ============================================================
 二、Aspects
 ============================================================

 【原理：利用消息转发机制（forwardInvocation:）】
 1. 为目标类动态创建子类 B（类似 KVO 的机制）
 2. 将对象的 isa 指向子类 B，外部调用 class 仍返回原类 A（B 的 class 方法 IMP 替换为 A 的）
 3. 将目标方法的 IMP 替换为 _objc_msgForward，使调用该方法时触发消息转发
 4. Hook 子类 B 的 forwardInvocation: 方法，指向 __ASPECTS_ARE_BEING_CALLED__ 函数
 5. 在 __ASPECTS_ARE_BEING_CALLED__ 中按 Before / Instead / After 时机执行切面 Block

 【关键数据结构】

 // 切面时机
 typedef NS_OPTIONS(NSUInteger, AspectOptions) {
     AspectPositionAfter   = 0,            // 原方法执行后（默认）
     AspectPositionInstead = 1,            // 替换原方法
     AspectPositionBefore  = 2,            // 原方法执行前
     AspectOptionAutomaticRemoval = 1 << 3 // 执行一次后自动撤销
 };

 // 单个切面信息
 @interface AspectIdentifier : NSObject
 @property (nonatomic, assign) SEL selector;                  // 被 hook 的方法
 @property (nonatomic, strong) id block;                      // 切面执行的 Block
 @property (nonatomic, strong) NSMethodSignature *blockSignature; // Block 签名
 @property (nonatomic, weak)   id object;                     // 关联的对象（Target）
 @property (nonatomic, assign) AspectOptions options;         // 执行时机
 @end

 // 切面容器（以关联对象形式存储在目标类/对象上）
 @interface AspectsContainer : NSObject
 @property (atomic, copy) NSArray<AspectIdentifier *> *beforeAspects;
 @property (atomic, copy) NSArray<AspectIdentifier *> *insteadAspects;
 @property (atomic, copy) NSArray<AspectIdentifier *> *afterAspects;
 @end

 【已知问题】
 - 将目标方法的 IMP 全部重定向到 _objc_msgForward，与直接使用 class_replaceMethod 的 Hook 不兼容
   （后者获取到的"原方法"已是 _objc_msgForward，调用时无限递归或崩溃）
 - 不支持 Swift 方法（没有 ObjC 消息发送机制）
 - 不支持 hook 静态方法（+method）


 ============================================================
 三、Stinger（饿了么开源）
 ============================================================

 【特点】
 基于 libffi 实现 AOP，不依赖消息转发机制，兼容性优于 Aspects，
 支持同一方法被多次 hook（链式调用），支持特定实例对象级别的 AOP。

 【libffi 是什么】
 libffi（Foreign Function Interface）相当于 C 语言的 Runtime，核心能力：
 - 根据参数类型（ffi_type）和参数个数生成调用模板（ffi_cif）
 - 通过 ffi_call(cif, fn, ret, args) 动态调用任意函数指针
 - 生成闭包（ffi_closure）：将一段内存映射为可执行函数指针，执行时回调指定 C 函数，
   在回调中可获取所有参数地址、返回值地址和自定义数据（userdata）

 【具体实现】
 1. 用 libffi 创建闭包（stingerIMP），替换 selector 的原始 IMP
 2. 闭包执行时进入 _st_ffi_function，该函数获取所有参数
 3. 在 _st_ffi_function 中按时机调用各切面 Block，并用 ffi_call 执行原始 IMP

 【优势】
 - 多次 hook 同一方法安全，不会互相覆盖
 - 与 Swizzle / class_replaceMethod 兼容，不会产生 Aspects 的冲突问题
 - 支持实例级别（per-object）AOP


 ============================================================
 四、fishhook
 ============================================================

 【适用范围】
 只能 hook 动态库中的 C 函数（如 NSLog、malloc、open 等系统 C API），
 不能 hook 自定义 C 函数（因其实现在代码段，不通过符号表间接寻址）。

 【PIC 技术基础（Position Independent Code）】
 iOS 应用引用系统动态库中的 C 函数时，编译器无法在编译时确定函数的运行时地址，
 因此在 Mach-O 的 __DATA 段建立一张"延迟绑定指针表"（__la_symbol_ptr）：
 - 编译时：每个被引用的系统 C 函数对应一个指针槽位，初始值指向 stub_helper
 - 运行时：函数第一次被调用时，dyld 执行懒绑定，将槽位指针替换为函数在共享缓存中的真实地址

 【fishhook 原理】
 在 dyld 绑定完成后，遍历 __DATA.__la_symbol_ptr 和 __nl_symbol_ptr，
 通过符号名称（字符串匹配）找到目标函数对应的指针槽位，
 将其替换为用户自定义函数地址，并保存原始函数地址供调用。

 【为什么不能 hook 自定义 C 函数】
 自定义 C 函数的实现直接编译进 __TEXT 段（代码段），调用时不经过 __DATA 的指针表，
 代码段具有只读+可执行权限（不可写），无法修改。
 系统函数通过 __DATA 的指针间接寻址，数据段可读写，所以 fishhook 可以修改。

 【典型使用场景】
 - Hook NSLog/printf 过滤/重定向日志
 - Hook malloc/free 检测内存问题
 - Hook 网络 C API（如 connect）做监控
 - 安全防护：hook dlopen/dlsym 防止动态加载恶意库


 ============================================================
 五、Dobby（InlineHook）
 ============================================================

 【适用范围】
 可 hook 任意函数，包括自定义 C/C++ 函数、ObjC 方法（通过 IMP 地址）、
 Swift 函数（需获取函数地址），常用于逆向工程和底层安全场景。

 【原理：直接修改汇编指令】
 Dobby 在运行时修改目标函数内存中的机器码（代码段），
 通过 mprotect 临时修改内存页权限为可写，完成 patch 后恢复。
 原始 MachO 文件不受影响，只影响进程运行时的内存映像。

 【具体步骤】
 1. 将目标函数开头的前 N 个字节（N 为跳转指令长度，ARM64 通常为 4 字节）备份
 2. 在目标函数开头写入跳转指令（B/BL + 偏移），跳转到 Hook 函数
 3. Hook 函数执行自定义逻辑（Before）
 4. 调用"跳板函数"（Trampoline）：执行备份的前 N 字节 + 跳回原函数 +N 处继续执行
 5. 原函数执行完毕后可返回 Hook 函数执行后续逻辑（After）

 ⚠️ 注意事项：
 - 修改汇编代码可能破坏栈帧平衡（prologue 指令被跳过），需谨慎处理
 - ARM64 下指令对齐要求严格，patch 字节数必须精确
 - 不适合在 App Store 正式包中使用（违反 Apple 代码签名完整性要求）


 ============================================================
 六、横向对比与选型建议
 ============================================================

 方案         作用目标              实现机制            兼容性       典型场景
 ──────────────────────────────────────────────────────────────────────────
 Swizzle      ObjC 实例/类方法     Runtime IMP 交换    好           埋点、防护、日志
 Aspects      ObjC 实例/类方法     消息转发             一般         AOP 切面（低频）
 Stinger      ObjC 实例/类方法     libffi 闭包          好           AOP 切面（推荐）
 fishhook     动态库 C 函数        符号重绑定            好           C API 监控/防护
 Dobby        任意函数（含 C/C++） 汇编 InlineHook      差           逆向/底层调试
 ──────────────────────────────────────────────────────────────────────────

 选型建议：
 - ObjC 方法 AOP（日志、埋点）→ Swizzle（简单）或 Stinger（需多次 hook）
 - 系统 C 函数监控（malloc/NSLog）→ fishhook
 - 需要与其他 Hook 共存 → Stinger（兼容性最好）
 - 逆向调试、静态 C 函数 Hook → Dobby（仅限调试环境）
 - 避免 Aspects 与 Swizzle/class_replaceMethod 混用（IMP 冲突）

*/
