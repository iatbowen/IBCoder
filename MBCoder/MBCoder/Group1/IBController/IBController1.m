//
//  IBController1.m
//  IBCoder1
//
//  Created by Bowen on 2018/4/23.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController1.h"
#import "UIView+Ext.h"

@interface IBController1 ()

@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end

/*

 ============================================================
 UIViewController 生命周期 / 圆角方案 / 缓存机制 / 断点续传 面试题总结
 ============================================================


 ============================================================
 一、UIViewController 生命周期
 ============================================================

 【完整执行顺序】

 initialize         类第一次被使用时由 runtime 调用（+方法，只调一次）
 alloc/init         对象内存分配与初始化
 initWithNibName    通过 Nib 初始化时调用（或 initWithCoder 通过 Storyboard）
 awakeFromNib       Nib/Storyboard 反序列化完成后，所有 outlet 已连接
 loadView           加载或创建根视图（不要手动调用，不要调 super 后再赋值）
 viewDidLoad        视图层级加载完毕，只调用一次，适合做一次性初始化
 viewWillAppear     视图即将出现（每次切换到该页面都会触发）
 updateViewConstraints  Auto Layout 约束更新（可在此修改约束）
 viewWillLayoutSubviews 子视图即将布局（frame 尚未最终确定）
 viewDidLayoutSubviews  子视图布局完成（frame 已确定，适合依赖 frame 的操作）
 viewDidAppear      视图已完全显示（适合启动动画、开始采集数据）
 viewWillDisappear  视图即将消失（适合暂停播放、保存草稿）
 viewDidDisappear   视图已消失（适合停止网络请求、释放资源）
 dealloc            对象释放（ARC 下自动触发）

 【关键方法说明】

 loadView
   系统默认从 Nib/Storyboard 加载根视图。
   纯代码时可重写以手动创建根视图，但不能调用 self.view（会触发递归）。
   重写时不要调 [super loadView]，直接赋值 self.view = myView。

 viewDidLoad vs viewWillAppear
   viewDidLoad：只调用一次，适合初始化数据、创建子视图、注册通知。
   viewWillAppear：每次页面出现都调用，适合刷新 UI 状态（如导航栏样式）。

 self.view = nil 的陷阱
   在 viewDidLoad 中将 self.view 置为 nil 会触发循环调用：
   访问 self.view → view 为空 → 调用 loadView → 调用 viewDidLoad → 再次置空...

 【两个 VC 切换时的完整生命周期顺序（push 为例）】
 A.viewWillDisappear → B.viewWillAppear → B.viewDidAppear → A.viewDidDisappear


 ============================================================
 二、圆角实现方案对比（对应下方 test1~test4）
 ============================================================

 【方案一：cornerRadius + masksToBounds（test1）】
 实现：layer.cornerRadius = r; layer.masksToBounds = YES;
 离屏渲染：
   - 纯色背景 + 圆角（iOS 9+）：不触发，系统优化处理
   - 图片/渐变/多层叠加 + masksToBounds：触发离屏渲染
 优点：代码简单
 缺点：复合图层场景下触发离屏渲染，频繁滚动时 GPU 压力大

 【方案二：Core Graphics + UIBezierPath（test2）】
 实现：开启 UIGraphicsContext → 设置裁剪路径 → 绘制图片 → 获取结果图
 离屏渲染：不触发（CPU 完成，直接输出位图结果）
 优点：彻底避免离屏渲染，适合静态图片
 缺点：CPU 绘制耗时，每次图片变化都需重新绘制，不适合频繁更新场景

 【方案三：CAShapeLayer + UIBezierPath 作为 mask（test3）】
 实现：创建 CAShapeLayer 设置圆角路径，赋给 layer.mask
 离屏渲染：触发（layer.mask 本质触发离屏合成）
 优点：灵活，可实现任意形状（只裁剪某几个角）
 缺点：仍触发离屏渲染，内存占用较高（mask 层额外占用）

 【方案四：预渲染（推荐方案）】
 实现：图片加载完成后，在子线程用 Core Graphics 绘制圆角，主线程赋值
 离屏渲染：不触发
 优点：GPU 零负担，滑动流畅，适合大量 cell 中的图片圆角
 缺点：需要异步处理，实现稍复杂（可用 YYImage/SDWebImage 的 processor 实现）

 【最佳实践】
 静态少量圆角：方案一（纯色背景）或方案二（图片）
 列表滚动大量圆角图片：方案四（异步预渲染），配合 SDWebImage thumbnailPixelSize 或 transformer


 ============================================================
 三、缓存机制：YYCache vs SDImageCache
 ============================================================

 【架构对比】

 YYCache
   定位：通用对象缓存（NSString/NSData/UIImage/自定义对象均可）
   内存缓存：YYMemoryCache，使用双向链表 + 字典实现 LRU，线程安全（pthread_mutex）
   磁盘缓存：YYDiskCache，文件系统 + SQLite 混合存储
     数据 > 20KB → 文件系统存储（读写速度更快）
     数据 ≤ 20KB → SQLite 存储（便于快速统计、排序、LRU 淘汰）
   淘汰策略：LRU（最近最少使用），支持按数量/大小/时间三个维度限制

 SDImageCache（SDWebImage 内置）
   定位：专用图片缓存
   内存缓存：NSCache 封装，系统内存紧张时自动清理（无精细控制）
   磁盘缓存：纯文件系统（MD5 文件名），无 SQLite
   淘汰策略：按过期时间（默认 7 天）+ 最大容量，仅在 App 进入后台/收到内存警告时触发
   局限：不支持自定义对象、不支持按数量限制、淘汰时机不够精细

 【YYCache 内存缓存 LRU 实现】
 数据结构：双向链表（维护访问顺序）+ NSDictionary（O(1) 查找）
 访问时：将节点移到链表头部（最近使用）
 淘汰时：从链表尾部移除（最久未使用）
 线程安全：pthread_mutex 保证多线程读写安全

 【选型建议】
 纯图片缓存，已用 SDWebImage → SDImageCache（内置无需额外依赖）
 需缓存任意对象、精细控制淘汰策略 → YYCache
 对内存占用敏感的图片列表 → YYCache（LRU 更精准，可设最大数量）


 ============================================================
 四、断点续传
 ============================================================

 【HTTP Range 请求机制（HTTP/1.1）】
 客户端请求头：Range: bytes=1024-2047   （请求第 1025~2048 字节）
               Range: bytes=1024-      （请求从第 1025 字节到末尾）
 服务器响应：
   成功：状态码 206 Partial Content
         响应头 Content-Range: bytes 1024-2047/10240（当前范围/总大小）
   不支持：状态码 200，返回完整内容

 【iOS 实现要点】
 1. 首次请求：正常发起，记录已下载字节数和文件总大小（从 Content-Length 获取）
 2. 中断恢复：读取本地已下载文件的大小，构造 Range 请求头，追加写入文件
 3. 数据完整性校验：下载完成后用 MD5/SHA256 与服务器提供的 ETag 或 checksum 比对
 4. NSURLSessionDownloadTask：系统级断点续传，通过 resumeData 恢复
    URLSession:task:didCompleteWithError: 中保存 resumeData
    [session downloadTaskWithResumeData:resumeData] 恢复下载

 【NSURLSessionDownloadTask 断点续传注意事项】
 resumeData 中包含临时文件路径，App 被杀死后临时文件可能被清除，resumeData 失效。
 可靠方案：手动管理分片，将已下载数据写入固定路径，恢复时从该路径续传。


 ============================================================
 五、常见面试问题
 ============================================================

 Q：viewDidLoad 和 viewWillAppear 分别适合做什么操作？
 A：viewDidLoad 只调用一次，适合一次性初始化：创建子视图、注册通知、初始化数据源。
    viewWillAppear 每次页面出现都调用，适合每次显示时需要刷新的操作：
    更新导航栏样式、刷新列表数据、恢复播放状态等。
    避免在 viewWillAppear 中做耗时操作（网络请求、大量计算）影响转场流畅性。

 Q：为什么大量圆角图片会导致列表滚动卡顿？如何解决？
 A：cornerRadius + masksToBounds 在图片/渐变场景下触发离屏渲染：
    GPU 需要先在屏幕外单独合成圆角效果，再拷贝回帧缓冲区，增加 GPU 负担。
    列表快速滚动时大量圆角触发，导致 GPU 无法在 16.7ms 内完成渲染，帧率下降。
    解决方案：预渲染（在子线程用 Core Graphics 绘制好圆角图片再赋值），
    SDWebImage 的 SDImageRoundCornerTransformer 可开箱即用。

 Q：YYCache 为什么对大小数据选择不同的存储方式？
 A：实验表明，对于 20KB 以上的数据，文件系统的顺序读写速度优于 SQLite，
    因为文件系统直接操作块设备，而 SQLite 有 B-Tree 索引维护开销。
    对于 20KB 以下的小数据，SQLite 的优势在于：
    可以用 SQL 快速统计总大小、按 LRU 时间排序找到待淘汰项，实现更精细的淘汰控制。
    纯文件系统（如 SDImageCache）要做 LRU 淘汰，需要遍历目录读取文件修改时间，效率较低。

 */

@implementation IBController1


- (void)setName:(NSString *)name {
    _name = name;
    NSLog(@"set方法在生命周期之前调用");
}

+ (void)initialize {
    NSLog(@"initialize");
}

+ (instancetype)alloc {
    NSLog(@"alloc");
    return [super alloc];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    NSLog(@"initWithNibName");
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)loadView {
    [super loadView];
    NSLog(@"loadView");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    /*
     self.view置空，后面在调用view会出现循环调用，因为view是按需加载
     如果为空，会调用loadView加载view，而loadView中调用viewDidLoad；
     */
//    self.view = nil;
    self.view.backgroundColor = [UIColor whiteColor];
}

//将要布局子视图
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    NSLog(@"viewWillLayoutSubviews");
}

//已经布局子视图
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSLog(@"viewDidLayoutSubviews");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear");
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear");
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"viewDidDisappear");
}

- (void)dealloc {
    NSLog(@"dealloc");
}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self test0];
//    [self test1];
//    [self test2];
//    [self test3];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 100, 300, 300)];
    view.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:view];
    UIBezierPath *bezier = [UIBezierPath bezierPath];
    [bezier addArcWithCenter:CGPointMake(0, 0) radius:80 startAngle:0 endAngle:M_PI_4 clockwise:YES];
    [bezier addLineToPoint:CGPointMake(0, 0)];
    CAShapeLayer *sectorLayer = [CAShapeLayer layer];
    sectorLayer.frame = CGRectMake(0, 0, 80, 60);
    sectorLayer.path = bezier.CGPath;
    sectorLayer.fillColor = [UIColor redColor].CGColor;
    sectorLayer.masksToBounds = YES;
    
    CAGradientLayer *gl = [CAGradientLayer layer];
    gl.frame = CGRectMake(0, 0, 80, 60);
    gl.startPoint = CGPointMake(0.5, 0.85);
    gl.endPoint = CGPointMake(0.5, 0);
    gl.colors = @[(__bridge id)[UIColor colorWithRed:128/255.0 green:39/255.0 blue:254/255.0 alpha:0].CGColor, (__bridge id)[UIColor colorWithRed:128/255.0 green:39/255.0 blue:254/255.0 alpha:1].CGColor];
    gl.locations = @[@(0), @(1.0f)];
    gl.mask = sectorLayer;

    
    
    [view.layer addSublayer:gl];
    CGFloat xiaoshu = (double)arc4random()/0x100000000;
    NSLog(@"%lf", xiaoshu/100);

}

/**
 方案一：cornerRadius + masksToBounds
 离屏渲染场景：
  - 非矩形透明内容(非纯色、透明、渐变、带alpha的图片)
  - 复合图层（多层叠加 + 圆角，图片 + 背景色 ）
 */
- (void)test1 {
    self.imgView.layer.cornerRadius = self.imgView.width/2;
    self.imgView.layer.masksToBounds = YES;
}

/**
 方案二：Core Graphics 和 UIBezierPath
 */
- (void)test2 {
    //开启上下文
    UIGraphicsBeginImageContextWithOptions(self.imgView.bounds.size, NO, 1.0);
    //设置裁剪区域
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.imgView.bounds cornerRadius:self.imgView.width];
    [path addClip];
    //绘制图片
    [self.imgView.image drawInRect:self.imgView.bounds];
    //从上下文中获取图片
    self.imgView.image = UIGraphicsGetImageFromCurrentImageContext();
    //关闭上下文
    UIGraphicsEndImageContext();
}

/**
 方案三：CAShapeLayer 和 UIBezierPath
 性能分析
 离屏渲染: 会触发离屏渲染
 CPU占用: 中等（路径计算）
 内存占用: 较高（mask层额外内存）
 灵活性: 高，可以实现各种复杂形状
 */
- (void)test3 {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.imgView.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:self.imgView.bounds.size];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
    //设置大小
    maskLayer.frame = self.imgView.bounds;
    //设置图形样子
    maskLayer.path = maskPath.CGPath;
    self.imgView.layer.mask = maskLayer;
}

/**
 方案四：预渲染圆角
 通常在图片加载后，借助 CoreGraphics 绘制圆角、再赋值到 UIImageView
 */
- (void)test4 {
    
}


@end
