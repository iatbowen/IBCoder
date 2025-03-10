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
#include "hermes/hermes.h"

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
    [self testQuickJS];
    [self testHermes];
}

- (void)testQuickJS {
//    [self testOriginCode];
//    [self testContextSmoke];
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


- (void)testHermes {
    auto config = hermes::vm::RuntimeConfig::Builder().build();
    std::unique_ptr<facebook::hermes::HermesRuntime> runtime = facebook::hermes::makeHermesRuntime(config);
    auto console = facebook::jsi::Object(*runtime);
    console.setProperty(*runtime,
                        "log",
                        facebook::jsi::Function::createFromHostFunction(*runtime,
                                                                        facebook::jsi::PropNameID::forAscii(*runtime, "log"),
                                                                        1,
                                                                        [](facebook::jsi::Runtime &rt,
                                                                           const facebook::jsi::Value &thisVal,
                                                                           const facebook::jsi::Value *args,
                                                                           size_t count) {
        NSMutableString *logStr = [NSMutableString new];
        for (size_t i = 0; i < count; ++i) {
            [logStr appendFormat:@"%@ ", [NSString stringWithUTF8String:args[i].toString(rt).utf8(rt).c_str()]];
        }
        NSLog(@"JS Log: %@", logStr);
        return facebook::jsi::Value::undefined();
    }
                                                                        ));
    runtime->global().setProperty(*runtime, "console", console);
    @try {
        // 1.0 log
        NSString *script = @"console.log('Hello from Hermes!');";
        auto jsBuffer = std::make_shared<facebook::jsi::StringBuffer>([script UTF8String]);
        runtime->evaluateJavaScript(jsBuffer, "script.js");
        // 2.0 加法
        NSString *addScript = @"(function() { return 2 + 3; })();";
        auto addJSBuffer = std::make_shared<facebook::jsi::StringBuffer>([addScript UTF8String]);
        facebook::jsi::Value result = runtime->evaluateJavaScript(addJSBuffer, "script.js");
        NSString *resultString = [NSString stringWithUTF8String:result.toString(*runtime).utf8(*runtime).c_str()];
        NSLog(@"JS Function: add result %@", resultString);
        
    } @catch (NSException *exception) {
        NSLog(@"JS Error: %@", exception);
    }
}

@end


/*
 一、cmake 介绍
 1、option
 1.1、-G 生成器选择
 -G "Ninja"             # 最快的构建系统
 -G "Xcode"             # 生成Xcode工程
 -G "Visual Studio 17 2022"  # VS2022项目
 
 1.2、-B/-S 路径控制
 -B build              # 指定构建目录
 -S src                # 指定源码目录（含CMakeLists.txt）
 
 1.3 -D 定义变量
 -DCMAKE_SYSTEM_NAME=iOS
 -DCMAKE_OSX_SYSROOT=iphoneos
 -DCMAKE_BUILD_TYPE=Release
 -DCMAKE_OSX_ARCHITECTURES=arm64
 -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0
 -DHERMES_BUILD_APPLE_FRAMEWORK=ON
 
 二、hermes 构建
 
 1、git clone https://github.com/facebook/hermes.git
 cd hermes
 
 2、编译 iOS 静态库
 ./utils/build-ios-framework.sh
 
 3、解决编译报错，修改 .mm 文件扩展名来表示Objective-C++
 
 4、修改Header Search Path
 
 */
