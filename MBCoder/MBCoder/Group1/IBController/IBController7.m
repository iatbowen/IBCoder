//
//  IBController7.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/2.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController7.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface IBController7 ()

@end

@implementation IBController7

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self test];
}

- (void)test {
    // 1. 加载 Wasm 文件
    NSURL *wasmURL = [[NSBundle mainBundle] URLForResource:@"math" withExtension:@"wasm"];
    NSData *wasmData = [NSData dataWithContentsOfURL:wasmURL];
    
    // 2. 创建 JSContext
    JSContext *context = [[JSContext alloc] init];
    context.exceptionHandler = ^(JSContext *ctx, JSValue *exception) {
        NSLog(@"JS 异常: %@", exception);
    };
    
    // 3.判断环境是否支持
    if ([context evaluateScript:@"typeof WebAssembly === 'undefined'"].toBool) {
        NSLog(@"WebAssembly is not supported in this JavaScriptCore context.");
        return;
    }
    
    // 4. 将 NSData 转换为 JavaScript 的 Uint8Array
    JSValue *uint8Array = [self convertNSDataToUint8Array:wasmData inContext:context];
    
    // 5. 定义 JavaScript 代码（使用 Promise 异步加载 Wasm）
    NSString *jsCode =
    @"async function loadWasm(bytes) {"
    "       const module = await WebAssembly.compile(bytes);"
    "       const instance = await WebAssembly.instantiate(module);"
    "       return instance;"
    "}";
    [context evaluateScript:jsCode];
    
    // 6. 调用 JavaScript 函数加载 Wasm
    JSValue *loadWasmFunc = context[@"loadWasm"];
    JSValue *promise = [loadWasmFunc callWithArguments:@[uint8Array]];
    
    // 7. 处理 Promise 的 then/catch
    [promise invokeMethod:@"then" withArguments:@[^(JSValue *instance) {
        // 成功：调用 add 函数
        JSValue *addFunc = instance[@"exports"][@"add"];
        if (!addFunc.isUndefined) {
            JSValue *result = [addFunc callWithArguments:@[@(5), @(3)]];
            NSLog(@"5 + 3 = %d", [result toInt32]); // 输出 8
        } else {
            NSLog(@"错误: add 函数未导出");
        }
    }]];
    
    [promise invokeMethod:@"catch" withArguments:@[^(JSValue *error) {
        NSLog(@"wasm 加载失败: %@", error);
    }]];
    
}


#pragma mark - 辅助方法

// 将 NSData 转换为 Uint8Array
- (JSValue *)convertNSDataToUint8Array:(NSData *)data inContext:(JSContext *)context {
    JSValue *arrayBuffer = [context[@"ArrayBuffer"] constructWithArguments:@[@(data.length)]];
    JSValue *uint8Array = [context[@"Uint8Array"] constructWithArguments:@[arrayBuffer]];
    
    uint8_t *bytes = (uint8_t *)data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        uint8Array[i] = [JSValue valueWithInt32:bytes[i] inContext:context];
    }
    return uint8Array;
}

@end

/**
 一， WebAssembly
 WebAssembly (Wasm) 是一种二进制指令格式，用于在现代 Web 浏览器中运行高性能应用程序。它是一种低级编程语言，类似于汇编语言，设计用于在各种平台上高效执行。
 WebAssembly 允许开发者使用多种编程语言（如 C、C++、Rust 等）编写代码，并将其编译为 WebAssembly 格式，以便在浏览器中运行。
 
 1、环境安装
 1.1 安装 Emscripten（需提前安装 Python、Node.js）
 git clone https://github.com/emscripten-core/emsdk.git
 cd emsdk
 ./emsdk install latest
 ./emsdk activate latest
 source ./emsdk_env.sh
 
 1.2 编译为WebAssembly
 使用Emscripten编译C代码：
 emcc math.c -o math.js -s WASM=1
 生成配套的JavaScript文件
 emcc math.c -o math.js -s WASM=1 -sEXPORTED_FUNCTIONS='["_add"]'
 
 
 */
