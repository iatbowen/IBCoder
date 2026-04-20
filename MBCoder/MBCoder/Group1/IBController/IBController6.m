//
//  IBController6.m
//  IBCoder1
//
//  Created by Bowen on 2018/4/28.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController6.h"
#import "IBView.h"

@interface IBController6 ()

@property (nonatomic, strong) UIView *iView;
@property (nonatomic, strong) NSLayoutConstraint *height;
@property (nonatomic, strong) IBView *ibView;

@end

@implementation IBController6

/*
 一、UIViewAutoresizing

 UIViewAutoresizingNone    不会随父视图的改变而改变
 
 UIViewAutoresizingFlexibleLeftMargin 自动调整view与父视图左边距，以保证右边距不变
 
 UIViewAutoresizingFlexibleWidth 自动调整view的宽度，保证左边距和右边距不变
 
 UIViewAutoresizingFlexibleRightMargin 自动调整view与父视图右边距，以保证左边距不变
 
 UIViewAutoresizingFlexibleTopMargin 自动调整view与父视图上边距，以保证下边距不变
 
 UIViewAutoresizingFlexibleHeight  自动调整view的高度，以保证上边距和下边距不变
 
 UIViewAutoresizingFlexibleBottomMargin 自动调整view与父视图的下边距，以保证上边距不变
 
 注意：设置视图的属性autoresizesSubviews为yes才会生效(不一定)
 
 二、NSLayoutConstraint
 
 计算公式：view1.attr1 = view2.attr2 * multiplier + constant

                view1：要添加约束的视图对象
                view2：父视图
    NSLayoutAttribute：有上、下、左、右、宽、高等。
            relatedBy：两个参考属性之间关系
           multiplier：约束的比例，比如view1的宽是view2的宽的两倍，这个multiplie就是2.
             constant：约束常量
 +(instancetype)constraintWithItem:(id)view1
                         attribute:(NSLayoutAttribute)attr1
                         relatedBy:(NSLayoutRelation)relation
                            toItem:(nullable id)view2
                         attribute:(NSLayoutAttribute)attr2
                        multiplier:(CGFloat)multiplier
                          constant:(CGFloat)c;
 
 
 VFL语言语法格式
  H：代表水平方向    H:|  代表水平方向距离父视图
  V：代表垂直方向    V:|  代表垂直方向距离父视图
  |：边界
  -：间隙
 []：要添加的约束view
 
 NSLayoutFormatOptions：设置为0即可
 metrics:属性替换字典，例如我们上边用到的距离左边界20，如果这个20是变量width,我们将20的地方换成width，然后配置这个字典@{@“width":@20}，
         这样在布局时，系统会把width换成20。dictionary的key必须是NSString值，dictionary的value必须是NSNumber类型。
   views:对象的映射字典，原理也是将字符串中的对象名映射成真实的对象，NSDictionaryOfVariableBindings(对象)会帮我们生成这样的字典
 
 + (NSArray<__kind of NSLayoutConstraint *> *)constraintsWithVisualFormat:(NSString *)format
                                                                  options:(NSLayoutFormatOptions)opts
                                                                  metrics:(nullable NSDictionary *)metrics
                                                                    views:(NSDictionary *)views;
例子：
 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-100-[label(100)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]
 H:|-20-[label(100@1000)]
 前面的H代表是水平的布局还是垂直的布局，H代表水平，V表示垂直，|表示父视图的边沿，-20-表示距离20px，[]内是要布局摆放的视图对象名，()中是约束的尺寸，H下则为宽度，V下则为高度,@后面的数字代表优先级。(约束还具有 1 到 1000 之间的优先级。具有优先级 1000 的约束是必需的。小于 1,000 的所有优先级是可选的。默认情况下，所有约束都是需要 (优先级 = 1,000)。在解决所要的约束后，AutoLayout将从最高到最低的优先级顺序来处理所有可选约束，如果它不能解决一个可选的约束，它将尝试来作为尽可能接近所需的结果，然后移动到下一个约束。这种不平等、 平等和优先级的结合给你强大的灵活性。通过结合多个约束,可以定义动态地适应用户界面元素在屏幕中的大小和位置。)
 
 注意事项：
 1、约束前子视图已经添加到父视图上
 2、一定要禁止将Autoresizing Mask转换为约束（translatesAutoresizingMaskIntoConstraints设置为no）
 3、子视图约束添加到父视图上
 4、如果是设置view自身的属性，不涉及到与其他view的位置约束关系。第四个参数为nil，第五个参数为NSLayoutAttributeNotAnAttribute
 5、在设置宽和高这两个约束时，relatedBy参数使用的是 NSLayoutRelationGreaterThanOrEqual，而不是 NSLayoutRelationEqual。
 
 
 三、于UIView的translatesAutoresizingMaskIntoConstraints属性
    除了AutoLayout，AutoresizingMask也是一种布局方式。
    默认情况下，translatesAutoresizingMaskIntoConstraints ＝ true , 此时视图的AutoresizingMask会被转换成对应效果的约束。
    这样很可能就会和我们手动添加的其它约束有冲突。此属性设置成false时，AutoresizingMask就不会变成约束。也就是说 当前 视图的 AutoresizingMask失效了。
 
 四、AutoLayout与Frame篇
 问题：父视图用约束，子视图用 frame，子视图拿到的 frame 是 0
 解决方案：
 - 把子视图 frame 设置写在 layoutSubviews 或 viewDidLayoutSubviews 中
 - 设置完约束后调用 [view layoutIfNeeded] 立即刷新，再读 frame
 - 父视图 frame + 子视图约束时，可调用 setNeedsUpdateConstraints + updateConstraintsIfNeeded
 - viewDidLoad 中拿到的 frame 不可靠（未最终布局）
 
 五、刷新子布局
 
 1. layoutSubviews 触发时机：
 - layoutSubviews 触发时机
 - initWithFrame: 且 frame ≠ CGRectZero（普通 init 不触发）
 - addSubview: 时
 - 修改自身 frame（值有变化）
 - 滚动 UIScrollView
 - 旋转屏幕（触发父视图）
 - 改变子视图大小（触发父视图）（UIKit 内部在 setFrame: 实现里自动调用了 superview 的 setNeedsLayout）
 
 2、布局相关
 方法               作用
 setNeedsLayout    标记需要布局，下个 runloop 异步调用 layoutSubviews
 layoutIfNeeded    立即布局（有标记才会调用 layoutSubviews）
 layoutSubviews    实际布局，重写用于自定义子视图布局
 
 viewWillLayoutSubviews → layoutSubviews → viewDidLayoutSubviews
 
 3、重绘
 方法                       作用
 setNeedsDisplay           标记需要重绘，下个绘制周期异步调用 drawRect:
 setNeedsDisplayInRect:    标记局部重绘
 drawRect:                 重写实现绘制（能拿到 context）
 
 4、sizeToFit和sizeThatFits
 方法              区别
 sizeToFit        计算最优 size 并修改自己的 size
 sizeThatFits:    只返回最优 size，不修改
  
 六、updateViewConstraints与updateConstraints篇
 API                          类型       作用
 setNeedsUpdateConstraints    方法       标记：告诉系统下个周期更新约束（异步）
 needsUpdateConstraints       只读属性    查询：当前是否被标记为需要更新
 updateConstraintsIfNeeded    方法       立即：如果有标记，马上执行 updateConstraints
 updateConstraints            方法       执行：实际更新约束的地方（重写），最后调用 [super updateConstraints]
 
 updateConstraints → layoutSubviews → drawRect:
 （约束更新）      （布局）          （绘制）

 七、intrinsicContentSize和invalidateIntrinsicContentSize
    intrinsicContentSize：内置大小，控件本身内容控制控件大小
    invalidateIntrinsicContentSize：内置大小变化后，需重新计算尺寸，调用invalidateIntrinsicContentSize刷新
 
 八、setContentHuggingPriority和setContentCompressionResistancePriority
    setContentHuggingPriority：该优先级表示一个控件抗被拉伸的优先级。优先级越高，越不容易被拉伸。
    setContentCompressionResistancePriority：该优先级和上面那个优先级相对应，表示一个控件抗压缩的优先级。优先级越高，越不容易被压缩
 

 九、主线程不能更新UI原因
 1、线程安全性（Thread Safety）：
 UIKit 和 SwiftUI 的底层实现不是线程安全的。如果多个线程同时修改 UI 元素（例如同时更改同一个 UILabel 的 text），可能导致竞态条件（Race Condition），引发崩溃或 UI 状态不一致。
 2、渲染引擎限制
 iOS 的渲染系统（Core Animation、Core Graphics）依赖 RunLoop 在主线程上管理和同步 UI 的刷新。
 所有 UI 变更必须通过 Core Commit Transaction 提交到渲染树，这一过程是主线程 RunLoop 驱动的
 
 十、为什么 Texture（AsyncDisplayKit）可以子线程更新UI
 核心在于它通过 异步预合成、线程安全的布局计算 和 CALayer 的轻量级操作 绕过主线程部分耗时任务，而最终的 UI 更新仍严格在主线程完成
 
 AsyncDisplayKit 的核心设计
 1. 基于 Node 的抽象层
 Node：每个 ASDisplayNode 对应一个 UIView 或 CALayer，但 Node 的生命周期方法（如布局、渲染）允许在子线程执行。
 线程隔离：Node 的属性（如 frame、backgroundColor）在子线程计算，最终仅将结果提交到主线程的 UIView/CALayer。
 
 2. 异步布局与渲染
 布局计算（Layout）：在子线程执行 calculateLayoutThatFits: 方法，生成布局结果。
 图像预合成：在子线程解码图片、绘制文本（通过 CoreText），生成位图（Bitmap）缓存。
 主线程提交：仅在需要显示时，将最终结果（如 CALayer 的 contents）同步到主线程。
 
 3. CALayer 的轻量操作
 相比 UIView，CALayer 的属性（如 position、contents）修改不需要严格在主线程进行（但需通过事务提交）。
 AsyncDisplayKit 通过 CATransaction 批量提交属性变更，减少主线程开销。
 
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%s",__func__);
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.iView = [[UIView alloc] init];
    self.iView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:self.iView];
    self.iView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.iView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.iView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.iView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.iView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:100.0];
    
    self.height = height;
    [self.view addConstraints:@[left,right,top,height]];
    
//    [self.iView layoutIfNeeded]; //手动调用出现尺寸
//    NSLog(@"%@",NSStringFromCGRect(self.view.frame));
    
    self.ibView = [[IBView alloc] initWithFrame:CGRectMake(0, 250, 414, 44)];
    self.ibView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.ibView];

    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self test1];
    
}

- (void)test1 {
    
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.iView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:200.0];
    [self.view removeConstraint:self.height];
    [self.view addConstraints:@[height]];
    
    self.ibView.frame = CGRectMake(0, 250, 414, 80);
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    NSLog(@"%s",__func__);
}


- (void)viewWillLayoutSubviews {
    NSLog(@"%s",__func__);

}

- (void)viewDidLayoutSubviews {
    NSLog(@"%s--%@",__func__,NSStringFromCGRect(self.iView.frame));

}



@end
