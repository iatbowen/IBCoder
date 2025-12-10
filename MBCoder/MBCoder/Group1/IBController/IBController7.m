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
    NSLog(@"===== 开始测试 WebAssembly =====");
    
    // 1. 加载 Wasm 文件
    NSURL *wasmURL = [[NSBundle mainBundle] URLForResource:@"math" withExtension:@"wasm"];
    NSLog(@"1. Wasm 文件路径: %@", wasmURL);
    
    if (!wasmURL) {
        NSLog(@"❌ 错误: 找不到 math.wasm 文件");
        return;
    }
    
    NSData *wasmData = [NSData dataWithContentsOfURL:wasmURL];
    NSLog(@"2. Wasm 文件大小: %lu bytes", (unsigned long)wasmData.length);
    
    if (!wasmData || wasmData.length == 0) {
        NSLog(@"❌ 错误: Wasm 文件数据为空");
        return;
    }
    
    // 2. 创建 JSContext
    JSContext *context = [[JSContext alloc] init];
    context.exceptionHandler = ^(JSContext *ctx, JSValue *exception) {
        NSLog(@"❌ JS 异常: %@", exception);
    };
    context[@"console"][@"log"] = ^(JSValue *message) {
        NSLog(@"   [JS] %@", message);
    };
    NSLog(@"3. JSContext 创建成功");
    
    // 3. 判断环境是否支持 WebAssembly
    JSValue *wasmCheck = [context evaluateScript:@"typeof WebAssembly"];
    NSLog(@"4. WebAssembly 类型检查: %@", [wasmCheck toString]);
    
    if ([wasmCheck.toString isEqualToString:@"undefined"]) {
        NSLog(@"❌ 错误: JavaScriptCore 不支持 WebAssembly");
        return;
    }
    
    NSLog(@"✅ WebAssembly 支持检查通过");
    
    // 4. 将 NSData 转换为 JavaScript 的 Uint8Array
    JSValue *uint8Array = [self convertNSDataToUint8Array:wasmData inContext:context];
    NSLog(@"5. Uint8Array 创建成功，长度: %@", uint8Array[@"length"]);
    
    // 5. 定义 JavaScript 代码（使用 Promise 异步加载 Wasm）
    NSString *jsCode =
    @"function loadWasm(bytes) {"
    "   console.log('开始编译 WASM...');"
    "   try {"
    "       var module = new WebAssembly.Module(bytes);"
    "       console.log('模块编译成功');"
    "       var instance = new WebAssembly.Instance(module);"
    "       console.log('实例化成功');"
    "       return instance;"
    "   } catch (e) {"
    "       console.log('错误: ' + e.message);"
    "       throw e;"
    "   }"
    "}";
    
    [context evaluateScript:jsCode];
    NSLog(@"6. JavaScript 函数定义完成");
    
    // 6. 调用 JavaScript 函数加载 Wasm（同步方式）
    JSValue *loadWasmFunc = context[@"loadWasm"];
    NSLog(@"7. 调用 loadWasm 函数...");
    
    JSValue *instance = [loadWasmFunc callWithArguments:@[uint8Array]];
    
    if (!instance || instance.isUndefined) {
        NSLog(@"❌ 错误: WASM 实例化失败");
        return;
    }
    
    NSLog(@"8. WASM 实例化成功");
    
    // 7. 调用 add 函数
    JSValue *exports = instance[@"exports"];
    NSLog(@"9. 导出对象: %p", exports);
    
    JSValue *addFunc = exports[@"add"];
    if (!addFunc || addFunc.isUndefined) {
        NSLog(@"❌ 错误: add 函数未导出");
        // 列出所有导出的函数
        JSValue *keys = [context evaluateScript:@"(function(obj) { return Object.keys(obj); })"];
        JSValue *exportNames = [keys callWithArguments:@[exports]];
        NSLog(@"   可用的导出: %@", exportNames);
        return;
    }
    
    NSLog(@"10. 找到 add 函数，准备调用...");
    
    // 调用 add(5, 3)
    JSValue *result = [addFunc callWithArguments:@[@(5), @(3)]];
    NSLog(@"✅ 结果: 5 + 3 = %d", [result toInt32]);
    
    NSLog(@"===== WebAssembly 测试完成 =====");
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
