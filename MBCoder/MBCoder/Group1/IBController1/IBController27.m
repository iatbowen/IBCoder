//
//  IBController27.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/23.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController27.h"
#import "IBGrahpicsView.h"
#import "UIView+Ext.h"

@interface IBController27 ()

@property (nonatomic, strong) IBGrahpicsView *gView;

@end

@implementation IBController27

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self test1];
    NSLog(@"%@",self);
//    [self test2];
//    [self test3];
}

- (void)test1 {
    
    IBGrahpicsView *view = [[IBGrahpicsView alloc] initWithFrame:CGRectMake(0, TopBarHeight, self.view.width, 500)];
    view.backgroundColor = [UIColor orangeColor];
    self.gView = view;
    [self.view addSubview:view];
    
}

- (void)test3 {
    // 1. 开启一个位图上下文
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0);
    
    // 2. 获取位图上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // 3. 把屏幕上的图层渲染到图形上下文
    [self.view.layer renderInContext:ctx];
    
    // 4. 从位图上下文获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 5. 关闭上下文
    UIGraphicsEndImageContext();
    
    // 6. 存储图片
    self.gView.layer.contents = (id)image.CGImage;
    self.gView.layer.contentsScale = [UIScreen mainScreen].scale;

}

//绘制图片
- (void)test2 {
    // 创建图片
    UIImage *logoImage = [UIImage imageNamed:@"AppIcon"];
    CGSize size = logoImage.size;
    // 1. 开启位图上下文
    // 注意: 位图上下文跟view无关联，所以不需要在drawRect中获取上下文
    // size: 位图上下文的尺寸（绘制出新图片的尺寸）
    // opaque: 是否透明，YES：不透明  NO：透明，通常设置成透明的上下文
    // scale: 缩放上下文，取值0表示不缩放，通常不需要缩放上下文
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    
    // 2. 描述绘画内容
    
    // 绘制原生图片
//    [logoImage drawAtPoint:CGPointZero];
    [logoImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // 绘制文字
    NSString *logo = @"iShowMap";
    // 创建字典属性
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[NSForegroundColorAttributeName] = [UIColor whiteColor];
    dict[NSFontAttributeName] = [UIFont systemFontOfSize:5];
    [logo drawAtPoint:CGPointMake(10, 0) withAttributes:dict];
    
    // 绘制图形
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.gView.layer.contents = (id)image.CGImage;
    self.gView.layer.contentsScale = [UIScreen mainScreen].scale;

}


@end

/*

 ============================================================
 iOS 渲染原理 & 性能优化 面试题总结
 ============================================================

 一、图像渲染完整流程
 ──────────────────────────────────────────
 1. App 层（UIKit / Core Animation 构建阶段）

 【布局阶段 Layout】
 - Auto Layout 求解 / 手动设置 frame
 - 调用 layoutSubviews / layoutSublayers
 - 计算各 view / layer 的 frame、bounds、transform

 【绘制阶段 Drawing】
 - UIView 子类实现 drawRect: → 系统为其创建 CGContext
 - CALayer 实现 drawInContext:
 - 文字 / 图片通过 Core Graphics / Core Text 绘制到 backing store（位图缓冲）
 - 以上均在 CPU 上完成

 【组装图层树 Layer Tree】
 - 整个界面在内存中表现为一棵图层树，所有修改在此阶段打包

 ──────────────────────────────────────────
 2. Core Animation（IPC 提交阶段）

 - App 进程负责构建和更新图层树；渲染由独立的 Render Server 进程 + GPU 完成
 - Core Animation 维护三棵树：
   · Model Tree  ：开发者直接操作的 CALayer 树
   · Presentation Tree：动画执行中的中间状态（只读）
   · Render Tree ：打包给 GPU 的低层次渲染数据（顶点、变换、透明度等）
 - 动画原理：Core Animation 将动画描述（起止值 + 时间曲线）发送给 Render Server，
   Render Server 每帧插值生成 Presentation Layer 状态进行渲染，
   因此动画在 GPU / Render Server 侧执行，不占用主线程 CPU

 ──────────────────────────────────────────
 3. 显示管线（VSync + RunLoop 协同）

 - 屏幕以固定频率刷新（60Hz / 120Hz），每次 VSync 信号到来时：
   · 系统唤醒主线程 RunLoop
   · 主线程处理 UI 事件、布局、动画提交
   · Core Animation 收集本轮 layer 变化，通过 IPC 发送给 Render Server

 ──────────────────────────────────────────
 4. GPU 渲染阶段

 - Render Server 接收图层数据后，交由 GPU 执行以下操作：
   · Tiling（分块）：将屏幕划分成小块（tile）并行渲染，充分利用 GPU 多核
   · Compositing（合成）：按 Z 轴顺序将各图层纹理混合叠加到帧缓冲
   · 双缓冲 / 三缓冲：
     - 双缓冲（Double Buffer）：GPU 渲染到后台缓冲区，VSync 时与前台缓冲区交换；
       避免撕裂（Tearing），但若未及时完成则掉帧
     - 三缓冲（Triple Buffer）：额外一块缓冲区允许 GPU 在等待 VSync 时继续渲染下一帧，
       提升帧率稳定性，iOS 上在高负载时会自动启用

 ──────────────────────────────────────────
 5. 显示到屏幕

 - GPU 渲染完毕后图像数据写入帧缓冲（Frame Buffer）
 - 显示控制器在 VSync 时扫描帧缓冲，逐像素驱动屏幕显示

 ============================================================
 二、UIView 与 CALayer 的关系
 ============================================================

 每个 UIView 内部都有一个对应的 CALayer，两者保持一一映射：
 视图树（View Tree）↔ 图层树（Layer Tree）

 【为何分离为 UIView + CALayer 两套体系】
 职责分离：UIView 负责事件响应（触摸、手势）；CALayer 负责内容呈现与动画。
 跨平台复用：Mac 端用 NSView + CALayer，iOS 端用 UIView + CALayer，
 CALayer 代码在两端完全复用，只需替换事件处理层。
 实际上共有四棵树：视图树、图层树、呈现树（Presentation Tree）、渲染树（Render Tree）。

 【CALayer 为何能显示内容】
 CALayer 基本等同于一块 GPU 纹理（Texture）。
 其 contents 属性指向一块称为 backing store 的位图缓冲，即寄宿图（Hosted Image）。
 绘制内容有两种方式：

 方式一：Contents Image（直接设置图片）
 - 将 CGImage 赋值给 layer.contents 即可
 - contents 类型为 id：因为 Mac 端同时支持 NSImage，iOS 端只支持 CGImage
 - 若赋值非 CGImage，图层显示为空白

 方式二：Custom Drawing（Core Graphics 自定义绘制）
 - 继承 UIView，实现 drawRect: 方法
 - UIView 实现了 CALayerDelegate 协议，作为 CALayer 的 delegate
 - 绘制流程：
   1）CALayer 调用 delegate 的 -displayLayer:，代理可直接设置 contents
   2）若未实现，CALayer 调用 -drawLayer:inContext:，并传入空白 CGContext
   3）Core Graphics 在该 Context 中绘制，结果写回 backing store

 ============================================================
 三、渲染服务（Render Server）
 ============================================================

 1）App 进程通过 IPC 将图层树序列化发送给 Render Server 进程（独立进程，防止 App 崩溃影响渲染）
 2）Render Server 反序列化，重建图层树
 3）依据图层顺序、RGBA 值、frame 等过滤被完全遮挡的图层（遮挡剔除）
 4）将图层树转化为渲染树（提取顶点坐标、颜色等 GPU 所需信息）
 5）将渲染树数据提交给 Metal / OpenGL ES
 6）Metal / OpenGL ES 编译着色器，生成 GPU 绘制命令，提交到命令缓冲区（Command Buffer）供 GPU 执行

 ============================================================
 四、图形渲染管线（Graphics Rendering Pipeline）
 ============================================================

 渲染管线描述原始图形数据从顶点（Vertices）到像素（Pixels）的完整变换过程。
 主要分两步：① 3D 坐标 → 2D 坐标；② 2D 坐标 → 有颜色的像素

 GPU 渲染管线六个阶段：
 1. 顶点着色器（Vertex Shader）
    ：对每个顶点执行坐标变换（模型 → 世界 → 裁剪空间）、光照计算等
 2. 图元装配（Shape Assembly / Primitive Assembly）
    ：将顶点连接成几何图元（点 / 线段 / 三角形）
 3. 几何着色器（Geometry Shader）
    ：可选阶段，能生成新图元（iOS Metal 中支持有限）
 4. 光栅化（Rasterization）
    ：将矢量图元离散化为屏幕上的像素片段（Fragment）
 5. 片段着色器（Fragment Shader）
    ：对每个像素片段计算最终颜色（纹理采样、光照、透明度等）
 6. 测试与混合（Tests and Blending）
    ：深度测试、模板测试，以及 Alpha 混合（Blending）

 ============================================================
 五、屏幕显示 & 双缓冲机制
 ============================================================

 【CRT / LCD 扫描原理】
 CRT 电子枪从左到右、从上到下逐行扫描：
 - 换行时发出水平同步信号（HSync）
 - 一帧扫描完毕发出垂直同步信号（VSync）
 现代 LCD 原理相同，只是显示介质不同。

 【VSync 与双缓冲】
 iOS 设备始终启用垂直同步 + 双缓冲：
 - GPU 渲染到后台缓冲区（Back Buffer）
 - VSync 到来时，将前后缓冲区指针互换（Page Flip），屏幕读取新帧
 - 若 CPU + GPU 在一个 VSync 周期内未完成，该帧被丢弃（掉帧），屏幕保持上一帧

 一个 VSync 时间 = 1 ÷ 刷新率
 60Hz  → VSync 周期 ≈ 16.67 ms
 120Hz → VSync 周期 ≈  8.33 ms

 ============================================================
 六、CPU 与 GPU 工作分工
 ============================================================

 CPU 负责（软件阶段）：
 - 视图布局计算（Auto Layout 求解 / frame 赋值）
 - Core Graphics 绘制（drawRect: 中的位图渲染）
 - 文字渲染（Core Text 把字形光栅化到位图）
 - 图片解码（PNG/JPEG → 未压缩位图，默认在主线程，可优化到子线程）
 - 图层数据序列化，通过 IPC 发送给 Render Server

 GPU 负责（硬件阶段）：
 - 纹理采样（从 backing store 中读取像素）
 - 图层合成（按 Z 轴顺序 Alpha 混合叠加）
 - 几何变换（affine / 3D transform，GPU 上接近零成本）
 - 滤镜（Core Image 的模糊、色彩调整等）
 - 输出到帧缓冲

 典型 CPU 瓶颈：大量 drawRect:、复杂 Auto Layout、大图解码
 典型 GPU 瓶颈：离屏渲染、透明图层过度混合、单纹理尺寸超限（> 4096×4096）
 （离屏渲染、图层混合、光栅化、卡顿优化详见 IBController21）

 ============================================================
 七、图片加载与解码
 ============================================================

 图片从磁盘到屏幕经历三个缓冲区阶段：
 Data Buffer（磁盘编码文件）→ Image Buffer（解码后原始像素位图）→ Frame Buffer（GPU 合成后的帧）

 【解码时机】
 imageNamed: / imageWithContentsOfFile: 只是创建图片对象，不立即解码（懒加载）。
 真正的解码发生在图片首次被 Core Animation 提交给 GPU 时，默认在主线程执行，
 解码大图会阻塞主线程，导致卡顿。

 【imageNamed: vs imageWithContentsOfFile:】
 - imageNamed:：有系统内存缓存，同名图片不重复解码；适合频繁复用的小图
 - imageWithContentsOfFile:：无缓存，每次从磁盘读取解码；适合大图、一次性展示

 【子线程预解码（Force Decode）优化】
 在后台线程提前将图片渲染到 CGBitmapContext，触发解码，得到已解码的位图：

   dispatch_async(dispatch_get_global_queue(0, 0), ^{
       UIGraphicsBeginImageContextWithOptions(image.size, YES, 0);
       [image drawAtPoint:CGPointZero];
       UIImage *decodedImage = UIGraphicsGetImageFromCurrentImageContext();
       UIGraphicsEndImageContext();
       dispatch_async(dispatch_get_main_queue(), ^{
           imageView.image = decodedImage;
       });
   });

 SDWebImage、YYImage 等图片库均内置了子线程预解码逻辑。

 【图片内存占用】
 内存占用 ≈ 宽 × 高 × 4 字节（每像素 RGBA 各 1 字节），与磁盘文件大小无关
 例：3000×3000 PNG → 3000 × 3000 × 4 ≈ 36 MB

 ============================================================
 八、异步渲染
 ============================================================

 核心思路：在子线程用 Core Graphics 完成耗时绘制，将结果 bitmap 在主线程赋值给 CALayer.contents。

 实现步骤：
 1. 子线程创建 CGBitmapContext，执行所有绘制操作
 2. 从 Context 中取出 CGImage
 3. 回到主线程，将 CGImage 赋值给 layer.contents

 代表开源框架：
 - YYAsyncLayer（ibireme）：利用 RunLoop 空闲时间（BeforeWaiting）分批提交绘制任务，
   避免和主线程争用 CPU，帧率更稳定
 - Texture / AsyncDisplayKit（Meta）：节点（ASNode）系统在子线程完成布局和渲染，
   主线程只做最终的 layer 提交

 注意：
 - CGContext 非线程安全，每个线程必须有独立的 Context，不可跨线程共享
 - UIView / UILabel 等 UIKit 对象只能在主线程创建和修改

 ============================================================
 九、Metal 与 OpenGL ES
 ============================================================

 OpenGL ES（嵌入式 OpenGL）：
 - 跨平台图形 API，iOS 12 起苹果已将其标记为 Deprecated
 - 驱动层有大量隐式状态管理和运行时验证，CPU 开销相对较高

 Metal（苹果自研，iOS 8 推出）：
 - 更底层的 GPU API，减少驱动开销，CPU overhead 降低约 10 倍
 - 支持离线预编译着色器（MTLLibrary），消除运行时编译卡顿
 - 更精细的显存管理（MTLBuffer、MTLTexture、MTLHeap）
 - iOS 上 Core Animation / Core Image / SceneKit / RealityKit 底层均已切换到 Metal

 Core Animation 与 Metal 的协作：
 - 使用 CAMetalLayer 可将 MTLDrawable 直接提交到屏幕，绕过普通图层树
 - 游戏或高性能图形场景直接用 Metal 渲染，以获得最低延迟和最高帧率

 */
