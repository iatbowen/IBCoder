//
//  IBGroup2Controller30.m
//  MBCoder
//
//  Created by 叶修 on 2024/10/21.
//  Copyright © 2024 inke. All rights reserved.
//

#import "IBGroup2Controller30.h"
#import "QJSRuntime.h"
#import "QJSContext.h"
#include "quickjs-libc.h"

@interface TestObject : NSObject<QJSValueObject>

@end

@implementation TestObject

- (void)dealloc {
    NSLog(@"TestObject dealloc");
}

- (NSArray *)test:(NSNumber *)a :(NSString *)b :(NSNumber *)c :(NSString *)d {
    NSLog(@"%@ %@ %@ %@", a, b, c, d);
    return @[@"a", @NO, @(123), d];
}

- (NSDictionary *)objectMap {
    return @{@"testkey": @"testKey from objectMap"};
}

@end

@protocol TestProtocol<NSObject>

- (id)javascriptAddFunc:(id)arg1 :(id)arg2 :(id)arg3;

@end


@interface IBGroup2Controller30 ()

@end

@implementation IBGroup2Controller30

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
//    [self testOriginCode];
    [self testContextSmoke];
//    [self testQJSContext_Block];
//    [self testQJSValueInterface];
//    [self testContext_methodInvoke];
}

- (void)testOriginCode {
    JSRuntime *rt = JS_NewRuntime();
    JSContext *ctx = JS_NewContext(rt);
    // 日志
    js_std_add_helpers(ctx, 0, NULL);
    // 系统模块
    js_init_module_std(ctx, "std");
    js_init_module_os(ctx, "os");
    // 执行
    const char *scripts = "console.log('hello quickjs')";
    JS_Eval(ctx, scripts, strlen(scripts), "main", 0);
    
}

- (void)testContextSmoke {
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    QJSContext *context = [runtime newContext];

    QJSValue *retValue = [context eval:@"console.log(fetch);"];
    if ([retValue isException]) {
        NSLog(@"%@", [context popException].exception);
    }
    retValue = [context eval:@"var x = {a:1, b:2};console.log(JSON.stringify(x));x;"];
    NSLog(@"%@", retValue.objValue);
}

- (void)testQJSValueInterface {
    @autoreleasepool {
        QJSRuntime *runtime = [[QJSRuntime alloc] init];
        QJSContext *context = [runtime newContext];
        QJSValue *destObject =
            [context eval:@"var a = {javascriptAddFunc: function(a, b, c){console.log(c);return a * 10 + b;}}; a;"];
        id<TestProtocol> obj = [destObject asProtocol:@protocol(TestProtocol)];
        id retValue = [obj javascriptAddFunc:@(1):@(2):nil];
        NSLog(@"%@", retValue);
    }
}

- (void)testContext_methodInvoke {
    TestObject *obj = [TestObject new];
    @autoreleasepool {
        QJSRuntime *runtime = [[QJSRuntime alloc] init];
        QJSContext *context = [runtime newContext];
        QJSValue *globalValue = [context getGlobalValue];
        [globalValue setObject:obj forKey:@"testval"];
        [context eval:@"console.log(testval.testkey);"];
        [context eval:@"testval.test(1, 'a', false, testval.testkey);"];
        QJSValue *res = [context eval:@"testval(123);"];
        NSLog(@"%d", [res isException]);
        QJSException e = [context popException];
        NSLog(@"%@", e.exception);
    }
}

- (void)testQJSContext_Block {
    dispatch_block_t_2 blk = ^id(NSNumber *a, NSNumber *b) {
        return @(a.integerValue * 10 + b.integerValue);
    };
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    QJSContext *context = [runtime newContext];
    QJSValue *globalValue = [context getGlobalValue];
    [globalValue setObject:blk forKey:@"objcAdd"];
    [context eval:@"var a=objcAdd(2,3);console.log(a);"];
    QJSValue *retValue = [context eval:@"objcAdd(1,3)"];
    NSLog(@"%@", retValue.objValue);
}

@end
