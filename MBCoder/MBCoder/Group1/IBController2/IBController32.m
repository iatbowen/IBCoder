//
//  IBController32.m
//  IBCoder1
//
//  Created by Bowen on 2018/6/1.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController32.h"

/*
 ============================================================
 Mac Catalyst 与 iOS App on Mac 面试题总结
 ============================================================


 ============================================================
 一、两种方案对比
 ============================================================

 iOS App on Mac（Apple Silicon，M1 及以后）
 - 在 Mac App Store 勾选「在 Mac 上提供 iOS App」，几乎零代码改动
 - 系统直接运行 iPad/iOS 二进制，触控映射为鼠标/触控板
 - 优点：零适配成本、上线快
 - 缺点：UI 仍是 iOS 风格，窗口/菜单/快捷键体验一般，部分 API 不可用

 Mac Catalyst（iOS 13+）
 - Xcode 勾选「Mac」目标，用 UIKit 在 macOS 上运行并做 Mac 化适配
 - 编译产物是 macOS App，可单独上架 Mac App Store
 - 优点：可深度定制 Mac 体验（菜单栏、多窗口、悬停、键盘快捷键）
 - 缺点：需要专门测试与适配，部分 iOS 框架不可用

 关系：面向 Mac 用户时通常二选一（同一产品很少同时维护两套 Mac 分发路径）。
 选型：轻量工具/游戏 → iOS App on Mac；生产力/办公类 → Catalyst；专业级 → 独立 macOS（AppKit/SwiftUI）。


 ============================================================
 二、Catalyst 系统自动处理的内容
 ============================================================

 触摸事件        → 鼠标左键 / 触控板
 部分 UIKit 控件 → 更接近 macOS 的外观与交互（如 UISwitch、UIActivityIndicator）
 UINavigationBar   → 可配合 Mac 风格工具栏
 iPad 分屏/Scene   → 多窗口（需配合 UIScene、windowScene 配置）
 指针交互        → iOS 13.4+ 支持 UIPointerInteraction / UIHoverStyle

 仍需开发者处理：菜单栏、快捷键、文件访问方式、窗口尺寸策略、不支持的 API 隔离。


 ============================================================
 三、如何开启
 ============================================================

 iOS App on Mac
 - App Store Connect → App 信息 → 勾选在 Mac 上提供（需 Apple Silicon 相关配置）
 - 无需改 Xcode Target，本质是分发选项

 Mac Catalyst
 - Target → General → Supported Destinations 勾选 Mac
 - 或 Build Settings → SUPPORTED_PLATFORMS 含 macosx，DERIVE_MACCATALYST_PRODUCT = YES
 - 首次会生成 Mac 专用 Asset、Info.plist 差异，需单独 Archive Mac 版本


 ============================================================
 四、平台判断（编译期 / 运行期）
 ============================================================

 【Objective-C 编译期】
 #if TARGET_OS_MACCATALYST
     // Mac Catalyst 构建
 #else
     // iPhone / iPad
 #endif

 【Objective-C 运行期】
 if (@available(iOS 13.0, *)) {
     if ([[NSProcessInfo processInfo] isMacCatalystApp]) {
         // 当前进程跑在 Catalyst 环境
     }
 }

 【Swift 编译期】
 #if targetEnvironment(macCatalyst)
     setupMacFeatures()
 #else
     setupiOSFeatures()
 #endif

 【Swift 运行期】
 if ProcessInfo.processInfo.isMacCatalystApp { ... }

 注意：iOS App on Mac 上 isMacCatalystApp 为 NO（不是 Catalyst 包）；
       若需区分「真 iPad」与「iOS App on Mac」，可用：
       #if TARGET_OS_MACCATALYST → Catalyst
       否则在 Mac 上可用 ProcessInfo.processInfo.isiOSAppOnMac（iOS 14+）判断 iOS App on Mac。


 ============================================================
 五、不支持的 API 与隔离方式
 ============================================================

 常见在 Catalyst / Mac 上不可用或受限的框架（需条件编译或运行时降级）：
 - ARKit、HealthKit、CallKit、CoreTelephony
 - 部分传感器、NFC、后台定位策略与 iOS 不一致
 - 仅真机可用的私有/硬件相关 API

 隔离写法（OC）：
 #if !TARGET_OS_MACCATALYST
     // ARKit、HealthKit 等仅 iOS 真机/iPad 路径
     [self setupARSession];
 #endif

 原则：编译期用宏剪掉依赖；运行期对可选能力做 feature detection，避免直接崩溃。


 ============================================================
 六、Mac 特性适配（Catalyst 核心工作）
 ============================================================

 1. 菜单栏与快捷键
    - 使用 UIKeyCommand / UICommand 或构建 UIMenu
    - 为常用操作提供 Cmd+S、Cmd+W 等，符合 Mac 用户习惯

 2. 窗口与多窗口
    - 配置 Info.plist：UIApplicationSceneManifest，支持多 Scene
    - 合理设置 UIWindowScene 尺寸、最小/最大窗口；避免固定 iPhone 窄屏布局

 3. 指针与悬停
    - 列表/按钮增加 hover 高亮（UIPointerInteraction、UIHoverStyle）
    - 区分 click 与 iOS 的 tap 语义

 4. 文件与拖拽
    - 优先 UIDocumentPickerViewController、NSItemProvider 拖拽
    - 沙盒路径与 iOS 不同，勿写死 Documents 假设

 5. 布局与导航
    - 宽屏使用 splitView / 侧边栏，避免单纯放大 iPhone 竖屏 UI
    - popover 在 Mac 上锚点与尺寸需单独调

 6. 键盘与焦点
    - Tab 键焦点链、Esc 关闭面板
    - UITextField 与 Mac 输入法、快捷键冲突需测试

 7. Mac 专用能力（可选）
    - UIActivityItemsConfiguration、Touch Bar（旧设备）、Services 菜单集成


 ============================================================
 七、测试与上架注意
 ============================================================

 - Catalyst 必须在「My Mac (Designed for iPad)」或 Mac 目标下跑完整回归
 - 检查 Human Interface Guidelines：Mac 版需满足菜单、窗口、指针交互
 - Mac App Store 审核关注：沙盒、隐私描述、与 iOS 版功能差异说明
 - 性能：桌面端常驻内存、多窗口同时存在，注意图片缓存与后台任务


 ============================================================
 八、选型建议
 ============================================================

 简单应用、重投放速度        → iOS App on Mac
 需要接近原生 Mac 体验       → Mac Catalyst
 专业工具、重度 Mac 独占能力 → 独立 macOS（AppKit / SwiftUI）


 ============================================================
 九、常见面试问答
 ============================================================

 Q：Mac Catalyst 和 iOS App on Mac 有什么区别？
 A：iOS App on Mac 是商店分发选项，系统直接跑 iPad 包，几乎不改代码；
    Catalyst 是单独 Mac 目标，UIKit 跑在 macOS 上，可菜单栏、多窗口、悬停等深度适配。
    前者零成本体验一般，后者要投入适配但更接近 Mac 原生。

 Q：如何在代码里判断当前是否 Catalyst？
 A：编译期 TARGET_OS_MACCATALYST（OC）或 targetEnvironment(macCatalyst)（Swift）；
    运行期 [NSProcessInfo processInfo].isMacCatalystApp（iOS 13+）。
    iOS App on Mac 时 isMacCatalystApp 为 NO，需用 isiOSAppOnMac 区分。

 Q：Catalyst 为什么要 #if !TARGET_OS_MACCATALYST 包一层？
 A：部分框架在 Mac 上不存在或链接失败，编译期剔除可避免符号缺失；
    同时避免运行时在 Mac 上调用仅 iOS 硬件支持的 API 导致崩溃。

 Q：Catalyst 会自动把触摸变成鼠标吗？还需要改什么？
 A：系统会做基础事件映射，但菜单、快捷键、窗口策略、hover、键盘焦点、
    宽屏布局仍需开发者按 Mac HIG 适配，否则仍是「放大的 iPad 应用」。

 */

@interface IBController32 ()

@end

@implementation IBController32

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
