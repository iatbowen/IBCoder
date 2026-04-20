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
 
 一、tableview优化
 1、cell复用
 2、预先计算缓存高度
 3、渲染（异步绘制框架）
 4、视图层级优化（不要动态创建视图，善用hidden；减少视图层级）
 5、减少透明view: 透明需要图层混合计算
 6、不要阻塞主线程
 7、内存优化
 1）cell按需加载
 2）使用Autorelease Pool（避免内存峰值）
 3）gzip/zip压缩
 4）懒加载控件、页面
 5）不要使用太多的xib/storyboard
 6）重大开销对象，比如NSDateFormatter和 NSCalendar用属性存储
 7）减少离屏渲染
 
 OpenGL中，GPU屏幕渲染有以下两种方式：
    On-Screen Rendering即当前屏幕渲染，指的是GPU的渲染操作是在当前用于显示的屏幕缓冲区中进行。
    Off-Screen Rendering即离屏渲染，指的是GPU在当前屏幕缓冲区以外新开辟一个缓冲区进行渲染操作。
 
 为什么离屏渲染会发生卡顿？
 - 创建新的缓冲区（内存开销）
 GPU 要额外分配一块内存作为离屏缓冲区，频繁创建/销毁带来开销。
 - 上下文切换昂贵（最致命）
 GPU 渲染流水线被打断： 屏幕缓冲区 → 切换到离屏缓冲区 → 渲染 → 切回屏幕缓冲区 → 合成 每次切换都要重新建立 GPU 状态，代价很高。
 - 多次渲染（正常渲染1次：图层内容 ──直接渲染──▶ 屏幕缓冲区 ──▶ 显示）
 同一图层要先渲染到离屏缓冲区，再合成回屏幕，渲染次数翻倍。
 - CPU 与 GPU 同步等待
 两者无法并行工作，互相等待，浪费时间。
 - 超出每帧时间预算
 iOS 屏幕 60Hz，每帧只有 16.67ms。离屏渲染让 GPU 工作量倍增，一旦超时就掉帧，用户感知为卡顿
 
 设置了以下属性时，都会触发离屏渲染：
 - 圆角 + masksToBounds/clipsToBounds（同时满足）
 - layer.mask 遮罩
 - shadow 阴影（未指定 shadowPath）
 - 光栅化 shouldRasterize = YES
 - 抗锯齿 allowsEdgeAntialiasing
 - layer.shouldRasterize，光栅化

 离屏渲染的优化建议
 使用ShadowPath指定layer阴影效果路径。
 使用异步进行layer渲染（Facebook开源的异步绘制框架AsyncDisplayKit）。
 设置layer的opaque值为YES，减少复杂图层合成。
 尽量使用不包含透明（alpha）通道的图片资源。
 尽量设置layer的大小值为整形值。
 直接让美工把图片切成圆角进行显示，这是效率最高的一种方案。
 很多情况下用户上传图片进行显示，可以在客户端处理圆角。
 使用代码手动生成圆角image设置到要显示的View上，利用UIBezierPath（Core Graphics框架）画出来圆角图片。
 
 8）合理使用光栅化 shouldRasterize（把 layer 渲染结果缓存为位图，下次直接复用，避免重复渲染）
 使用原则：✅ 适合：静态、不变的复杂视图（如带阴影的卡片） ❌ 不适合：频繁变化的视图（每次变都要重做缓存，更慢）
   
 异步渲染
 在子线程绘制，主线程渲染。例如 VVeboTableViewDemo
 
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
