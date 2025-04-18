//
//  IBGroup2Controller27.m
//  MBCoder
//
//  Created by Bowen on 2020/6/16.
//  Copyright © 2020 inke. All rights reserved.
//

#import "IBGroup2Controller27.h"

@interface IBGroup2Controller27 ()

@property (nonatomic, strong) UIView *whiteView;

@end

@implementation IBGroup2Controller27

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection * traitCollection) {
            if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
                return [UIColor redColor];
            }
            else {
                return [UIColor greenColor];
            }
        }];
    }
    self.whiteView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(100, 200, 80, 44)];
        view.layer.borderColor = [UIColor orangeColor].CGColor;
        view.layer.borderWidth = 10.0;
        view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:view];
        view;
    });
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(100, 260, 80, 44)];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];

}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if (@available(iOS 13.0, *)) {
        
        UIColor *dynamicColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitC) {
            if (traitC.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return UIColor.blackColor;
            } else {
                return UIColor.whiteColor;
            }
        }];
        
        UIColor *red  = [dynamicColor resolvedColorWithTraitCollection:previousTraitCollection];
        self.whiteView.backgroundColor = red;
    }
    NSLog(@"%s", __func__);
}


@end

/**
 一、暗黑适配
 1. KVC访问私有属性
    textFiled的占位文字
 2. 模态弹窗ViewController 默认样式改变
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
 3. 黑暗模式的适配
 4. LaunchImage即将废弃（https://www.jianshu.com/p/ef5f877b2412）
 5. 新增一直使用蓝牙的权限申请
 6. Sign With Apple
 7. 推送Device Token适配
 8. 废弃UIWebview APIs
 9. StatusBar新增样式
    StatusBar 新增一种样式，默认的 default 由之前的黑色字体，变为根据系统模式自动选择展示 lightContent 或者 darkContent
 10. 使用 @available 导致旧版本 Xcode 编译出错
 
 
 一、 gem
 gem update --system
 gem update
 gem install
 gem uninstall [gemname] --version=[version]
 gem list [--local]
 gem clean
 
 二、RVM
 
 rvm get stable
 rvm list
 rvm list known
 rvm install 2.7.0
 rvm use 2.7.0 --default
 rvm remove 2.4.1

 三、rbenv
 
 1. 安装 rbenv
 brew install rbenv
 
 安装后，将以下内容添加到 ~/.zshrc 或 ~/.bashrc：
 eval "$(rbenv init -)"
 
 然后重新加载 Shell：
 source ~/.zshrc  # 或 source ~/.bashrc
 
 
 命令                              作用
 rbenv install --list         查看可安装的 Ruby 版本
 rbenv install 3.3.0        安装 Ruby 3.3.0
 rbenv versions             查看已安装的 Ruby 版本
 rbenv global 3.3.0       设置全局 Ruby 版本
 rbenv local 3.2.2         设置当前目录的 Ruby 版本
 rbenv shell 3.1.4          临时切换 Ruby 版本
 rbenv uninstall 3.1.4    卸载 Ruby 版本
 rbenv rehash               更新 shims（安装新 gem 后可能需要）
 
 */
