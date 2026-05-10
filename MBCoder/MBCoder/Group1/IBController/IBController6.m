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

 十一、Safe Area
 - safeAreaInsets：表示视图被系统遮挡的安全区域（状态栏、Home Indicator、刘海、工具栏等）
 - safeAreaLayoutGuide：Auto Layout 锚点版本，优先使用 guide 而非硬编码 insets
 - 读取时机：viewSafeAreaInsetsDidChange / viewDidLayoutSubviews，viewDidLoad 中为零
 - additionalSafeAreaInsets：自定义追加的安全区域（如导航栏自定义高度）
 - iOS 11 以前用 topLayoutGuide / bottomLayoutGuide，11+ 统一迁移到 safeAreaLayoutGuide

 十二、UIStackView
 - 沿主轴（axis）自动排列子视图，无需手动添加大量约束
 - 核心属性：
   axis            UILayoutConstraintAxisHorizontal / Vertical
   distribution    Fill / FillEqually / FillProportionally / EqualSpacing / EqualCentering
   alignment       Fill / Leading / Center / Trailing / FirstBaseline / LastBaseline
   spacing         子视图间距（可配合 setCustomSpacing:afterView: 单独设置）
 - 动态增删子视图：addArrangedSubview: / removeArrangedSubview: + removeFromSuperview
   隐藏子视图（hidden = YES）会自动折叠，不占用空间
 - 嵌套 StackView：水平+垂直嵌套可替代复杂约束
 - 注意：arrangedSubviews ≠ subviews，直接 addSubview: 不会参与排列

 十三、约束冲突与歧义
 冲突（Unsatisfiable Constraints）
 - 两条约束互相矛盾（如 width = 100 且 width = 200）
 - 运行时会打印 "Unable to simultaneously satisfy constraints"，系统随机 break 一条
 - 解决：降低其中一条优先级（< 1000）使系统可打破，或检查约束逻辑

 歧义（Ambiguous Layout）
 - 约束不足，无法唯一确定视图的位置或尺寸
 - 调试：view.hasAmbiguousLayout / [view exerciseAmbiguityInLayout]
   lldb: po [[UIWindow keyWindow] _autolayoutTrace]

 优先级常量（UILayoutPriority）
 UILayoutPriorityRequired             = 1000（不可 break，不能用于动画）
 UILayoutPriorityDefaultHigh          = 750
 UILayoutPriorityDefaultLow           = 250
 UILayoutPriorityFittingSizeLevel     = 50
 建议动画约束优先级设为 999，避免打断 Required 约束报错

 十四、UIScrollView + Auto Layout
 - UIScrollView 的 contentSize 由内部子视图约束自动推算，不能直接写 frame
 - 正确做法：将所有子视图约束到 ScrollView 的 contentLayoutGuide，
   同时通过 frameLayoutGuide 约束内容宽度（防止水平滚动）：
   [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]
 - iOS 11+ 推荐使用 contentLayoutGuide / frameLayoutGuide，iOS 11 以前需手动设 contentSize
 - 常见坑：忘记设 translatesAutoresizingMaskIntoConstraints = NO，或内部视图约束不完整导致 contentSize = 0

 ============================================================
 十五、常见面试问答
 ============================================================

 Q：layoutSubviews 和 drawRect: 的区别？
 A：layoutSubviews 负责计算并设置子视图 frame，由 Auto Layout 引擎或 setNeedsLayout 触发；
    drawRect: 负责自定义 CoreGraphics 绘制内容，由 setNeedsDisplay 触发。
    二者触发时机独立，layoutSubviews 先执行，drawRect: 后执行。

 Q：setNeedsLayout 和 layoutIfNeeded 的区别？
 A：setNeedsLayout 只标记"脏"，等待下个 RunLoop 批量执行；
    layoutIfNeeded 立即检查标记，有则同步执行 layoutSubviews。
    动画约束变化时通常写法：[UIView animateWithDuration:0.3 animations:^{ [self.view layoutIfNeeded]; }]

 Q：Auto Layout 和 Frame 性能对比？
 A：Auto Layout 底层使用 Cassowary 线性规划算法求解约束，约束数量越多求解越慢。
    简单界面两者性能接近；复杂深层嵌套（如列表 Cell）Auto Layout 可能成为瓶颈。
    优化：减少约束数量、避免动态增删约束、使用 UIStackView 替代多余约束。

 Q：intrinsicContentSize 的工作原理？
 A：UILabel/UIButton 等控件根据内容计算"最适合"的尺寸并通过 intrinsicContentSize 返回。
    Auto Layout 将此尺寸转化为两对约束（宽/高），优先级由 CHCR 控制（抗拉伸默认 250，抗压缩默认 750）。
    自定义控件重写此方法，内容变更后调用 invalidateIntrinsicContentSize 触发重算。

 Q：Safe Area 与 topLayoutGuide 的区别？
 A：topLayoutGuide 是 iOS 7 引入的对导航栏/状态栏的适配，iOS 11 废弃。
    safeAreaLayoutGuide 覆盖所有系统 UI 遮挡区域（刘海、Home Indicator、状态栏、工具栏），
    且支持 additionalSafeAreaInsets 自定义扩展，更通用，应统一迁移到 safeAreaLayoutGuide。

 Q：UIScrollView 设置 Auto Layout 后 contentSize 为 0 的原因？
 A：未将子视图四边完整约束到 contentLayoutGuide，导致系统无法推算内容尺寸。
    另一个常见原因是忘记给内容容器视图约束宽度（与 frameLayoutGuide 宽度相等），
    导致内容视图宽度歧义，contentSize.width 推算为 0。
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
