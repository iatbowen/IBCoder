//
//  IBGroup2Controller32.m
//  MBCoder
//
//  Created by 叶修 on 2024/11/11.
//  Copyright © 2024 inke. All rights reserved.
//

#import "IBGroup2Controller32.h"
#import "Person.pbobjc.h"
#include "teacher_generated.h"

@interface IBGroup2Controller32 ()

@end

@implementation IBGroup2Controller32

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self testProtobuf];
    [self testFlatBuffers];

}

- (void)testProtobuf {
    // 创建对象
    Person *person = [Person new];
    person.name = @"bowen";
    person.uid = 20170810;
    person.email = @"bowen@qq.com";
    
    // 序列化为Data
    NSData *data = [person data];
    NSLog(@"NSData= %@", data);
    
    // 反序列化为对象
    Person *person2 = [Person parseFromData:data error:NULL];
    NSLog(@"person name:%@ uid:%d email:%@",person2.name, person2.uid, person2.email);
}

- (void)testFlatBuffers {
    flatbuffers::FlatBufferBuilder builder;
    // 序列化
    auto nameOffset = builder.CreateString(@"bowen".UTF8String);
    auto teacherOffset = MyApp::CreateTeacher(builder, nameOffset, 30);
    builder.Finish(teacherOffset);
    NSData *buffer = [NSData dataWithBytes:builder.GetBufferPointer() length:builder.GetSize()];
    // 反序列化
    const MyApp::Teacher *teacher = MyApp::GetTeacher([buffer bytes]);
    NSString *name = [NSString stringWithUTF8String:teacher->name()->c_str()];
    NSLog(@"teacher name:%@, age:%d", name, teacher->age());
}

@end

/*
 一、Protobuf
 配置protobuf编译器
 方法一
 1、首先将文件下载下来https://github.com/google/protobuf/releases
 2、然后依次执行：
 $ ./configure
 $ make
 $ make check
 $ make install
 
 方法二
 1、首先将文件下载下来https://github.com/protocolbuffers/protobuf
 2、然后依次执行：
 $ ./autogen.sh
 $ ./configure
 $ make
 $ make install
 
 3、使用PB编译器编译.proto文件
 $ touch Person.proto
 $ protoc *.proto --objc_out=../ //生成model
 
 例子：
 syntax = "proto3";
 message Person {
    string name = 1;
    int32 uid = 2;
    string email = 3;
    enum PhoneType {
        MOBILE = 0;
        HOME = 1;
        WORK = 2;
 }
 message PhoneNumber {
    string number = 1;
    PhoneType type = 2;
 }
 repeated PhoneNumber phone = 4;
 
 }
 
 4、把Model引入工程，Compile Source把Model的.m文件设置为-fno-objc-arc
 
 二、FlatBuffers
 1、环境配置
 1) 安装 cmake：
 brew install cmake
 2) 下载源码
 git clone https://github.com/google/flatbuffers.git
 3) 生产makefile文件
 cd flatbuffers
 cmake -G "Unix Makefiles"
 4) 安装
 make
 make install
 5) 添加到系统，方便以后使用
 sudo cp flatc /usr/local/bin/flatc

 2、编译文件
 1) 定义 FlatBuffers Schema
 // teacher.fbs
 namespace MyGame;

 // 声明一个表（table），包含两个字段
 table Teacher {
   name:string;
   age:int;
 }
 
 // 定义文件的根类型
 root_type Teacher;
 
 2) 生成代码
 flatc --cpp --C++ --java teacher.fbs

 3) 使用见示例
 
 
 三、FlatBuffers vs Protobuf
 
 1、FlatBuffers
 优点
 1）零拷贝访问：
 FlatBuffers 允许直接从字节缓冲区访问数据，而不需要复制整个数据集到内存中。这种零拷贝解析非常适用于需要高性能读操作的应用，如游戏和实时系统。
 2）快速解析：
 由于采用了零拷贝设计，FlatBuffers 的解析速度极快，尤其在大数据集上。这使其非常适合高负载、低延迟环境。
 3）内存效率：
 在不需要拷贝数据的情况下访问内存，使得 FlatBuffers 具备很高的内存效率，减少了不必要的内存占用。
 3）语言支持广泛：
 FlatBuffers 支持多种编程语言，包括但不限于 C++, C#, Java, Go, JavaScript, Python, 和 Swift。
 
 缺点
 1）较高的写复杂性：
 构建缓冲区比 protobuf 复杂，因为需要先定义数据的结构。
 2）Schema 必须一致：
 在读写数据时，schema 的变更需要谨慎处理，否则可能导致兼容性问题。
 
 2、Protocol Buffers (Protobuf)
 优点
 1）简单易用：
 Protobuf 使用简单的 .proto 文件来定义数据结构，生成的代码相对容易理解和集成。
 2）高效的序列化效率：
 虽然在解析上不如 FlatBuffers 快，但它在序列化和压缩上表现很好，并且生成的二进制数据更小。
 3）广泛的使用和支持：
 Protobuf 是一个成熟的项目，已经被广泛应用于 Google 和其他许多企业的产品中，社区活跃且提供良好的支持。
 4）版本兼容性：
 通过支持默认值和可选字段，协议缓冲区允许在版本演化中灵活地添加新字段而不会破坏旧的数据格式。
 
 缺点
 1）需要反序列化：
 解析时需要将数据拷贝到结构化对象，这在某些高性能应用中会成为瓶颈。
 2）稍逊于 FlatBuffers 的解析速度：
 虽然快速，但在解码速度上通常慢于没有数据拷贝的 FlatBuffers。
 
 四、选择指南
 1. 使用 FlatBuffers 的场景：
 实时系统要求极高的解析速度。
 内存使用受限，需要尽量减少 RAM 占用。
 数据结构比较复杂，但读操作比写操作频繁。
 
 2. 使用 Protobuf 的场景：
 企业级应用系统需要稳定的通信协议和广泛的生态支持。
 需要向后/向前兼容的数据结构演化。
 应用程序中序列化和反序列化都需要高效处理。
 
 五、性能对比
 
 编码性能对比（单位秒）
 
 Person个数    Protobuf    JSON    FlatBuffers
 10           6.000       8.952    12.464
 50           26.847      45.782   56.752
 100          50.602      73.688   108.426
 编码性能Protobuf相对于JSON有较大幅度的提高，而FlatBuffers则有较大幅度的降低。

 解码性能对比 (单位秒)

 Person个数    Protobuf    JSON    FlatBuffers
 10           0.255       10.766    0.014
 50           0.245       51.134    0.014
 100          0.323       101.070   0.006
 解码性能方面，Protobuf相对于JSON，有着惊人的提升。Protobuf的解码时间几乎不随着数据长度的增长而有太大的增长，而JSON则随着数据长度的增加，解码所需要的时间也越来越长。
 而FlatBuffers则由于无需解码，在性能方面相对于前两者更有着非常大的提升。


 */
