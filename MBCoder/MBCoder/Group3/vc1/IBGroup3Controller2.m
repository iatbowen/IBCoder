//
//  IBGroup3Controller2.m
//  MBCoder
//
//  Created by 叶修 on 2025/1/3.
//  Copyright © 2025 inke. All rights reserved.
//

#import "IBGroup3Controller2.h"
#import "JPEngine.h"

@interface IBGroup3Controller2 ()

@end

@implementation IBGroup3Controller2

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [JPEngine startEngine];
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"js"];
    NSString *script = [NSString stringWithContentsOfFile:sourcePath encoding:NSUTF8StringEncoding error:nil];
    [JPEngine evaluateScript:script];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 120, [UIScreen mainScreen].bounds.size.width, 44)];
    [btn setTitle:@"Push JPTableViewController" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(handleBtn:) forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:btn];
}

- (void)handleBtn:(id)sender
{
    
}

@end

/**
 
 一、JSPatch
 源码：https://github.com/bang590/JSPatch
 JSPatch 源码解析(一)
 https://zhang759740844.github.io/2019/08/01/jspatch/
 JSPatch 源码解析(二)
 https://zhang759740844.github.io/2019/08/08/jspatch2/
 JSPatch 实现原理详解
 https://github.com/bang590/JSPatch/wiki/JSPatch-%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86%E8%AF%A6%E8%A7%A3
 oc -> js
 https://github.com/bang590/JSPatchConvertor
  
 二、OCRunner
 https://github.com/SilverFruity/OCRunner
 OCRunner 第零篇：从零教你写一个 iOS 热修复框架
 https://mp.weixin.qq.com/s?__biz=MzI2NTAxMzg2MA==&mid=2247488962&idx=1&sn=cdb1cd8a8cd788b15fbc0dbc0ecfccf1&scene=21#wechat_redirect
 
 三、libffi/lex/yacc
 libffi探究
 https://juejin.cn/post/6844904177609490440
 https://github.com/libffi/libffi
 Lex与YACC详解
 https://zhuanlan.zhihu.com/p/143867739
 
 四、QQ浏览器HD iOS 动态化/热修复方案QBDF
 https://github.com/ventureli/QBDF
 https://blog.csdn.net/liwenqiang04051?type=blog&year=2022&month=01

 五、MangoFix
 https://www.jianshu.com/p/a6511c687eda
 https://github.com/yanshuimu/MangoFixUtil
 
 六、DynamicCocoa
 https://juejin.cn/post/6844903457699135495
 
 七、OCS ——史上最疯狂的 iOS 动态化方案
 https://www.jianshu.com/p/0f99d106d93a
 
 
 
 */
