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
