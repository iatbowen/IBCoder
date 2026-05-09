//
//  IBController9.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/3.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController9.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface Doctor: NSObject

@end

@implementation Doctor

- (void)eat {
    NSLog(@"%s",__func__);
}

- (void)sleep {
    NSLog(@"%s",__func__);
}

- (void)walk {
    NSLog(@"%s",__func__);
}


@end

@interface IBController9 ()

@end

/**
 一、objc_msgSend 整体流程
 [obj method] → objc_msgSend(obj, @selector(method))

 阶段 1：消息发送（Message Send）
   ① isa → 找到所属类
   ② 查方法缓存 cache_t（哈希表，命中则直接调用）
   ③ 未命中 → 遍历 class_rw_t 方法列表（已排序二分查找，否则线性遍历）
   ④ 找到 → 写入缓存 → 调用
   ⑤ 未找到 → superClass 逐级向上重复 ②③
   ⑥ 到 NSObject 仍未找到 → 进入动态解析
        |
 阶段 2：动态方法解析（Dynamic Method Resolution）
   ① 调用 +resolveInstanceMethod: / +resolveClassMethod:
   ② 可用 class_addMethod 动态添加 IMP
   ③ 添加成功 → 标记已解析 → 重新走消息发送流程
   ④ 未添加 → 标记已解析（防止死循环）→ 进入消息转发
        |
 阶段 3：消息转发（Message Forwarding）
   ① 快速转发：-forwardingTargetForSelector:
      返回非 nil 对象 → objc_msgSend(新对象, SEL)
   ② 完整转发：-methodSignatureForSelector: 返回方法签名
      → -forwardInvocation:（NSInvocation 封装 target/SEL/参数/返回值）
      可任意转发给其他对象或修改参数
   ③ 签名返回 nil → 直接崩溃
        |
 阶段 4：抛出异常 -doesNotRecognizeSelector: → crash

 二、关键 API 说明

 class_addMethod(Class cls, SEL sel, IMP imp, const char *types)
   types 类型编码：v=void  @=id  :=SEL  *=char*  i=int  d=double  B=BOOL
   示例："v@:*" → 返回 void，参数为 (id self, SEL _cmd, char *str)
   注意：只在方法不存在时才添加；已存在用 class_replaceMethod

 快速转发 vs 完整转发：
   快速转发：只能换 target，无法修改参数/返回值，开销小
   完整转发：可修改参数、合并多消息、记录日志等，开销大
   两者均未处理才走 doesNotRecognizeSelector:

 源码路径（objc4）：
 objc-msg-arm64.s
 ENTRY _objc_msgSend
 b.le    LNilOrTagged
 CacheLookup NORMAL
 .macro CacheLookup
 .macro CheckMiss
 STATIC_ENTRY __objc_msgSend_uncached
 .macro MethodTableLookup
 _class_lookupMethodAndLoadCache3

 objc-runtime-new.mm
 _class_lookupMethodAndLoadCache3
 lookUpImpOrForward
 getMethodNoSuper_nolock、search_method_list_inline（已排序方法二分查找，否则遍历查找 ）、log_and_fill_cache
 log_and_fill_cache、cache_fill
 _class_resolveInstanceMethod
 _objc_msgForward_impcache

 objc-msg-arm64.s
 STATIC_ENTRY __objc_msgForward_impcache
 ENTRY __objc_msgForward

 Core Foundation
 __forwarding__（不开源）
 */

@implementation IBController9


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self performSelector:@selector(run:) withObject:@"haha"];
    [self performSelector:@selector(eat) withObject:@"hehe"];
    [self performSelector:@selector(sleep) withObject:@"heihei"];
    [self performSelector:@selector(walk) withObject:@"heihei"];

}

#pragma mark - 动态方法解析

+ (BOOL)resolveInstanceMethod:(SEL)sel{
    NSLog(@"resolveInstanceMethod = %@",NSStringFromSelector(sel));
    //判断没有实现方法, 那么我们就是动态添加一个方法
    if (sel == @selector(run:)) {
        class_addMethod(self, sel, (IMP)newRun, "v@:*");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
//函数
void newRun(id self,SEL sel,NSString *str) {
    NSLog(@"---%s---%@",__func__,str);
}

/**
+ (BOOL)resolveInstanceMethod:(SEL)sel{
    NSLog(@"resolveInstanceMethod = %@",NSStringFromSelector(sel));
    //判断没有实现方法, 那么我们就是动态添加一个方法
    if (sel == @selector(run:)) {
        Method method = class_getClassMethod(self, @selector(newRun:));
        class_addMethod(self,
                        sel,
                        method_getImplementation(method),
                        method_getTypeEncoding(method));
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
 - (void)newRun:(NSString *)str {
     NSLog(@"---%s---%@",__func__,str);
 }

*/


#pragma mark - 快速消息转发
- (id)forwardingTargetForSelector:(SEL)aSelector{
    NSLog(@"forwardingTargetForSelector = %@",NSStringFromSelector(aSelector));
    if (aSelector == @selector(eat)) {
        return [[Doctor alloc] init];
    }
    return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - 完整消息转发

//方法签名
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector OBJC_SWIFT_UNAVAILABLE(""){
    //转化字符
    NSString *sel = NSStringFromSelector(aSelector);
    //判断, 手动生成签名
    if([sel isEqualToString:@"sleep"]){
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
//        return [[[Doctor alloc] init] methodSignatureForSelector:@selector(sleep)];
    }else{
        return [super methodSignatureForSelector:aSelector];
    }
}

//拿到方法签名配发消息
- (void)forwardInvocation:(NSInvocation *)anInvocation OBJC_SWIFT_UNAVAILABLE(""){
    NSLog(@"forwardInvocation---%@---",anInvocation);
    //取到消息
    SEL seletor = [anInvocation selector];
    //转发
    Doctor *doctor = [[Doctor alloc] init];
    if([doctor respondsToSelector:seletor]){
        //调用对象,进行转发
        [anInvocation invokeWithTarget:doctor];
    }else{
        return [super forwardInvocation:anInvocation];
    }
}
//抛出异常
- (void)doesNotRecognizeSelector:(SEL)aSelector{
    NSString *selStr = NSStringFromSelector(aSelector);
    NSLog(@"%@不存在",selStr);
}

@end
