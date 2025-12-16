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
 一、响应者链（Responder Chain）是 iOS 中用于处理事件响应和事件传递的一种机制。由一系列的响应者对象组成的链表结构，这些对象都是继承自 UIResponder 类，用于确定事件的传递路径和响应者的顺序
 
 二、事件分发（Event Delivery）
 
 完整的事件处理流程
 
 1. 硬件事件产生
     ↓
 2. IOKit捕获事件
     ↓
 3. WindowServer/SpringBoard处理，分发到前台App
     ↓
 4. App进程通过RunLoop接收事件
     ↓
 5. UIApplication.sendEvent:被调用
     ↓
 6. UIWindow.sendEvent:被调用
     ↓
 7. Hit-Testing（查找First Responder，UIViewController -> UIView -> 子View）
     ↓
 8. First Responder触发响应方法（touchesBegan:withEvent:等）
     ↓
 9. 事件未被处理，沿Responder Chain向上传递，直到被处理
     ↓
 10. UIApplication作为兜底处理者

 三、hitTest:withEvent:方法的处理流程如下
 
 - 判断自身能否响应事件
   如果 view 不能响应，则立即返回 nil，不再继续后续的子视图判断。
   前置条件为：
     用户交互是否开启 (userInteractionEnabled == YES)
     是否可见 (hidden == NO)
     透明度是否足够高 (alpha > 0.01)
 
 - 判断触摸点是否在自身
   使用 pointInside:withEvent: 方法做判断。如果不在，返回 nil。
 
 - 对子视图递归检查
 遍历所有子视图（倒序，先最上层显示的视图），将事件的 point 转换到当前子视图的坐标系，再调用子视图的 hitTest:withEvent:。
 如果其中有子视图返回非 nil，则返回该子视图。
 
 - 如果没有任何子视图响应，自己就是响应者
 若全部子视图都返回 nil，就返回自己（即当前 view）。
 
 四、说明
 1、如果最终hit-test没有找到第一响应者，或者第一响应者没有处理该事件，则该事件会沿着响应者链向上回溯，如果UIWindow实例和UIApplication实例都不能处理该事件，则该事件会被丢弃；
 
 注意:为什么用队列管理事件,而不用栈？
 队列先进先出,能保证先产生的事件先处理。栈先进后出。
 
 五、应用
 1、扩大UIButton的响应热区
 重载UIButton的-(BOOL)pointInside: withEvent:方法，让Point即使落在Button的Frame外围也返回YES
 2、子view超出了父view的bounds响应事件
 
 3、ScrollView page滑动
 如果想让边侧留出的距离响应滑动事件的话应该怎么办呢？在scrollview的父view中把蓝色部分的事件都传递给scrollView就可以了
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
