//
//  IBGroup3Controller7.m
//  MBCoder
//
//  Created by 叶修 on 2025/1/3.
//  Copyright © 2025 inke. All rights reserved.
//

#import "IBGroup3Controller7.h"

@interface IBGroup3Controller7 ()

@end

@implementation IBGroup3Controller7

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end

/*
 React-Native — 原理探究
 https://www.jianshu.com/p/a54c0bffc4e5

 React Native 原理与实践
 https://juejin.cn/post/6916452544956858382

 渲染，提交与挂载（渲染流水线）
 https://reactnative.cn/docs/render-pipeline

 「ReactNative原理」 JS 层渲染之 diff 算法
 https://juejin.cn/post/6844904197096226824
 
 一、React-Native
 
 1、项目初始化
 npx create-expo-app@latest
 
 经典结构
 npx create-expo-app my-app -t expo-template-blank

 2、运行项目
 npx expo start
 
 3、预构建原生代码
 npx expo prebuild
 
 4、配置 TypeScript 环境
 - 安装 TypeScript 及类型声明包
 npm install --save-dev typescript @types/react @types/react-native

 - 自动生成 TypeScript 配置
 npx tsc --init

 5、学习 <<从0到1上手 RN 开发.pdf>>
 
 6、通信原理
 旧架构                                新架构
 ─────────────────────────────────────────────────────────
 ┌─────────────┐                      ┌─────────────┐
 │  JS Engine  │                      │  JS Engine  │
 │    (JSC)    │                      │  (Hermes)   │
 │             │                      │             │
 │  JSContext  │                      │jsi::Runtime │
 └──────┬──────┘                      └──────┬──────┘
        │                                    │
        │ ObjC JSContext API                 │ C++ JSI 直接操作
        │ JSON序列化                          │ 无序列化
        │ 异步消息队列                         │ 同步/异步可选
        │                                    │
 ┌──────▼──────┐                      ┌──────▼──────┐
 │   Bridge    │                      │     JSI     │
 │  (JSON队列)  │                      │  (C++接口)  │
 └──────┬──────┘                      └──────┬──────┘
        │                                    │
 ┌──────▼──────┐                      ┌──────▼──────────────┐
 │ ObjC Native │                      │ Turbo Modules       │
 │  Modules    │                      │ Fabric Renderer     │
 │             │                      │ (C++ → ObjC)        │
 └─────────────┘                      └─────────────────────┘

 旧架构：
 JS ←[ObjC JSContext + JSON序列化 + 异步队列]→ Native

 新架构：
 JS ←[C++ JSI + 直接内存 + 同步调用]→ Native

 
 7、RN 工程设计
 基于 pnpm workspace 的 RN 工程（多应用 + 共享包）
 repo/                                      # L0 单仓
 ├── pnpm-workspace.yaml                    # L1 编排：包范围
 ├── package.json                           # L1 根脚本 / 版本对齐
 ├── tsconfig.base.json                     # L1 TS 基座
 ├── turbo.json                             # L1 任务编排（可选）
 ├── eslint.config.* | .eslintrc.*          # L1 规范（择一）
 ├── scripts/                               # L1 脚手架、仓级脚本
 ├── tools/                                 # L1 周边工具
 ├── .changeset/                            # L1 发版记录（可选）
 │
 ├── apps/                                  # L2 竖切：可交付 RN
 │   └── <app>/
 │       ├── hammer.config.js               # 构建入口（或 metro 等，按栈）
 │       ├── package.json
 │       └── src/                           # L3 运行时架构
 │           ├── index.ts                   # 入口注册（路由 / bundle）
 │           ├── containers/                # L3 页面域
 │           │   └── <feature>/             # L4 单功能域
 │           │       ├── page/              # 或 screens/
 │           │       ├── components/
 │           │       └── hooks/
 │           ├── store/
 │           ├── services/
 │           ├── components/                # 应用内 UI 复用
 │           ├── config/
 │           ├── utils/
 │           └── tracker/
 │
 └── shared/                                # L2 横切：共享库（多 workspace 子包）
     ├── components/                        # 示例：可按现仓拆法命名
     │   └── src/
     ├── hooks/
     │   └── src/
     └── utils/
         └── src/
 
 二、Lynx
 1、项目初始化
 https://github.com/lynx-family/lynx/tree/develop/explorer/darwin/ios

 
 三、KMP
 
 1. 鸿蒙工程原理：
 Kuikly 鸿蒙端渲染是基于ArkUI C-API 实现，在业务接入时，需要通过 NAPI ，将运行时初始化接口暴露到业务ArkTS层。
 NAPI：一套让 ArkTS/JS 可以调用 C/C++ 原生代码能力 的接口/机制，用来做“原生扩展”。
 iOS 的 ObjC interop、Android 的 JNI
 https://kuikly.tds.qq.com/QuickStart/harmony.html
 
 2. 架构原理：
 ┌─────────────────────────────────┐
 │         共享业务逻辑 (Kotlin)     │
 │  ┌──────────┐  ┌──────────────┐ │
 │  │  Domain  │  │     Data     │ │
 │  │  Layer   │  │    Layer     │ │
 │  └──────────┘  └──────────────┘ │
 └────────┬────────────────────────┘
          │ 编译
     ┌────┴────┐
     ↓         ↓
 JVM/Android  Kotlin/Native → iOS Framework
 (字节码)      (LLVM编译为.framework)
 
 
 3. Kotlin/Native 与 ObjC 的"零桥接"原理

 Kotlin/Native 编译器做了三件事:

 第一件: 内存布局兼容 ObjC
 ┌─────────────────────────────────────┐
 │ isa pointer        ← 放在第一位!    │
 ├─────────────────────────────────────┤
 │ Kotlin typeInfo                     │
 ├─────────────────────────────────────┤
 │ Kotlin 字段...                      │
 └─────────────────────────────────────┘
 满足了 ObjC Runtime 的最低要求 ✅

 第二件: 注册 Class 到 ObjC Runtime
 objc_allocateClassPair(...)   // 创建类
 class_addMethod(              // 注册方法
     cls,
     @selector(getPlatformName),
     Kotlin编译出的C函数地址,    // ← 关键！
     "@@:"
 )
 objc_registerClassPair(...)   // 注册完成

 第三件: Kotlin 编译出 C 函数作为 IMP
 static id impl(id self, SEL _cmd) {
     // self 就是那块内存
     // 直接执行 Kotlin 逻辑
 }

 4. 完整流程
 内存中的 Kotlin 对象:
 地址 0x100 ┌─────────────────┐
            │ isa → Class表   │
            ├─────────────────┤
            │ Kotlin数据...   │
            └─────────────────┘

 ObjC Class 表（已注册到Runtime）:
 ┌──────────────────────────────────────┐
 │ "SharedPlatform"                     │
 │ 方法列表:                             │
 │   getPlatformName → 0xABCD (函数地址) │ ← Kotlin编译出的C函数
 │   init            → 0xEF01           │
 └──────────────────────────────────────┘

 调用时:
 platform.getPlatformName()
     ↓
 objc_msgSend(0x100, getPlatformName)
     ↓
 读 0x100 第一个字段 → 找到 Class 表
     ↓
 查表找到 IMP = 0xABCD
     ↓
 直接 jump 0xABCD 执行
     ↓
 执行的就是 Kotlin 编译出的机器码
 

 四、Flutter
 
 1. 整体架构
 ┌─────────────────────────────────────────┐
 │         Dart 业务层 (Flutter)            │
 │   MethodChannel / EventChannel /        │
 │   BasicMessageChannel                   │
 └──────────────┬──────────────────────────┘
                │ Dart FFI / dart:ui
 ┌──────────────┴──────────────────────────┐
 │      Flutter Engine (C++)               │
 │   - Platform Task Runner                │
 │   - UI Task Runner                      │
 │   - Message Codec / Binary Messenger    │
 └──────────────┬──────────────────────────┘
                │ ObjC Interop (Embedder API)
 ┌──────────────┴──────────────────────────┐
 │   iOS Embedder (ObjC/Swift)             │
 │   FlutterEngine / FlutterViewController │
 │   FlutterMethodChannel                  │
 └──────────────┬──────────────────────────┘
                │ 系统 API
 ┌──────────────┴──────────────────────────┐
 │         iOS 原生 (UIKit / Foundation)    │
 └─────────────────────────────────────────┘
 
 Platform Channel 三种类型：
 - MethodChannel    → 方法调用 (一次请求-响应)
 - EventChannel     → 事件流 (Native持续推送到Dart)
 - BasicMessageChannel → 自定义编解码消息
 
 Flutter 通信原理图

 Dart 世界                              iOS 世界
┌───────────────────┐                ┌───────────────────┐
│ invokeMethod(...) │                │  block handler    │
└─────────┬─────────┘                └─────────▲─────────┘
          │ 编码                                │ 解码
          ↓                                    │
┌───────────────────┐                ┌─────────┴─────────┐
│  ByteData (二进制) │                │  NSData (二进制)   │
└─────────┬─────────┘                └─────────▲─────────┘
          │ BinaryMessenger.send               │
          ↓                                    │
╔═════════════════════════════════════════════════════════╗
║              Flutter Engine (C++)                       ║
║                                                         ║
║   PlatformMessage { channel, data, reply_callback }     ║
║                                                         ║
║   UI 线程 ────跨线程投递───→ 主线程                         ║
╚═════════════════════════════════════════════════════════╝


 
 */
