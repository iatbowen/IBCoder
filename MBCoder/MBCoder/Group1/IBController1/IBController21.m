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
 Core Animation
 
 1) Color Blended Layers(图层混合)
    颜色标识：红色->混合图层  绿色->没有使用混合
    混合颜色计算公式：
    R(C)=alpha*R(B)+(1-alpha)*R(A)    R(x)、G(x)、B(x)分别指颜色x的RGB分量
    
    解决：
    - 设置opaque 属性为true。(默认为true)
    - 减少半透明区域、或者把透明度动画区域减到最小
    - 图片资源如非透明推荐用 JPG 或去掉 alpha 通道
 
     例子
     label.backgroundColor = [UIColor whiteColor];
     label.layer.masksToBounds = YES;
     到这里你可能奇怪，设置label的背景色第一行不就够了么，为什么还有第二行？
     这是因为如果label的内容是中文，label实际渲染区域要大于label的size，最外层多了一个sublayer，如果不设置第二行label的边缘外层灰出现图层混合的红色，
     因此需要在label内容是中文的情况下加第二句。单独使用label.layer.masksToBounds = YES是不会发生离屏渲染，下文会讲离屏渲染。
 
    注意点：UIImageView控件比较特殊，不仅需要自身这个容器是不透明的，并且imageView包含的内容图片也必须是不透明的，如果你自己的图片出现了图层混合红色，
       先检查是不是自己的代码有问题，如果确认代码没问题，就是图片自身的问题，可以联系你们的UI眉眉～
 
 2) Color Hits Green and Misses Red（图层合成缓存命中与否）
    用绿/红展示图层合成缓存命中与否。绿色=命中缓存，红色=没命中、要重新合成，会消耗CPU/GPU。
 
    出现的原因
    - 视图频繁修改、内容不断变化，缓存常被失效。
    - 图层层级过于复杂，且部分属性（如 transform、opacity）频繁变化。
 
    怎么解决
    - 合理拆分和合并图层，隔离频繁更新的区域。
    - 尽量减少动画或变动的视图数量与复杂度。
    - 有动态内容时用 shouldRasterize(预先渲染为位图缓存) 缓存合成，但动画结束要关闭。
 
 3）Color Copied Images（图片颜色格式）
    高亮显示被 Core Animation 拷贝为新缓冲区的图片（说明图片没被高效复用）。
    颜色标识：蓝色->需要复制
 
    出现的原因
    - 图片不是原生推荐格式（非 BGRA8、未 opaque）。
    - 图片未像素对齐。
    - 使用了带 alpha 的 PNG，或者图片尺寸/位置是小数。
 
    怎么解决
    - 用 BGRA8、JPG 不带透明或 opaque PNG。
    - 设置 imageView/图片 opaque = YES。
    - 保证 imageView 的 frame/size/position 是 pixel 对齐的整数
 
 
 4）Color Immediately（颜色刷新频率）
    绘制后马上高亮每次实际被绘制的区域，方便定位频繁重绘。
    出现的原因
    - setNeedsDisplay/setNeedsLayout等频繁调用，或高频动态刷新。
    - 动画、滑动时非必要部分也在频繁刷新。
    怎么解决
    - 只更新真的需要的数据和控件，其它控件不要随帧重绘。
    - 仔细划分脏区域，避免全局刷新。

 
 5）Color Misaligned Images(图片大小)
    高亮没对齐像素网格的图片，可能影响清晰度和渲染效率。
    颜色标识：洋红色->图片没有像素对齐，黄色->图片缩放
 
    出现的原因
    - imageView 或图片 size/位置是小数点或非整数。
    - 自动布局或手动布局未取整。
 
    怎么解决
    - 用 CGFloat 的 round、floor、ceil 保证 frame/size/center 用整数像素。

 6）Color Offscreen-Rendered Yellow（离屏渲染）
    颜色标识：黄色->发生离屏渲染
    离屏渲染 Off-Screen Rendering 指的是GPU在当前屏幕缓冲区以外新开辟一个缓冲区进行渲染操作。
    当前屏幕渲染 On-Screen Rendering ，指的是GPU的渲染操作是在当前用于显示的屏幕缓冲区中进行，只能支持简单的像素填充、透明度混合等基础绘制。
    离屏渲染会先在屏幕外创建新缓冲区，离屏渲染结束后，再从离屏切到当前屏幕，把离屏的渲染结果显示到当前屏幕上，这个上下文切换的过程是非常消耗性能的，实际开发中尽可能避免离屏渲染。
    触发离屏渲染Offscreen rendering的行为：
    （1）drawRect:方法
    （2）layer.shadow
    （3）layer.allowsGroupOpacity or layer.allowsEdgeAntialiasing
    （4）layer.shouldRasterize
    （5）layer.mask
    （6）layer.masksToBounds && layer.cornerRadius && 非单层内容

    离屏渲染的原因：
    在于它们需要对视图的像素进行复杂的计算或裁剪操作，无法直接在原始视图的上下文中进行，系统需要将视图的内容渲染到离屏缓冲区中，完成后再将结果合成到最终的屏幕帧缓冲区
 
    为什么需要避免？
    离屏渲染需要 GPU 在多个缓冲区之间切换、传输数据（内存带宽消耗），并且增加了额外的绘制指令（计算量消耗）。这会导致：
    - 增加 GPU 工作负载，消耗更多电量。
    - 可能增加帧渲染时间，导致卡顿（掉帧），特别是在大量视图同时触发离屏渲染时（如复杂列表滚动）。
 
 7）Color Compositing Fast-Path Blue (快速路径)
    颜色标记->蓝色
    标记由硬件绘制的路径，显示蓝色，越多越好。 可以直接对OpenGL绘制的图像高亮。
 
    出现的原因
    - 图层简单、无透明/离屏效果、格式适配，才能走 Fast-Path。
    - 图层过于复杂或有混合/离屏渲染则无法 Fast-Path。
 
    怎么解决
    - 按 Color Blended Layers 和 Offscreen-Rendered 优化，简化合成路径。
    - 用 opaque 图层并合并静态区域。

 8）Flash Updated Regions (重绘区域)
    颜色标识->黄色
    对重绘区域高亮为黄色，会使用CoreGraphics绘制，越小越好。
 
 9）Color Layer Formats（颜色格式）
    用颜色展示不同图层采用的像素格式（如 RGBA8、BGRA8、浮点、灰度等），可视化性能分布。颜色标识：UILabel显示灰色背景
    出现的原因
    - 图层使用了过高精度（如 RGBA 16bit/32bit float）。
    - 图层不必要地带 alpha 或使用默认格式。
    怎么解决
    - 除非必须，使用标准 BGRA8/8位格式。
    - 避免滥用高精度纹理或 alpha 通道。
    - 图片资源提前转换为适合的像素格式。
 
 
 界面顿卡的原因(主要两个方面)
 CPU限制
 1、对象的创建，释放，属性调整。这里尤其要提一下属性调整，CALayer的属性调整的时候是会创建隐式动画的，是比较损耗性能的。
 2、视图和文本的布局计算，AutoLayout的布局计算都是在主线程上的，所以占用CPU时间也很多 。
 3、文本渲染，诸如UILabel和UITextview都是在主线程渲染的
 4、图片的解码，这里要提到的是，通常UIImage只有在交给GPU之前的一瞬间，CPU才会对其解码。
 GPU限制
 1、视图的混合。比如一个界面十几层的视图叠加到一起，GPU不得不计算每个像素点药显示的像素
 2、离屏渲染。视图的Mask，圆角，阴影。
 3、半透明，GPU不得不进行数学计算，如果是不透明的，CPU只需要取上层的就可以了
 4、浮点数像素

 
 */


@end
