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
 
 一、 gem 和 bundler
 gem update --system
 gem update
 gem install
 gem uninstall [gemname] --version=[version]
 gem list [--local]
 gem clean
 
 命令                                                               作用说明
 bundle install                                                   根据 Gemfile 安装所有依赖，生成/更新 Gemfile.lock
 bundle update                                                 更新所有（或指定的）gem 到允许的最新版，并更新 Gemfile.lock
 bundle update <gem>                                     只更新指定 gem 及其依赖
 bundle add <gem>                                          添加指定 gem 到 Gemfile 并安装
 bundle remove <gem>                                    从 Gemfile 中移除指定 gem 并卸载
 bundle exec <命令>                                        用当前 bundle 环境运行命令（如 rails, rspec, rake 等）
 bundle list                                                        显示已安装的所有 gem 及其版本
 bundle show <gem>                                        显示指定 gem 的安装路径
 bundle outdated                                              列出所有可升级的 gem 及最新版本
 bundle info <gem>                                           显示指定 gem 的详细信息
 bundle check                                                   检查所需 gem 是否已全部安装，未安装则提示
 bundle clean [--force]                                    清理未在 Gemfile.lock 中的 gem
 bundle config                                                   配置 Bundler 的各种设置，例如安装路径
 bundle config set --local <key> <value>     设置本地（项目）配置项
 
 gem 管理“单个”gem 包
 Bundle（Bundler）可以自动管理和安装 Ruby 项目需要的所有 gem，确保每个人、每台机器上的环境都一样。Bundler（bundle）内部其实调用的是 gem 命令。
 
 二、RVM 和 ruby
 
 rvm get stable
 rvm list
 rvm list known
 rvm install 2.7.0
 rvm use 2.7.0 --default
 rvm remove 2.4.1

 三、rbenv 和 ruby（推荐）
 
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
 
 四、nvm 和 node
 
 nvm install 18.16.0          # 安装 18.16.0 版本
 nvm use 18.16.0              # 切换到 18.16.0
 nvm alias default 18.16.0    # 设置 18.16.0 为默认版本
 nvm uninstall 14.17.0        # 卸载 14.17.0 版本
 nvm ls                       # 查看所有已安装的 Node 版本
 nvm ls-remote                # 查看所有可用“远程”版本
 nvm use node                 # 切换到最新版本
 nvm install --lts            # 最新 LTS
 nvm use --lts                # 切换到最新 LTS

 
 */
