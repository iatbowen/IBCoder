//
//  IBController11.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/8.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController11.h"
#import "UIView+Ext.h"

/*
 ============================================================
 事件传递与响应 面试题总结
 ============================================================


 一、核心概念

 UIResponder：UIView / UIViewController / UIWindow / UIApplication / AppDelegate

 响应者链：nextResponder 串成的单向链表，事件向上冒泡时使用
 View → superview → (root view 则 VC) → … → Window → Application → AppDelegate → nil

 First Responder：
 - 触摸 FR：Hit-Test 命中的最深层 view
 - 键盘 FR：becomeFirstResponder 成功对象（如 UITextField），与触摸 FR 可不同

 两个方向（必考）：
 - 事件传递：自顶向下 Hit-Testing，touch 开始时只一次，定「谁收」
 - 事件响应：自底向上沿响应者链冒泡，定「不处理时交给谁」，通过在 touches 四个方法里调 [super] 手动驱动的，调则冒泡，不调则截断

 二、完整事件流程（从硬件到回调）

 触摸屏 → IOKit → WindowServer(Mach Port) → 主线程 RunLoop Source1 唤醒
 → UIApplication sendEvent: → UIWindow sendEvent:
 → Hit-Testing（自顶向下 hitTest:）→ 得到 hitView
 → 并行分发同一 UIEvent：
     ① hitView 及父链上的 UIGestureRecognizer 识别
     ② hitView 的 touchesBegan / Moved / Ended（可被 delaysTouchesBegan 推迟）
 → touches 调 super → 沿响应者链向上冒泡


 三、Hit-Testing（hitTest:withEvent:）

 ① 前置：userInteractionEnabled && !hidden && alpha>0.01，否则 nil
 ② pointInside:withEvent:（默认 bounds 内；IBViewD 可扩大热区）
 ③ 倒序遍历 subviews，convertPoint:toView: 后递归子 view hitTest
 ④ 子 view 均 nil → return self

 四、四种事件处理路径（关系总览）

 四者不是独立模块，是同一次 touch 的四个阶段/分支。
 Hit-Test 决定事件交给谁；后三者围绕 hitView 并行展开。

        手指按下
            ↓
     Hit-Test（向下，一次）→ hitView
            ↓ 同一 UIEvent 并行分发
     ┌──────┼──────────┐
     ↓      ↓          ↓
  touches  GestureRecognizer  UIControl
  原始流    识别序列语义      内部 tracking
  可冒泡    不冒泡           不冒泡

 Hit-Test：系统自顶向下调 hitTest:，找最深的 view，无业务回调，手势成功后不再重新 Hit-Test。

 touches：原始坐标流，每相位（Began/Moved/Ended）发给 hitView；
   调 [super touches...] 才向上冒泡；只有坐标，无语义。

 GestureRecognizer：与 touches 并行识别序列语义（单击/滑动）；
   识别成功调 action（参数 GestureRecognizer*），不走响应者链；
   cancelsTouchesInView=YES（默认）→ hitView 收 touchesCancelled，无 Ended。

 UIControl：hitView 是 UIControl 时走此路；内部 beginTracking→endTracking→发 ControlEvent；
   不走你的 touchesBegan；superview 重写 touchesBegan 收不到 Button 点击。

 三种场景时序
 · 普通 UIView（无手势）：  按下→Hit-Test→touchesBegan→[super冒泡]→touchesEnded
 · UIView 挂 Tap 手势：    按下→Hit-Test→Tap:Possible+touchesBegan→识别成功→onTap:+touchesCancelled
 · UIButton：              按下→Hit-Test→TouchDown→TouchUpInside→onClick

 关键属性（手势影响 touches）
 · cancelsTouchesInView=YES — 手势成功 cancel touches（默认）
 · cancelsTouchesInView=NO  — 两者共存，ScrollView 内按钮常设此项
 · delaysTouchesBegan       — 推迟 touchesBegan，优先让手势判定

 UIButton vs UIGestureRecognizer 优先级与冲突
 手势优先级更高，但结果取决于手势挂在哪里。

 典型冲突：手势挂在 Button 的 superview 上
   Hit-Test → hitView = UIButton
   并行：SuperView.TapGesture Possible + UIButton TouchDown
   手指抬起 → TapGesture 识别成功 → onTap: 触发
   cancelsTouchesInView=YES → UIButton 收 touchesCancelled → TouchUpInside 不触发

 解决方法：
 ① cancelsTouchesInView=NO — 手势与 Button 都触发，需自行处理重复响应
 ② delegate shouldReceiveTouch:（推荐）— 点到 UIControl 时让手势放行：
      - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gr shouldReceiveTouch:(UITouch *)touch {
          return ![touch.view isKindOfClass:[UIControl class]];
      }


 五、常见应用场景

 1. 扩大热区 — IBViewD 重写 pointInside:
 2. 子 view 超出父 bounds — 父 view 重写 pointInside/hitTest，或 clipsToBounds=NO
 3. ScrollView 留边分页 — 父 view hitTest 把留边交给 scrollView
 4. 事件穿透 — hitTest 某区域 return nil
 5. 全局监听 — 子类 UIApplication 重写 sendEvent:
 6. 调试链 — IBViewD touchesBegan 遍历 nextResponder


 六、常见面试问答

 Q：Hit-Testing 和响应者链方向？
 A：Hit-Test 向下找 FR；响应者链从 FR 向上 nextResponder 冒泡。

 Q：Hit-Test、touches、手势、Target-Action 关系？
 A：Hit-Test 定 hitView → 并行：手势识别+手势 target-action / touches 回调+可选 super 冒泡；
    UIControl 走内部 tracking→TouchUpInside→控件 target-action。

 Q：手势识别后还向下传吗？
 A：不会。不再 Hit-Test；默认 cancel hitView 的 touches，手势不走响应者链。

 Q：superview userInteractionEnabled=NO？
 A：不参与 hitTest，整棵子树收不到触摸。

 Q：touchesEnded 没来？
 A：手势 cancel、ScrollView pan、view 被 remove 等。

 Q：UIButton vs UIView touchesBegan？
 A：Button 走 UIControl；UIView 走 touches 或挂手势。

 Q：A→B→C，手势加在 B（或 C）上，C 是 UIControl，点击后 TouchUpInside 为何不触发？如何解决？
 A：Hit-Test 与手势无关，照常递归到 C（hitView = C）。
    但手势优先级高于 UIControl：C 先收到 TouchDown，手势识别成功后系统强制给 C 发 touchesCancelled，
    UIControl tracking 被打断，TouchUpInside 不触发（有 Began 无 Ended）——无论手势挂在 B 还是 C 结论相同。
    解决：
    · 手势在父 view → delegate shouldReceiveTouch: 判断 touch.view isKindOfClass:[UIControl class] 让手势放行
    · 手势在 C 自身 → cancelsTouchesInView=NO，或直接不加手势（UIControl 自带事件已够用）

 Q：两种 FR 区别？
 A：触摸 FR 由 Hit-Test 定；键盘 FR 由 becomeFirstResponder 定。
 */
@interface IBViewA : UIView

@end

@implementation IBViewA

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor redColor];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s",__func__);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"%s",__func__);

    // 1.判断下自己能否接收事件
    if (self.userInteractionEnabled == NO || self.hidden == YES || self.alpha <= 0.01) return nil;
    
    // 2.判断下点在不在当前控件上
    if ([self pointInside:point withEvent:event] == NO) return  nil; // 点不在当前控件
    
    // 3.从后往前遍历自己的子控件，UIKit 中后添加的视图显示在前面，应优先检测
    int count = (int)self.subviews.count;
    for (int i = count - 1; i >= 0; i--) {
        // 获取子控件
        UIView *childView = self.subviews[i];
        
        // 把当前坐标系上的点转换成子控件上的点
        CGPoint childP =  [self convertPoint:point toView:childView];
        
        UIView *hitView = [childView hitTest:childP withEvent:event];
        
        if (hitView) {
            return hitView;
        }
        
    }
    // 4.如果没有比自己合适的子控件,最合适的view就是自己
    return self;
}

//此方法内使用bouds判断是否在本视图范围内
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"%s",__func__);
    
    return CGRectContainsPoint(self.bounds, point);
}

@end

@interface IBViewB : UIView

@end

@implementation IBViewB

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor orangeColor];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s",__func__);
}

@end

@interface IBViewC : UIView

@end

@implementation IBViewC

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s",__func__);
}

@end


@interface IBViewD : UIView

@end

@implementation IBViewD

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor purpleColor];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UIResponder *next = self; next; next = [next nextResponder]) {
        NSLog(@"响应者——>%@", next.class);
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"%s",__func__);
    return [super hitTest:point withEvent:event];
}
//扩大响应范围
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    CGRect rect = CGRectMake(self.bounds.origin.x - 100, self.bounds.origin.y, self.width + 200, self.height);
    return CGRectContainsPoint(rect, point);
}

@end


@interface IBController11 ()

@end

@implementation IBController11

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    IBViewA *viewA = [[IBViewA alloc] initWithFrame:CGRectMake(20, 100, self.view.width - 40, 300)];
    [self.view addSubview:viewA];
    IBViewB *viewB = [[IBViewB alloc] initWithFrame:CGRectMake(20, 50, viewA.width - 40, 200)];
    [viewA addSubview:viewB];
    IBViewC *viewC = [[IBViewC alloc] initWithFrame:CGRectMake(20, 50, viewB.width - 40, 100)];
    [viewB addSubview:viewC];
//    viewB.userInteractionEnabled = NO;
    
    IBViewD *viewD = [[IBViewD alloc] initWithFrame:CGRectMake(100, 500, self.view.width - 200, 80)];
    [self.view addSubview:viewD];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s",__func__);
}

@end
