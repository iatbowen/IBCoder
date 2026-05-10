//
//  IBGroup2Controller24.m
//  MBCoder
//
//  Created by BowenCoder on 2020/2/19.
//  Copyright © 2020 inke. All rights reserved.
//

#import "IBGroup2Controller24.h"

@interface IBGroup2Controller24 ()

@end

@implementation IBGroup2Controller24

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

/*

 ============================================================
 编译原理、LLVM、Mach-O 与编译优化 面试题总结
 ============================================================

 一、__builtin_expect 与分支预测优化
 ──────────────────────────────────────────

 【原理】
 现代 CPU 采用流水线（Pipeline）技术：在一条指令未执行完时，就预取后续指令并行处理。
 遇到条件跳转（if/else）时，CPU 需要预测走哪个分支，若预测失败则必须清空流水线重新取指，
 造成 10~20 个时钟周期的惩罚（Pipeline Flush）。

 __builtin_expect(EXP, N) 是 GCC/Clang 提供的编译器提示，告知编译器 EXP == N 的概率很大，
 让编译器将"高概率路径"的代码排在前面（减少跳转），提升 CPU 分支预测准确率。

 【示例】
 if (__builtin_expect(x, 0)) {   // 告知编译器：x 为 0 的概率很大
     return 1;
 } else {
     return 2;
 }
 编译器会将 else 分支（x==0）生成为顺序执行路径，if 分支生成为跳转路径，
 CPU 直接顺序执行的概率大幅提升。

 【宏封装（Linux 内核常见用法）】
 #define likely(x)   __builtin_expect(!!(x), 1)   // 该条件大概率为真（fastpath）
 #define unlikely(x) __builtin_expect(!!(x), 0)   // 该条件极少为真（slowpath）

 使用场景：错误处理路径（错误极少发生）、热点循环中的边界检查等。


 ============================================================
 二、LLVM 三段式架构
 ============================================================

 【架构设计】
 传统编译器（如 GCC）前后端耦合严重，支持新语言或新平台需要大量修改。
 LLVM 采用三段式设计，以 LLVM IR 为通用中间表示，彻底解耦：

   前端（Frontend）→ LLVM IR → 优化器（Optimizer）→ LLVM IR → 后端（Backend）→ 机器码

   前端举例：Clang（C/C++/OC）、llvm-gcc（Fortran）、GHC（Haskell）、swiftc（Swift）
   后端举例：LLVM X86 Backend、LLVM ARM Backend、LLVM PowerPC Backend

 【三段各自职责】

 1. 前端（Frontend）
    词法分析 → 语法分析 → 语义分析 → 类型检查 → 生成 LLVM IR
    负责将源代码转换为与平台无关的中间表示，同时输出编译错误/警告及其行号。

 2. 优化器（Optimizer）
    对 LLVM IR 进行平台无关的通用优化，包括：
    - 常量折叠（Constant Folding）
    - 死代码消除（Dead Code Elimination）
    - 内联展开（Function Inlining）
    - 循环优化（Loop Unrolling / Loop Vectorization）
    - 全局值编号（GVN）等
    优化级别：-O0（不优化）/ -O1 / -O2 / -O3（最激进）/ -Os（优化代码尺寸）

 3. 后端（Backend）
    将优化后的 LLVM IR 转换为目标平台的汇编代码，再经汇编器生成机器码（.o 文件）。
    不同架构（arm64、x86_64）各自有独立的后端实现。

 【LLVM IR 的三种形式】
 text（.ll）   ：文本格式，类汇编语言，人类可读
                 未优化：$ clang -S -emit-llvm source.m
                 优化后：$ clang -O3 -S -emit-llvm source.m
 memory        ：内存中的数据结构，编译器内部使用
 bitcode（.bc）：二进制格式，用于分发和 Apple Bitcode 提交
                 $ clang -c -emit-llvm source.m


 ============================================================
 三、Clang 与 GCC 对比
 ============================================================

 Clang 是 LLVM 的 C/C++/Objective-C 编译器前端，相比 GCC 的优势：

 编译速度    ：Debug 模式下编译 OC 代码比 GCC 快约 3 倍
 内存占用    ：生成的 AST 内存占用约为 GCC 的 1/5
 诊断信息    ：错误提示更精准（指出具体列号、提供 Fix-it 提示）
 模块化设计  ：基于库的模块化设计，易于 IDE 集成（Xcode SourceKit）和工具复用
 静态分析    ：内置强大的 Clang Static Analyzer，支持路径敏感分析
 可扩展性    ：支持 Clang Plugin 机制，可自定义 AST 检查和代码转换


 ============================================================
 四、OC 源文件完整编译流程
 ============================================================

 查看完整编译阶段：$ clang -ccc-print-phases source.m

 【阶段 1：预处理（Preprocessor）】
 处理所有以 # 开头的指令：
 - 头文件展开（#import / #include）
 - 宏展开与替换（#define）
 - 条件编译（#ifdef / #ifndef）
 - 注释删除
 查看结果：$ clang -E source.m

 【阶段 2：编译（Compiler）— 前端主要工作】
 a. 词法分析（Lexical Analysis）
    将源码字符流转换为 Token 序列（标识符、关键字、运算符、字面量等）
    查看：$ clang -fmodules -E -Xclang -dump-tokens source.m

 b. 语法分析（Syntax Analysis）
    将 Token 序列按语法规则组织成抽象语法树（AST）
    查看：$ clang -fmodules -fsyntax-only -Xclang -ast-dump source.m

 c. 语义分析（Semantic Analysis）
    类型检查、方法调用验证、变量未声明检查，产生编译警告/错误

 d. 中间代码生成（IR Generation）
    将 AST 自顶向下遍历翻译为 LLVM IR

 【阶段 3：优化（Optimizer）】
 对 LLVM IR 进行平台无关优化（由 -O0/-O1/-O2/-O3/-Os 控制优化程度）

 【阶段 4：后端生成汇编（Backend）】
 将优化后的 LLVM IR 转换为目标架构汇编代码（.s 文件）

 【阶段 5：汇编（Assembler）】
 汇编器（as）将汇编代码转换为机器码，生成可重定位目标文件（.o 文件）
 .o 文件本质上是一个 Mach-O 格式的文件（可重定位类型）

 【阶段 6：链接（Linker）】
 链接器（ld）将多个 .o 文件及静态库/动态库链接，生成最终可执行的 Mach-O 文件
 主要工作：符号解析（Symbol Resolution）、重定位（Relocation）


 ============================================================
 五、Mach-O 文件格式
 ============================================================

 （Mach-O 文件结构、Load Commands、Segments/Sections、符号表、dSYM、ASLR 详见 IBController23）


 ============================================================
 六、iOS 项目 Xcode 编译流程
 ============================================================

 【子工程（Pod/Framework）编译】
 1. Write Auxiliary Files：生成 .hmap（头文件映射）、LinkFileList（.o 文件列表）等辅助文件
 2. 预编译 PCH 文件（若开启 Precompile Prefix Header）
 3. 逐文件编译（CompileC）：每个 .m 文件经 Clang 完整前端→优化→后端流程生成 .o
 4. 写入 LinkFileList：汇总所有 .o 路径
 5. 打包静态库（libtool）：将 .o 合并为 .a 静态库

 【主工程编译】
 1. 创建 .app 目录包
 2. 生成 Entitlements.plist（授予 App 能力和沙盒权限）
 3. 处理 Package（证书、Provisioning Profile 验证）
 4. 运行 Pre-Build 脚本（如 CocoaPods Check Pods Manifest.lock）
 5. 预编译 PCH 文件
 6. 逐文件编译：所有 .m 文件生成 .o（最耗时阶段之一）
 7. 链接（ld）：将所有 .o 及静态库合并，解析符号，生成 Mach-O 可执行文件（最耗时）
 8. 编译 Asset Catalog（xcassets → Assets.car）
 9. 拷贝资源文件（图片、字体、Storyboard、xib 等）
 10. 处理 Info.plist
 11. 嵌入动态 Frameworks（[CP] Embed Pods Frameworks）
 12. 生成 dSYM 符号文件
 13. 运行 Post-Build 脚本
 14. 代码签名（codesign）


 ============================================================
 七、Bitcode
 ============================================================

 【概念】
 Bitcode 是 LLVM IR 的二进制序列化形式（.bc 文件），是前端编译输出的中间产物。
 开启 Bitcode 后，提交到 App Store 的不是最终机器码，而是 Bitcode，
 Apple 服务器会针对不同设备架构重新编译生成最优机器码。

 【优点】
 - App Store 可针对新指令集（如未来的 arm 扩展）重新优化，无需开发者重新提交
 - 按需下载（App Thinning）：用户只下载其设备对应的架构包

 【注意】
 - 开启 Bitcode 要求所有依赖库也必须包含 Bitcode
 - Apple 在 Xcode 14 之后默认关闭了 Bitcode 提交（已不再被 App Store 使用）


 ============================================================
 八、编译速度优化
 ============================================================

 【工程配置优化】

 1. Build Active Architecture Only
    Debug 设为 YES，只编译当前连接设备的架构（如 arm64），不生成 Fat Binary，
    大幅减少编译产物体积和链接时间。Release 设为 NO 以支持所有架构。

 2. Precompile Prefix Header
    将 Precompile Prefix Header 设为 YES，PCH 文件预编译后缓存复用，
    避免每个编译单元重复解析公共头文件。需在 Prefix Header 中配置 PCH 路径。

 3. Debug Information Format
    Debug 模式改为 DWARF（不生成 .dSYM），减少调试信息写入时间。
    DWARF with dSYM 用于 Release，方便崩溃符号化。
    ⚠️ 改为 DWARF 后，崩溃无法在设备上还原符号，调试时影响不大。

 4. 关闭 Debug 模式下的 Link Time Optimization（LTO）
    LTO 在链接阶段进行全局优化，大幅增加链接耗时，Release 使用，Debug 关闭。

 5. Optimization Level
    Debug 设为 None（-O0），关闭编译优化，保证断点和调试信息准确。
    Release 设为 Fastest, Smallest（-Os），在速度和体积间取最优。

 6. 采用新构建系统（New Build System）
    Xcode 10+ 默认启用，支持增量编译和并行任务调度，编译速度明显优于旧系统。

 7. 增加 Xcode 并行编译线程数
    defaults write com.apple.Xcode PBXNumberOfParallelBuildSubtasks 8

 【代码与项目结构优化】

 8. 减少无用文件：删除无用的类、资源、图片，降低编译单元数量

 9. 二进制化第三方库
    将基础组件和不常修改的三方库打成静态 .a 或 XCFramework 二进制，
    跳过其源码编译，显著缩短增量编译时间（代价是调试不方便）。

 10. 减少头文件引用，使用 @class 前向声明
     头文件中尽量使用 @class 替代 #import，避免头文件链式展开。
     减少一个头文件变动引起大量文件重新编译的级联效应。

 11. 优化 PCH 文件
     PCH 中只放真正全局使用的头文件（UIKit、Foundation 等），
     减少 PCH 过大造成预编译缓存频繁失效。

 12. 减少 Storyboard / XIB 文件
     Storyboard 编译（ibtool）通常耗时较长，拆分大 Storyboard 或改用纯代码布局。

 【增量编译原理】
 Xcode 会对每个编译单元（.m 文件）计算"输入文件 + 编译选项"的指纹，
 若指纹与上次编译相同，则直接复用缓存的 .o 文件，跳过重新编译。
 因此：头文件变动影响范围越广（被大量 .m 引用），增量编译收益越低。

*/

@end
