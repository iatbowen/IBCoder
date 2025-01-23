//
//  IBGroup2Controller35.m
//  MBCoder
//
//  Created by 叶修 on 2024/12/20.
//  Copyright © 2024 inke. All rights reserved.
//

#import "IBGroup2Controller35.h"

@interface IBGroup2Controller35 ()

@end

@implementation IBGroup2Controller35

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end

/*
 
 一、像素预乘
 Alpha预乘（预乘Alpha，Premultiplied Alpha）是计算机图形学中用于处理颜色与透明度（Alpha）的技术。
 它涉及到在存储或计算颜色值之前，将颜色组件（红、绿、蓝）与Alpha值预先相乘。这与传统的非预乘Alpha（Straight Alpha）处理方式不同，后者将颜色与Alpha值分别储存和处理
  
 非预乘Alpha: 需要在运行时对每个通道进行单独的Alpha乘数计算。
 预乘Alpha: 预先将颜色通道与Alpha相乘，仅在混合时与背景计算，需要较少的运算步骤
 
 提高计算效率：在合成图像或进行混合操作时，由于混合公式中不需要再对颜色与Alpha进行逐像素的乘法计算，这提高了运算效率。
 
 二、使用内存图谱消减内存峰值
 - 超大图片缩小，瞬时峰值减不了，但是一段时间峰值可以减少
 - 转换过程中保留一份数据
 
 三、放量
 
 四、遇到的问题
 wkwebview
 
 打包 libavif
 1、mkdir build
 cd build
 2、运行下面指令
 cmake .. -DBUILD_SHARED_LIBS=OFF -DAVIF_LOCAL_DAV1D=ON -DAVIF_CODEC_DAV1D=ON  -DAVIF_LOCAL_LIBYUV=ON -DCMAKE_OSX_ARCHITECTURES=x86_64 -DCMAKE_OSX_SYSROOT=iphonesimulator -DCMAKE_BUILD_TYPE=Release

 cmake .. -DBUILD_SHARED_LIBS=OFF -DAVIF_LOCAL_DAV1D=ON -DAVIF_CODEC_DAV1D=ON -DAVIF_LOCAL_LIBYUV=ON -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_BUILD_TYPE=Release
 3、make

 打包 libyuv
 1、类似打包 libavif

 打包 dav1d
 1、clone
 2、执行下面代码
 meson build --cross-file=../other/x86_64-ios.meson --default-library=static --buildtype release
 meson build --cross-file=../other/arm64-ios.meson --default-library=static --buildtype release
 3、cd build
 3、ninja
 
 
 */
