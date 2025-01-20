//
//  IBGroup3Controller1.m
//  MBCoder
//
//  Created by 叶修 on 2024/12/20.
//  Copyright © 2024 inke. All rights reserved.
//

#import "IBGroup3Controller1.h"

@interface IBGroup3Controller1 ()

@end

@implementation IBGroup3Controller1

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end

/*
 一、Header Map
 Header Map是一种编译优化技术，它通过减少头文件的搜索范围来加速编译过程。
 当编译器编译源文件时，它会搜索头文件以获取所需的声明和定义。 如果头文件很大或者有很多依赖关系，那么搜索时间可能会很长。 Header Map可以减少搜索范围，从而加快编译速度
 
 二、XCRemoteCache
 https://github.com/spotify/XCRemoteCache
 
 
 
 一款可以让大型iOS工程编译速度提升50%的工具
 https://tech.meituan.com/2021/02/25/cocoapods-hmap-prebuilt.html
 
 iOS编译速度如何稳定提高10倍以上之一
 https://juejin.cn/post/6903407900006449160
 
 微信团队分享：极致优化，iOS版微信编译速度3倍提升的实践总结
 https://cloud.tencent.com/developer/article/1558486
 
 iOS编译速度优化实践
 https://juejin.cn/post/7227084645481365559
 
 幸福里 C 端 iOS 编译优化实践-优化 40% 耗时 原创 精选
 https://www.51cto.com/article/715377.html
 
 深入剖析iOS编译
 https://ming1016.github.io/2017/03/01/deeply-analyse-llvm/

 iOS同学需要了解的基本编译原理
 https://juejin.cn/post/6985767264863649828
 
 iOS 编译全过程
 https://juejin.cn/post/6859926544408969224

 美团 iOS 工程 zsource 命令背后的那些事儿
 https://tech.meituan.com/2019/08/08/the-things-behind-the-ios-project-zsource-command.html
 pod zsource add AFN

 基于LLVM开发属于自己Xcode的Clang插件
 https://www.jianshu.com/p/4935e919bb45

 开启Link Time Optimization(LTO)后到底有什么优化？
 https://www.jianshu.com/p/58fef052291a

 深入浅出 iOS 编译
 https://github.com/LeoMobileDeveloper/Blogs/blob/master/Compiler/xcode-compile-deep.md

 iOS里的导入头文件
 https://zhuanlan.zhihu.com/p/51194169
 

 修改：Clang，Zsource

 替换Clang

 下面我详细记录一下操作步骤：
 1. 先下载编译好的llvm，下载网页：http://releases.llvm.org/download.html。
 2. 网页的Pre-Built Binaries下面有已经编译好的各个平台的llvm
 3. 解压后，在 Xcode 的 Build Settings 下的 User-Defined 添加键 CC,值就就是你刚解压的clang的位置 {解压路径}/bin/clang
 4. 添加方式：Editor -> Add Build Setting -> Add Build User-Defined Setting
 5. 在 Build Settings 里搜索 OTHER_CFLAGS 添加参数 -ftime-trace
 6. 这个时候编译会报这个错误，Unknown argument: '-index-store-path'，在Build Setting 中搜索index并将Enable Index-While-Building Functionality选项设置为NO
 7. chrome://tracing
 这个时候就可以编译了，如果当前工程依赖其他工程，比如Pods工程，如果编译出现一些链接错误的话，那就也把这些工程改为下载的clang编译，重复上面的4、5、6步。

 post_install do |installer|
   
   puts "##### post_install start #####"
   
   installer.pod_targets.each do |target|
     installer.generated_projects.flat_map { |p| p.targets }.each do |target|
       puts "targetName: #{target.name}"
       target.build_configurations.each do |config|
         config.build_settings['CC'] = '/Users/bowencoder/Desktop/llvm_release/bin/clang'
         config.build_settings['CXX'] = '/Users/bowencoder/Desktop/llvm_release/bin/clang'
         config.build_settings['OTHER_CFLAGS'] = '-ftime-trace'
         config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
       end
     end
   end
   
   puts "##### post_install end #####"
   
 end #installer
 
 */

