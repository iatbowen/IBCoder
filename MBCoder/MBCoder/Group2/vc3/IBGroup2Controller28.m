//
//  IBGroup2Controller28.m
//  MBCoder
//
//  Created by BowenCoder on 2020/8/1.
//  Copyright © 2020 inke. All rights reserved.
//

#import "IBGroup2Controller28.h"

/*
 libcurl 和 cronet
 
 libcurl:用于在各种平台上进行网络数据传输。它支持众多协议（HTTP、HTTPS、FTP、SMTP 等）。
 特点：
 - C 语言编写，C/C++/Python/Java/等语言都有绑定。
 - 易于集成，稳定可靠，接口简单。
 - 支持多种协议，尤其在自动化运维、硬件嵌入设备、桌面服务等场景中非常普遍。
 - 跨平台，支持 Windows、Linux、macOS、iOS、Android 等。
 - 支持同步和异步请求，但异步需要自己管理线程或事件循环。
 
 Cronet 库是Chrome使用的移动端网络库。支持 HTTP、HTTP/2 以及 QUIC 协议。支持 Android 和 iOS 平台。
 特点：
 - 基于 Chromium 的网络栈，采用最新的网络协议和技术，如 HTTP/2、QUIC。
 - 高性能，低延迟；专为移动设备优化。
 - 异步 API 设计，更适合高并发场景。
 - 自动管理连接池、缓存等优化逻辑。
 - 只支持 HTTP/HTTPS，协议支持不如 libcurl 广泛。
 - 现在主要在 Android、iOS 及部分桌面应用中使用，特别是 Chrome 浏览器和一些 Google 官方应用
 
 移动端(Android、iOS)接入Cronet实践
 https://itimetraveler.github.io/2019/07/25/%E7%A7%BB%E5%8A%A8%E7%AB%AF%E6%8E%A5%E5%85%A5Cronet%E7%BD%91%E7%BB%9C%E5%BA%93%E5%AE%9E%E8%B7%B5/
 
 
 */

@interface IBGroup2Controller28 ()

@end

@implementation IBGroup2Controller28

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

}

@end

