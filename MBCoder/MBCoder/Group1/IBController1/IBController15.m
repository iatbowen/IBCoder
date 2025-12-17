//
//  IBController15.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/8.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController15.h"
#import "Calculate.h"
#import "BProxy.h"
#import "YYWeakProxy.h"

/*
 一、NSProxy
 1、定义
 NSProxy 是 Foundation 框架中的一个抽象基类，专门用于消息转发和代理实现。
 2、常用场景：
 弱引用代理（防止循环引用）、多重委托（消息多播）、日志、统计、权限拦截（AOP/切面编程）、保护性代理（访问控制）
 
 例1：弱引用代理
 @interface WeakProxy : NSProxy
 @property (nonatomic, weak, readonly) id target;
 @end

 @implementation WeakProxy

 - (instancetype)initWithTarget:(id)target {
     _target = target;
     return self;
 }

 + (instancetype)proxyWithTarget:(id)target {
     return [[self alloc] initWithTarget:target];
 }

 - (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
     return [self.target methodSignatureForSelector:sel];
 }

 - (void)forwardInvocation:(NSInvocation *)invocation {
     if (self.target) {
         [invocation invokeWithTarget:self.target];
     }
 }

 - (BOOL)respondsToSelector:(SEL)aSelector {
     return [self.target respondsToSelector:aSelector];
 }

 @end

 // 使用示例 - NSTimer防止循环引用
 @interface ViewController : UIViewController
 @property (nonatomic, strong) NSTimer *timer;
 @end

 @implementation ViewController

 - (void)viewDidLoad {
     [super viewDidLoad];
     
     // 使用弱代理防止循环引用
     WeakProxy *weakProxy = [WeakProxy proxyWithTarget:self];
     self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                   target:weakProxy
                                                 selector:@selector(timerAction)
                                                 userInfo:nil
                                                  repeats:YES];
 }

 - (void)timerAction {
     NSLog(@"Timer fired");
 }

 @end

 
 例2：多重委托（消息多播）
 @interface MulticastProxy : NSProxy
 @property (nonatomic, strong) NSArray *targets;
 - (instancetype)initWithTargets:(NSArray *)targets;
 @end

 @implementation MulticastProxy
 - (instancetype)initWithTargets:(NSArray *)targets { _targets = targets; return self; }
 - (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
     for (id target in _targets) {
         if ([target respondsToSelector:sel]) {
             return [target methodSignatureForSelector:sel];
         }
     }
     return [NSObject instanceMethodSignatureForSelector:@selector(init)];
 }
 - (void)forwardInvocation:(NSInvocation *)invocation {
     for (id target in _targets) {
         if ([target respondsToSelector:invocation.selector]) {
             [invocation invokeWithTarget:target];
         }
     }
 }
 @end
 
 例3：AOP (面向切面编程)
 @interface AOPProxy : NSProxy
 @property (nonatomic, strong) id target;
 @property (nonatomic, copy) void(^beforeBlock)(NSInvocation *invocation);
 @property (nonatomic, copy) void(^afterBlock)(NSInvocation *invocation, id result);
 @end

 @implementation AOPProxy

 - (instancetype)initWithTarget:(id)target {
     self.target = target;
     return self;
 }

 - (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
     return [self.target methodSignatureForSelector:sel];
 }

 - (void)forwardInvocation:(NSInvocation *)invocation {
     // 前置通知
     if (self.beforeBlock) {
         self.beforeBlock(invocation);
     }
     
     // 执行原方法
     [invocation invokeWithTarget:self.target];
     
     // 获取返回值
     id result = nil;
     if (invocation.methodSignature.methodReturnLength > 0) {
         [invocation getReturnValue:&result];
     }
     
     // 后置通知
     if (self.afterBlock) {
         self.afterBlock(invocation, result);
     }
 }

 @end
 
 
 例4：保护性代理（访问控制）
 @interface ProtectionProxy : NSProxy
 @property (nonatomic, strong) id target;
 @property (nonatomic, strong) NSSet *allowedSelectors;
 @property (nonatomic, copy) BOOL(^authenticationBlock)(SEL selector);
 @end

 @implementation ProtectionProxy

 - (BOOL)hasPermissionForSelector:(SEL)selector {
     if (self.authenticationBlock) {
         return self.authenticationBlock(selector);
     }
     return [self.allowedSelectors containsObject:NSStringFromSelector(selector)];
 }

 - (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
     if ([self hasPermissionForSelector:sel]) {
         return [self.target methodSignatureForSelector:sel];
     }
     return [super methodSignatureForSelector:sel];
 }

 - (void)forwardInvocation:(NSInvocation *)invocation {
     if ([self hasPermissionForSelector:invocation.selector]) {
         [invocation invokeWithTarget:self.target];
     } else {
         NSLog(@"访问被拒绝: %@", NSStringFromSelector(invocation.selector));
     }
 }

 @end

 */

@interface IBController15 ()

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation IBController15

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    test1();
    test2();
    [self test3];
}

void test1 () {
    Calculate *cal = [[Calculate alloc] init];
    [cal add];
    [cal add1];
}

void test2() {
    BProxy *proxy = [BProxy proxy];
    [proxy purchaseBookWithTitle:@"上衣"];
    [proxy purchaseClothesWithSize:BClothesSizeLarge];
}

- (void)test3 {
    self.timer = [NSTimer timerWithTimeInterval:1
                                         target:[YYWeakProxy proxyWithTarget:self]
                                       selector:@selector(timerInvoked:)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];

}

- (void)timerInvoked:(NSTimer *)timer{
    NSLog(@"1");
}
- (void)dealloc
{
    NSLog(@"%s",__func__);
}

@end
