//
//  IBController8.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/3.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController8.h"
#import "UIImageView+WebCache.h"
#import "UIView+WebCache.h"
#import "IBRunLoopLoad.h"

#define  ShowImageTableViewReusableIdentifier @"ShowImageTableViewReusableIdentifier"
#define ImageWidth 50

@interface IBRunLoopLoadCell ()

@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *topLbl;
@property (nonatomic, strong) UILabel *bottomLbl;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation IBRunLoopLoadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupCell];
    }
    return self;
}

- (void)setupCell {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 300, 25)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor redColor];
    label.font = [UIFont boldSystemFontOfSize:13];
    [self.contentView addSubview:label];
    self.topLbl = label;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 30, 200, 65)];
    imageView.backgroundColor = [UIColor lightGrayColor];
//    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imgView = imageView;
    [self.contentView addSubview:imageView];
    
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(5, 99, 300, 35)];
    label1.lineBreakMode = NSLineBreakByWordWrapping;
    label1.numberOfLines = 0;
    label1.backgroundColor = [UIColor clearColor];
    label1.textColor = [UIColor colorWithRed:0 green:100.f/255.f blue:0 alpha:1];
    label1.font = [UIFont boldSystemFontOfSize:13];
    [self.contentView addSubview:label1];
    self.bottomLbl = label1;
    
}

- (void)setLblText:(NSInteger)index {
    self.topLbl.text = [NSString stringWithFormat:@"%zd - Drawing index is top priority", index + 1];
    self.bottomLbl.text = [NSString stringWithFormat:@"%zd - Drawing large image is low priority. Should be distributed into different run loop passes.", index + 1];
}

- (void)setImageUrl:(NSString *)url {
    [self.imgView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageLowPriority|SDWebImageCacheMemoryOnly];
}

@end


/*
 一、UITableView 性能优化

 1. cell 复用
    - dequeueReusableCellWithIdentifier: 避免重复创建

 2. 高度缓存
    - 提前计算并缓存行高，避免每次 heightForRow 重新计算
    - iOS 8+ 可用 estimatedRowHeight + UITableViewAutomaticDimension 自适应高度

 3. 视图层级优化
    - 减少视图嵌套层级；使用 hidden 而非动态 addSubview/removeFromSuperview
    - 避免透明视图（透明触发 GPU 图层混合计算，opaque = YES 可关闭）

 4. 图片优化
    - 子线程解码图片（SDWebImage 默认已做），避免主线程卡顿
    - 图片尺寸与 imageView 匹配，避免实时缩放
    - 圆角图片：服务端裁好 > UIBezierPath 预生成 > masksToBounds（后者触发离屏渲染，性能最差）

 5. 按需/分时加载（RunLoop 空闲加载）
    - 监听 kCFRunLoopBeforeWaiting，滚动停止后的空闲时机执行耗时任务（本文件演示此方案）
    - 快速滚动时跳过图片加载，indexPath 不匹配则忽略回调

 6. 避免主线程阻塞
    - 网络、I/O、图片解码、JSON 解析均放子线程
    - 不在 cellForRow 中做复杂计算

 7. 内存优化
    - 使用 @autoreleasepool 包裹大量对象创建，降低内存峰值
    - NSDateFormatter / NSCalendar 用属性存储（创建代价高）
    - 懒加载非必要控件；不滥用 xib/storyboard（解析耗时）

 二、离屏渲染（Off-Screen Rendering）

 正常渲染：图层内容 → 屏幕缓冲区 → 显示（一次 pass）
 离屏渲染：图层内容 → 离屏缓冲区 → 合成 → 屏幕缓冲区 → 显示（多次 pass）

 卡顿原因：
 - GPU 需额外分配离屏缓冲区（内存开销）
 - GPU 上下文切换代价高（最致命），渲染流水线被打断
 - CPU 与 GPU 需同步等待，无法并行
 - 60Hz 屏幕每帧仅 16.67ms，工作量翻倍容易超时掉帧

 触发条件：
 - 圆角 + masksToBounds/clipsToBounds（两者同时才触发）
 - layer.mask 遮罩
 - shadow 阴影（未设置 shadowPath）
 - shouldRasterize = YES（主动触发，但可缓存复用）
 - allowsEdgeAntialiasing 抗锯齿

 优化建议：
 - 阴影：指定 layer.shadowPath，避免 GPU 自动计算轮廓
 - 圆角：服务端/预处理裁好圆角图片；或用 UIBezierPath + Core Graphics 生成圆角 image
 - 设置 layer.opaque = YES，减少图层合成
 - 图片不含 alpha 通道
 - 异步绘制：AsyncDisplayKit / VVeboTableViewDemo

 三、光栅化 shouldRasterize
 - 将 layer 渲染结果缓存为位图，下次直接复用，跳过重复渲染（主动离屏渲染换取复用收益）
 - 适合：静态、不频繁变化的复杂视图（带阴影的卡片、固定内容 cell）
 - 不适合：内容频繁变化的视图（每次变化都要重新生成缓存，反而更慢）
 - 缓存有 100ms 超时，超时未使用自动丢弃
*/


@interface IBController8 ()<UITableViewDelegate,UITableViewDataSource>

@property (strong,nonatomic) UITableView* showImageTableView;
@property (nonatomic, copy) NSArray *images;

@end

@implementation IBController8


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.showImageTableView registerClass:[IBRunLoopLoadCell class] forCellReuseIdentifier:ShowImageTableViewReusableIdentifier];
    [self.view addSubview:self.showImageTableView];
}

//懒加载
-(UITableView *)showImageTableView{
    if (!_showImageTableView) {
        _showImageTableView = [[UITableView alloc] initWithFrame:self.view.frame];
        _showImageTableView.delegate = self;
        _showImageTableView.dataSource = self;
    }
    
    return _showImageTableView;
}

//数据源代理
#pragma mark- UITableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    IBRunLoopLoadCell* cell = [tableView dequeueReusableCellWithIdentifier:ShowImageTableViewReusableIdentifier];
    cell.imgView.image = nil;
    [cell setLblText:indexPath.row];
    cell.indexPath = indexPath;
    [[IBRunLoopLoad sharedRunLoop] addTask:^{
        if ([cell.indexPath isEqual:indexPath]) {
            [cell setImageUrl:self.images[indexPath.row]];
        }
    }];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.images.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 135;
}
- (NSArray *)images {
    if (!_images) {
        _images = @[@"https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=1063018429,974188825&fm=200&gp=0.jpg",
                    @"https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=860353018,1603281892&fm=200&gp=0.jpg",
                    @"http://pic21.photophoto.cn/20111106/0020032891433708_b.jpg",
                    @"http://pic21.photophoto.cn/20111011/0006019003288114_b.jpg",
                    @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=2446086228,1541171154&fm=200&gp=0.jpg",
                    @"http://img.taopic.com/uploads/allimg/140804/240388-140P40P33417.jpg",
                    @"http://image.tupian114.com/20130521/15235862.jpg",
                    @"http://img.taopic.com/uploads/allimg/120819/214833-120Q919363810.jpg",
                    @"http://pic.58pic.com/58pic/14/27/40/58PIC6d58PICy68_1024.jpg",
                    @"http://f9.topitme.com/9/37/30/11224703137bb30379o.jpg",
                    @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=2784432848,511077205&fm=27&gp=0.jpg",
                    @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=188686010,320059973&fm=200&gp=0.jpg",
                    @"http://img3.duitang.com/uploads/item/201510/11/20151011223210_wxjQy.jpeg",
                    @"http://pic2.16pic.com/00/54/72/16pic_5472673_b.jpg",
                    @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=2653692883,494411913&fm=200&gp=0.jpg",
                    @"http://pic27.nipic.com/20130220/11588199_085535217129_2.jpg",
                    @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=1645710608,4064735852&fm=27&gp=0.jpg",
                    @"https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=1772973563,1603262817&fm=200&gp=0.jpg",
                    @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=4280515503,1510438976&fm=200&gp=0.jpg",
                    @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=3502465005,4153501499&fm=200&gp=0.jpg",
                    @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=238640327,3002157289&fm=200&gp=0.jpg",
                    @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=794351823,4243730852&fm=200&gp=0.jpg",
                    @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=1135159015,1853694453&fm=200&gp=0.jpg",
                    @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=1845261648,868382737&fm=200&gp=0.jpg",
                    @"https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=2272679418,3405114051&fm=200&gp=0.jpg",
                    @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=2284109894,2856524976&fm=27&gp=0.jpg",
                    @"https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=1315891417,203781640&fm=27&gp=0.jpg",
                    @"https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=2143735751,1143068346&fm=27&gp=0.jpg",
                    @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=1856111234,850015616&fm=200&gp=0.jpg",
                    @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=3524001812,1543361664&fm=200&gp=0.jpg"];
    }
    return _images;
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
}
@end
