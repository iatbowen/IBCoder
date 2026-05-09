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
 一、UIViewAutoresizing（弹簧 & 支柱模型）
 需父视图 autoresizesSubviews = YES 才生效

 选项                          作用
 None                          固定，不随父视图变化
 FlexibleLeftMargin            左边距弹性（保持右边距固定）
 FlexibleRightMargin           右边距弹性（保持左边距固定）
 FlexibleTopMargin             上边距弹性（保持下边距固定）
 FlexibleBottomMargin          下边距弹性（保持上边距固定）
 FlexibleWidth                 宽度弹性（保持左右边距固定）
 FlexibleHeight                高度弹性（保持上下边距固定）

 二、NSLayoutConstraint
 公式：view1.attr = view2.attr * multiplier + constant

 + (instancetype)constraintWithItem:(id)view1
                          attribute:(NSLayoutAttribute)attr1
                          relatedBy:(NSLayoutRelation)relation
                             toItem:(nullable id)view2
                          attribute:(NSLayoutAttribute)attr2
                         multiplier:(CGFloat)multiplier
                           constant:(CGFloat)c;

 注意事项：
 1. 添加约束前子视图必须已加入父视图
 2. 使用 AutoLayout 的视图必须设置 translatesAutoresizingMaskIntoConstraints = NO
 3. 两视图间的约束添加到共同父视图；仅涉及自身宽/高时 toItem 传 nil，attr2 传 NSLayoutAttributeNotAnAttribute
 4. 修改约束：remove 旧约束 + add 新约束，或直接修改 constraint.constant 并调用 layoutIfNeeded

 VFL 语法（Visual Format Language）
 H:|--[view(100@750)]--|    水平方向；| 父视图边缘，-- 间距，() 宽度，@ 优先级（1~1000，默认1000）
 V:|-20-[view(>=50)]-|      垂直方向；>= / <= 表示不等约束
 metrics: @{@"m":@20}       尺寸常量替换字典（key NSString，value NSNumber）
 views: NSDictionaryOfVariableBindings(view)   视图名映射字典

 三、translatesAutoresizingMaskIntoConstraints
 - 默认 YES：AutoresizingMask 自动转为约束，与手动约束冲突
 - 手动添加约束时必须设为 NO

 四、AutoLayout 与 Frame 混用
 - viewDidLoad 中直接读 frame 不可靠（布局尚未完成）
 - 需立即读 frame：添加约束后调用 [view layoutIfNeeded]
 - frame 赋值写在 viewDidLayoutSubviews / layoutSubviews 中最稳妥

 五、布局与重绘生命周期

 全局流程：updateConstraints → layoutSubviews → drawRect:
 ViewController：viewWillLayoutSubviews → layoutSubviews → viewDidLayoutSubviews

 方法                        作用
 setNeedsLayout              标记：下个 RunLoop 异步触发 layoutSubviews
 layoutIfNeeded              立即：有标记则同步执行 layoutSubviews
 layoutSubviews              执行：实际布局子视图（重写时必须调 super）
 setNeedsDisplay             标记：下个绘制周期异步触发 drawRect:
 setNeedsDisplayInRect:      标记：局部区域重绘
 drawRect:                   执行：自定义绘制，可获取 CGContext

 layoutSubviews 触发时机：
 - initWithFrame: 且 frame != CGRectZero（普通 init 不触发）
 - addSubview:
 - 自身 frame 发生变化
 - 子视图 frame 变化（触发父视图的 setNeedsLayout）
 - 滚动 UIScrollView
 - 旋转屏幕

 sizeToFit vs sizeThatFits:
 - sizeToFit：计算最优 size 并直接修改自身 frame.size
 - sizeThatFits:：只返回最优 size，不修改自身（适合外部读取后自行决定）

 六、约束更新相关 API
 API                           类型       作用
 setNeedsUpdateConstraints     调用方法    标记：下个周期异步执行 updateConstraints
 updateConstraintsIfNeeded     调用方法    立即：有标记则同步执行 updateConstraints
 needsUpdateConstraints        只读属性    查询：是否已被标记
 updateConstraints             重写方法    执行：重写约束更新逻辑，末尾必须调 [super updateConstraints]

 七、intrinsicContentSize
 - intrinsicContentSize：控件根据内容自适应的固有尺寸（UILabel/UIButton 等默认实现）
 - 自定义控件重写此方法返回期望尺寸，内容变化后调用 invalidateIntrinsicContentSize 通知系统重算
 - AutoLayout 利用此尺寸配合 CHCR 优先级决定最终布局

 八、抗拉伸 / 抗压缩优先级（CHCR）
 - ContentHuggingPriority（抗拉伸）：优先级越高越不容易被撑大，默认 250
 - ContentCompressionResistancePriority（抗压缩）：优先级越高越不容易被压缩，默认 750
 - 多控件空间不足/富余时，优先级低的先被压缩/拉伸
 用法：[label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal]

 九、UI 必须在主线程更新的原因
 1. UIKit 非线程安全：多线程并发修改同一 UI 元素会产生竞态条件，导致崩溃或状态错乱
 2. 渲染管线绑定主线程：Core Animation 的 Commit Transaction 由主线程 RunLoop 驱动，所有 CALayer 属性变更必须在主线程提交到渲染树

 十、Texture（AsyncDisplayKit）可在子线程布局的原因
 - Node 抽象层：ASDisplayNode 包装 UIView/CALayer，布局/渲染在子线程计算，
   仅最终结果在主线程提交给 CALayer.contents
 - 异步预合成：子线程解码图片、CoreText 绘制文本，生成位图缓存，避免主线程卡顿
 - CATransaction 批量提交：减少主线程 UI 提交次数
 - 最终 UI 更新仍严格在主线程，并未绕过 UIKit 线程安全限制
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
