//
//  IBController21.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/17.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController21.h"

@interface IBController21 ()

@end

@implementation IBController21

/*
 1、UILabel 绘制中文使用clipsToBounds避免出现离屏渲染
 2、UILabel为什么约束左上就可以
    因为UIView的intrinsicContentSize属性，如果你不约束，我就自己计算使用
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

/*

 ============================================================
 iOS 渲染性能优化 面试题总结
 ============================================================

 一、离屏渲染（Offscreen Rendering）★★★ 高频考点
 ──────────────────────────────────────────

 【概念】
 On-Screen Rendering：GPU 渲染操作直接在当前帧缓冲中进行，效率最高。
 Off-Screen Rendering：GPU 需要先在屏幕外另开一块缓冲区（Offscreen Buffer）完成中间渲染，
 再将结果合并回帧缓冲。两次上下文切换 + 额外内存带宽开销，严重时导致掉帧。

 【离屏渲染的本质原因】
 GPU 的正常渲染是流水线式的：逐层从下到上合成，合成完一层立即丢弃中间数据。
 离屏渲染的根本原因是：某些效果需要"看见整棵子树的最终结果"才能计算，
 无法在逐层合成时完成，必须先把所有相关图层渲染到一块临时缓冲区，
 对整体施加效果后，再把结果写回帧缓冲——这就是上下文切换的代价所在。

 【触发条件及各自原因】

 1. 圆角裁剪：layer.cornerRadius > 0 && layer.masksToBounds = YES
    原因：masksToBounds 要求对整棵子图层树统一裁剪，GPU 必须先把所有子层合并到
    离屏缓冲，才能对整体做圆形裁切，无法在逐层合成过程中完成。
    ⚠️ 仅设置 cornerRadius 不设 masksToBounds 不触发（只裁背景色，无子树问题）
    ⚠️ 若视图只有单层内容（无子图层），iOS 系统可能优化为不走离屏

 2. 阴影：layer.shadowColor / shadowOpacity / shadowRadius / shadowOffset
    原因：阴影需要依据图层的实际像素轮廓来绘制（非矩形图层的轮廓不规则），
    GPU 必须先完整渲染图层内容，才能分析出轮廓形状，再在其外围绘制阴影。
    ✅ 优化：提前指定 layer.shadowPath（告知 GPU 路径形状），跳过轮廓分析，无需离屏

 3. 遮罩：layer.mask
    原因：mask 图层本身也有内容（形状/透明度），GPU 需要先把被遮罩图层和 mask 图层
    分别渲染完毕，再按像素做 alpha 相乘合并，需要在离屏缓冲中完成"两张图叠算"。

 4. 光栅化：layer.shouldRasterize = YES
    原因：这是主动触发离屏渲染的方式，系统将图层树渲染结果缓存为位图存入离屏缓冲，
    换取后续帧的直接复用（以一次离屏换多帧节省），属于性能权衡而非 bug。
    ✅ 见第三节详解

 5. 组透明度：layer.allowsGroupOpacity = YES && layer.opacity < 1
    原因：组透明度要求先把整组子图层合成为一张图，再对整体应用 opacity，
    若逐层合成时各自乘以 opacity，最终效果与"对整体乘以 opacity"不同（半透明叠加误差）。
    因此需要先离屏合并子树，再统一应用透明度。
    ⚠️ iOS 7+ 对简单情况有优化，不一定每次都触发

 6. 抗锯齿：layer.allowsEdgeAntialiasing = YES
    原因：边缘抗锯齿需要在图层边缘像素级别做混合计算，必须先将图层内容渲染到
    离屏缓冲，才能对边缘像素与背景做平滑过渡处理。

 7. 渐变：部分 CAGradientLayer 配置
    原因：当渐变与其他图层属性（如 mask、opacity）组合使用时，需要中间缓冲区来
    完成多步计算；单独简单渐变通常不触发。

 8. Core Image 滤镜：layer.filters = @[CIFilter...]
    原因：CIFilter 是基于 Core Image 的像素级后处理，必须先完整渲染图层内容，
    才能对整张位图执行滤镜运算（模糊、色调、锐化等），需要离屏缓冲区。

 9. UIVisualEffectView（毛玻璃 / 模糊效果）
    原因：模糊效果需要对背景内容做卷积运算（高斯模糊），必须先采样背景区域，
    在离屏缓冲中完成模糊计算后叠加到前景，是系统级别的主动离屏渲染。
    ⚠️ UIVisualEffectView 无法避免离屏，使用时应控制数量和尺寸

 10. drawRect: 自定义绘制
     原因：实现了 drawRect: 的视图会为其 layer 创建一块额外的 backing store（位图缓冲），
     Core Graphics 在 CPU 上绘制完成后，该位图作为纹理上传 GPU，
     相比普通视图多一次内存分配和 CPU 绘制，属于广义的"额外缓冲区"。

 【为什么圆角 + masksToBounds 是最常见的性能问题】
 视图通常由背景层、内容层等多个子图层叠加组成。masksToBounds 要求把整棵子树
 统一裁成圆角，GPU 无法在逐层合成时完成此操作，必须先将所有子层渲染到离屏缓冲，
 统一裁剪后再合并到帧缓冲。在列表场景中大量 cell 同时触发，GPU 上下文切换急剧增多，
 极易导致掉帧。

 【优化方案】
 圆角：
   a. CPU 预绘：子线程用 Core Graphics / UIBezierPath clip 绘制圆角图，赋值给 layer.contents
   b. 假圆角：叠加一张中间镂空的圆角遮罩图片覆盖在视图上
   c. iOS 13+ 设置 layer.cornerCurve = kCACornerCurveContinuous，部分场景可避免离屏
 阴影：指定 layer.shadowPath，将轮廓计算由 GPU 运行时改为 CPU 一次性预计算
 复杂静态图层：开启 shouldRasterize 缓存渲染结果（见第三节）

 【检测工具】
 Simulator → Debug → Color Offscreen-Rendered（黄色高亮触发离屏的区域）
 Instruments → Core Animation → 勾选 Offscreen-Rendered Yellow


 二、图层混合（Blending）与透明度优化
 ──────────────────────────────────────────

 【Alpha 混合原理】
 图层含透明度（alpha < 1）或背景色为透明时，GPU 需对每个像素执行混合计算：
   Result = srcColor × srcAlpha + dstColor × (1 - srcAlpha)
 半透明图层越多，GPU 读写的像素数据越多，内存带宽压力越大。

 【注意点】
 - UIImageView 比较特殊：不仅自身容器需要不透明，所加载的图片本身也必须不含 alpha 通道，
   否则仍会触发图层混合（先排查代码逻辑，再考虑图片资源本身的问题）
 - UILabel 中文内容：label 实际渲染区域大于其 frame（多出一个外层 sublayer），
   需同时设置 backgroundColor 和 layer.masksToBounds = YES 才能消除混合
   ⚠️ 单独设置 masksToBounds 不会触发离屏渲染

 【优化方案】
 - 不需要透明的视图：显式设置 view.opaque = YES（UIView 默认 YES，部分情况会被隐式改为 NO）
 - 视图背景色不留 clearColor，设置为具体颜色
 - 图片使用不含 alpha 通道的格式（如 JPEG），GPU 可直接采样无需混合
 - 减少视图层级中不必要的透明图层

 【检测工具】
 Simulator → Debug → Color Blended Layers
 红色 = 正在混合（需优化），绿色 = 不透明（性能好）


 三、光栅化（shouldRasterize）
 ──────────────────────────────────────────

 【概念】
 layer.shouldRasterize = YES：将该图层及其所有子图层的渲染结果缓存为一张位图
 （存于 Offscreen Buffer），后续帧若图层内容未变化，直接复用缓存，跳过重新渲染。

 【适合场景】
 - 子图层叠加复杂（阴影 + 圆角 + 渐变），但内容基本静态（如固定样式的 TableView Cell）
 - 复杂静态视图在列表中反复出现

 【不适合场景】
 - 动态内容（动画中的视图、频繁调用 setNeedsDisplay 的视图），缓存频繁失效反而更耗
 - 超大尺寸图层（缓存位图内存占用大）

 【注意事项】
 - 本质上仍触发一次离屏渲染来生成缓存，后续帧复用时不再触发，属于"以一次离屏换多帧节省"
 - 缓存在 100ms 内未使用则被丢弃，动画结束后不再需要时应及时关闭
 - 必须设置 layer.rasterizationScale = [UIScreen mainScreen].scale，否则 Retina 屏显示模糊

 【检测工具】
 Simulator → Debug → Color Hits Green and Misses Red
 绿色 = 缓存命中（直接复用），红色 = 缓存未命中（重新合成，消耗 CPU/GPU）


 四、卡顿原因与优化
 ──────────────────────────────────────────

 【掉帧机制】
 在一个 VSync 周期（60Hz ≈ 16.67ms）内，CPU + GPU 必须全部完成并提交帧缓冲，
 否则该帧被丢弃，屏幕保持上一帧，用户感知为"卡顿"。

 CPU vs GPU 职责与卡顿方向：
 ┌──────────┬──────────────────────────────┬──────────────────────────┐
 │          │            CPU               │           GPU            │
 ├──────────┼──────────────────────────────┼──────────────────────────┤
 │ 负责内容  │ 布局 / 绘制 / 解码 / 文字渲染  │ 渲染 / 合成 / 显示        │
 ├──────────┼──────────────────────────────┼──────────────────────────┤
 │ 卡顿原因  │ 主线程耗时任务过多             │ 渲染任务过重              │
 ├──────────┼──────────────────────────────┼──────────────────────────┤
 │ 优化方向  │ 耗时操作移到子线程             │ 减少离屏渲染              │
 │          │ 减少主线程计算量               │ 减少图层复杂度和透明度     │
 └──────────┴──────────────────────────────┴──────────────────────────┘

 【CPU 侧卡顿原因 & 优化】
 - 复杂布局计算：布局计算放到子线程，缓存 cell 高度等结果
 - 文字渲染：Core Text 在子线程完成布局，以位图形式提交主线程
 - 图片解码：imageNamed: 不立即解码，首次绘制时才在主线程解码；改用子线程预解码
 - 大量 drawRect:：改用 CALayer.contents 直接设置位图，或采用异步渲染
 - 主线程同步 I/O / 网络请求：坚决禁止，改为异步方案

 【GPU 侧卡顿原因 & 优化】
 - 离屏渲染：减少 cornerRadius + masksToBounds 滥用，指定 shadowPath（见第一节）
 - 过度图层混合：减少不必要透明图层，设置 opaque = YES（见第二节）
 - 纹理过大：单纹理超过 4096×4096 时 GPU 无法直接处理，回退到 CPU 渲染
 - 视图层级过深：合并可合并的图层，减少不必要嵌套

 【卡顿检测方案】
 a. CADisplayLink 监控 FPS
    每帧回调计算实际帧率，低于阈值（如 45 FPS）触发告警

 b. RunLoop Observer 监控主线程耗时
    监听 kCFRunLoopBeforeSources → kCFRunLoopAfterWaiting 之间的耗时，
    超过 16ms 则认为发生卡顿，捕获主线程堆栈上报

 c. Instruments 工具
    · Time Profiler  ：定位 CPU 耗时函数
    · Core Animation ：查看帧率、离屏渲染、图层混合情况
    · Allocations    ：追踪内存分配与峰值


 五、Core Animation 调试工具速查
 ──────────────────────────────────────────
 （Simulator → Debug 菜单 或 Instruments → Core Animation 中开启）

 1）Color Blended Layers（图层混合）
    红色 = 混合，绿色 = 不透明  →  见第二节

 2）Color Hits Green and Misses Red（光栅化缓存命中）
    绿色 = 缓存命中，红色 = 重新合成  →  见第三节

 3）Color Offscreen-Rendered Yellow（离屏渲染）
    黄色 = 触发离屏  →  见第一节

 4）Color Copied Images（图片格式拷贝）
    蓝色 = Core Animation 将图片额外拷贝为新缓冲区（图片未被高效复用）
    原因：图片非 BGRA8 格式、含 alpha 的 PNG、尺寸/位置包含小数
    优化：使用 BGRA8 / 不带 alpha 的 JPG；保证 imageView.frame 为整数像素

 5）Color Immediately（颜色实时刷新频率）
    高亮每次被实际绘制的区域，定位频繁重绘热点
    原因：频繁调用 setNeedsDisplay / setNeedsLayout，动画非必要区域全帧刷新
    优化：只更新真正需要刷新的控件，精细划分脏区域，避免全局刷新

 6）Color Misaligned Images（图片像素未对齐）
    洋红色 = 图片未对齐像素网格，黄色 = 图片被缩放
    原因：imageView 的 frame / size / center 包含小数
    优化：用 round / floor / ceil 取整，确保布局值为整数像素

 7）Color Compositing Fast-Path Blue（快速合成路径）
    蓝色 = 硬件直接绘制路径，越多越好
    图层简单、无透明/离屏效果、格式适配 → 才能走 Fast-Path
    优化：按图层混合和离屏渲染建议优化，使用 opaque 图层

 8）Flash Updated Regions（重绘区域）
    黄色 = 使用 Core Graphics 重绘的区域，越小越好
    频繁重绘区域是性能热点，需缩小脏区或改为异步绘制

 9）Color Layer Formats（图层像素格式）
    用颜色展示各图层像素格式（RGBA8 / BGRA8 / 浮点 / 灰度等）
    UILabel 等控件默认显示灰色背景
    优化：非必要不使用高精度格式（16bit/32bit float），避免滥用 alpha 通道

 */


@end
