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
 
 iOS编译速度优化实践
 https://juejin.cn/post/7227084645481365559
 
 幸福里 C 端 iOS 编译优化实践-优化 40% 耗时 原创 精选
 https://www.51cto.com/article/715377.html
 
 深入剖析iOS编译
 https://ming1016.github.io/2017/03/01/deeply-analyse-llvm/

 iOS编译原理
 http://hchong.net/2019/07/30/iOS%E7%BC%96%E8%AF%91%E5%8E%9F%E7%90%86/

 Xcode编译速度提升
 https://elliotsomething.github.io/2018/05/23/XCodeBuild/

 iOS 微信编译速度优化
 https://mp.weixin.qq.com/s/QI7cyVyYuayLaJTXJVYgzQ

 浅谈iOS编译过程
 https://blog.csdn.net/Future_One/article/details/81882359

 Xcode Build过程
 https://www.jianshu.com/p/44f97ca6f452

 关于Xcode编译性能优化的研究工作总结
 https://blog.csdn.net/qq_25131687/article/details/52194034

 美团 iOS 工程 zsource 命令背后的那些事儿
 https://tech.meituan.com/2019/08/08/the-things-behind-the-ios-project-zsource-command.html
 pod zsource add AFN

 基于LLVM开发属于自己Xcode的Clang插件
 https://www.jianshu.com/p/4935e919bb45

 开发Xcode插件
 https://cloud.tencent.com/developer/article/1513387

 开启Link Time Optimization(LTO)后到底有什么优化？
 https://www.jianshu.com/p/58fef052291a

 XCode 分析編譯耗時之我見
 https://medium.com/@SunXiaoShan/llvm-%E7%B7%A8%E8%AD%AF%E8%80%97%E6%99%82%E4%B9%8B%E6%88%91%E8%A6%8B-eabb3fb3817e


 clang(-ftime-trace)优化C/C++工程编译时长
 https://blog.csdn.net/wwchao2012/article/details/105897623

 深入浅出 iOS 编译
 https://github.com/LeoMobileDeveloper/Blogs/blob/master/Compiler/xcode-compile-deep.md

 iOS里的导入头文件
 https://www.zybuluo.com/qidiandasheng/note/602118
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

