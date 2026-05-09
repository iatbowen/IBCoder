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
 一、响应者链（Responder Chain）
 是 iOS 中用于处理事件响应和事件传递的一种机制，由一系列继承自 UIResponder 的对象组成链表结构，用于确定事件的传递路径和响应者的顺序。

 所有继承自 UIResponder 的对象都可以是响应者：UIView、UIViewController、UIWindow、UIApplication、AppDelegate
 每个响应者都有 nextResponder，形成一条链：UIView → 父 View（逐级）→ UIViewController → UIWindow → UIApplication → AppDelegate → nil

 二、事件分发完整流程

 硬件触摸
   → IOKit 捕获，封装为 IOHIDEvent
   → SpringBoard/WindowServer 分发到前台 App（Mach Port）
   → App 主线程 RunLoop source1 唤醒
   → UIApplication -sendEvent: → UIWindow -sendEvent:
   → Hit-Testing 找到 First Responder（最合适的 view）
   → 触发 touchesBegan:withEvent: 等回调
   → 若未处理 → 沿 Responder Chain 向上传递
   → UIApplication 兜底，仍未处理则丢弃

 为何用队列管理事件而非栈：队列先进先出，保证先产生的事件先处理。

 三、Hit-Testing：hitTest:withEvent:

 目的：自顶向下找到触摸点所在的最深层可响应 view（First Responder）

 步骤（每个 view 递归执行）：
   ① 前置检查（任一不满足返回 nil）
      userInteractionEnabled == YES
      hidden == NO
      alpha > 0.01
   ② pointInside:withEvent: 判断触摸点是否在自身 bounds 内，不在则返回 nil
   ③ 倒序遍历子视图（后添加的显示在前，优先检测）
      将触摸点转换到子视图坐标系，递归调用子视图的 hitTest:withEvent:
      有子视图返回非 nil → 直接返回该子视图
   ④ 所有子视图均返回 nil → 返回 self（自己就是最合适的响应者）

 四、响应者链事件传递规则

 事件从 First Responder 开始，沿 nextResponder 向上传递，直到被处理或丢弃：

   First Responder（最深层 view）
     ↓ 不处理（未重写 touches 方法，或调用了 [super touches...]）
   UIViewController（若该 view 由 VC 管理）
     ↓ 不处理
   父 View（逐级向上）
     ↓ 不处理
   UIWindow
     ↓ 不处理
   UIApplication
     ↓ 不处理
   AppDelegate
     ↓ 不处理
   事件丢弃

 注意：
 - 若 view 没有对应的 UIViewController，nextResponder 直接是父 view
 - 重写 touches 方法但不调用 super，事件在此中断，不再向上传递
 - 只调用 [super touches...]，事件继续向上传递

 五、常见应用场景

 1. 扩大点击热区
    重写 -pointInside:withEvent:，在 bounds 外围扩展判定区域（见 IBViewD）

 2. 子 view 超出父 view bounds 仍可响应
    父 view 重写 hitTest:withEvent:，手动检测超出区域的子 view

 3. ScrollView 留边分页滑动
    父 view 重写 hitTest:withEvent:，将留边区域的触摸事件也返回 scrollView，
    同时设置 scrollView.clipsToBounds = NO 展示侧边内容

 4. 事件穿透（透明区域不响应）
    重写 hitTest:withEvent:，特定区域返回 nil，让事件穿透到下层视图

 5. 全局事件监听
    子类化 UIApplication，重写 sendEvent: 拦截所有事件（如统计点击、防重复点击）
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
