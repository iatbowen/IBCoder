//
//  IBGroup2Controller33.m
//  MBCoder
//
//  Created by 叶修 on 2024/12/4.
//  Copyright © 2024 inke. All rights reserved.
//

#import "IBGroup2Controller33.h"

/**
 泛型（T，ObjectType，ValueType，KeyType）：通过在定义时不指定具体类型而在使用时指定类型，以保证类型安全的同时提升代码复用及灵活性
 协变（__covariant）：用于泛型数据强转类型，子类可以转成父类，非常适合多态接口的返回类型
 逆变（__contravariant）：用于泛型数据强转类型，父类可以转成子类，特别适合传入参数的多态操作
 
 */

@interface IBGroup2Controller33 ()

@end

@implementation IBGroup2Controller33

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

@end


@interface Language : NSObject

@end

@implementation Language


@end

@interface Java : Language

@end

@implementation Java


@end

@interface iOS : Language

@end

@implementation iOS

@end

// 泛型，ObjectType
@interface Coder<ObjectType> : NSObject

// 语言
@property (nonatomic, strong) ObjectType language;

@end

@implementation Coder

- (void)test {
    Java *java = [[Java alloc] init];
    iOS *ios = [[iOS alloc] init];
    Coder<iOS *> *coder1 = [[Coder alloc] init];
    coder1.language = ios;
    
    Coder<Java *> *coder2 = [[Coder alloc] init];
    coder2.language = java;
}

@end

// __covariant 协变，子类转父类；泛型名字是ObjectType
@interface CoderBoy<__covariant ObjectType> : NSObject

// 语言
@property (nonatomic, strong) ObjectType language;

@end

@implementation CoderBoy

// 子类转父类
- (void)covariant {

    iOS *ios = [[iOS alloc] init];
    Language *language = [[Language alloc] init];

    // iOS 只会iOS
    CoderBoy<iOS *> *coder1 = [[CoderBoy alloc] init];
    coder1.language = ios;

    // Language 都会
    CoderBoy<Language *> *coder2 = [[CoderBoy alloc] init];
    
    // 如果没添加协变会报指针类型错误警告
    coder2 = coder1;
}

@end


// __covariant 协变，子类转父类；泛型名字是ObjectType
@interface CoderGirl<__contravariant ObjectType> : NSObject

// 语言
@property (nonatomic, strong) ObjectType language;

@end

@implementation CoderGirl

- (void)contravariant {

    // 第二步 定义泛型
    iOS *ios = [[iOS alloc] init];
    Language *language = [[Language alloc] init];

    // 父类转子类  都会
    CoderGirl<Language *> *coder1 = [[CoderGirl alloc] init];
    coder1.language = language;

    // iOS  只会iOS
    CoderGirl<iOS *> *coder2 = [[CoderGirl alloc] init];
    
    // 如果没添加逆变会报指针类型错误警告
    coder2 = coder1;
}


@end

