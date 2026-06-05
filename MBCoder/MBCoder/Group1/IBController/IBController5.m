//
//  IBController5.m
//  IBCoder1
//
//  Created by Bowen on 2018/4/27.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController5.h"

@interface IBController5 ()

@property (nonatomic, copy) NSString *nameCopy1;
@property (nonatomic, copy) NSMutableString *mutableNameCopy2;
@property (nonatomic, strong) NSString *nameStrong3; //内容可能被外界修改
@property (nonatomic, strong) NSMutableString *mutableNameStrong4; //可能崩溃

@end

@implementation IBController5

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self test0];
    [self test1];
//    [self test2];
//    [self test3];
//    [self test3_1];
}


/**
 指针的三个容易弄混淆的概念
 指针地址：指针自身的地址，即内存中用于存放指针变量的内存地址
 指针保存的地址：指针所保存的变量在内存中的地址，通俗讲就是指针所指向的对象的内存地址
 指针所保存的地址的值：指针所指对象的数值。
 
 指针混淆
 指针是一个变量，只是指向了其他变量的地址
 数组是是多个元素的集合，在内存中分布在地址相连的单元中，所以可以通过其下标访问不同单元的元素。
 它的数组名可以相当一个指针,代表数组的首地址；
 
 最主要的原因是它们都可以以指针形式和以数组下标形式这两种形式去访问。
 
 常量指针和指针常量区别：
 1、本质
 指针常量：本质上一个常量，表示该常量是一个指针类型的常量。
 常量指针：本质上是一个指针，说明该指针指向一个“常量”。

 2、地址
 指针常量：在指针常量中，指针自身的值是一个常量，不可改变，始终指向同一个地址。在定义的同时必须初始化。
 常量指针：指针可以指向其他地址

 3、内容
 指针常量：指向的内容可以修改
 常量指针：在常量指针中，指针指向的内容是不可改变的，指针看起来好像指向了一个常量。
 
 
 // 通知名正确写法（指针常量）
 NSString * const MyNotificationName = @"MyNotificationName";
 
 常量指针：指针指向常量（内容不可改，指针可改）
 指针常量：指针本身是常量（指针不可改，内容可改）
 
 */
- (void)test4
{
    int m = 10;
    const int n =20;
    
    int const *ptr1 = &m; // 指向的内容不能改变
    int * const ptr2 = &m; // 指针不能指向其他地方
    
    ptr1 = &n;  // 正确
//    ptr2 = &n; // 错误
    
//    *ptr1 = 3; // 错误
    *ptr2 = 3; // 正确
    
}

- (void)test3_1 {
    NSMutableString *str1 = @"1".mutableCopy;
    
    NSMutableArray *arr1 = @[str1, @[str1]].mutableCopy;
    
    // 一层深拷贝
    NSMutableArray *arr2 = [[NSMutableArray alloc] initWithArray:arr1 copyItems:YES];
    
    NSMutableString *str2 = [arr1 objectAtIndex:0];
    [str2 appendString:@"1"];
    
    NSLog(@"arr2--%@", arr2);

}

- (void)test3 {
    //利用归档实现完全深拷贝
    NSMutableString *a = @"bowen1".mutableCopy;
    NSMutableString *b = @"bowen2".mutableCopy;
    NSMutableString *c = @"bowen3".mutableCopy;
    NSMutableString *d = @"bowen4".mutableCopy;
    NSArray *arr = @[a,b,c,d];
    NSArray *temp = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:arr]];
    [a appendString:@"1"];
    NSLog(@"%@",temp);
    
    //自定义对象（需要实现nscoding协议+归档）

}


- (void)test2 {
    //不走set方法，就不经过copy，所以还是可变的
    _mutableNameCopy2 = @"bowen".mutableCopy;
    [_mutableNameCopy2 appendString:@"1"];
    
    self.mutableNameCopy2 = @"bowen".mutableCopy;
    [self.mutableNameCopy2 appendString:@"2"];
}

- (void)test0 {
    
    //原则，修改新旧对象，不影响旧新对象
    
    NSArray *arr1 = @[@1, @2, @3];
    NSArray *logArr1 = [arr1 copy];
    NSArray *logArr2 = [arr1 mutableCopy];
    NSLog(@"%p--%p--%p", arr1, logArr1, logArr2);
    NSLog(@"123");
    
    NSMutableArray *muArr1 = [NSMutableArray arrayWithObjects:@1,@2,@3, nil];
    NSMutableArray *logMuArr1 = [muArr1 mutableCopy];
    NSMutableArray *logMuarr2 = [muArr1 copy];
    NSLog(@"%p--%p--%p", muArr1, logMuArr1, logMuarr2);
    [logMuarr2 addObject:@4];
    NSLog(@"123");
    
}

- (void)test1 {
    
    NSString *temp = @"bowenzheng";
    NSMutableString *mutablestr = @"bowenzheng".mutableCopy;
    //浅拷贝(不可变=不可变）
    self.nameCopy1 = temp;
    NSLog(@"%p---%p",temp, self.nameCopy1);//指针复制
    
    //深拷贝(不可变 = 可变)
    self.nameCopy1 = mutablestr;
    NSLog(@"%p---%p",mutablestr, self.nameCopy1);//内存复制
    
    //浅拷贝（可变 = 不可变）
    self.mutableNameCopy2 = temp; // 声明类型可变，因为copy，真实对象是不可变
    NSLog(@"%p---%p",temp, self.mutableNameCopy2);
    
    //深拷贝(可变 = 可变)
    self.mutableNameCopy2 = mutablestr; // mutableNameCopy2 是不可变对象
    NSLog(@"%p---%p",mutablestr, self.mutableNameCopy2);
    
    //浅拷贝（不可变 = 可变）(strong 会被外界修改)
    self.nameStrong3 = mutablestr;
    NSLog(@"%p---%p",mutablestr, self.nameStrong3);
    [mutablestr appendString:@"1"];
    NSLog(@"%@---%@",mutablestr, self.nameStrong3);
    
    //深拷贝(可变 = 可变)
    self.mutableNameStrong4 = [mutablestr mutableCopy];
    NSLog(@"%p---%p",mutablestr, self.mutableNameStrong4);
    
    //浅拷贝(可变 = 不可变)(strong 崩溃)
    self.mutableNameStrong4 = temp;
    NSLog(@"%p---%p",temp, self.mutableNameStrong4);
    [self.mutableNameStrong4 appendString:@"2"];

    
}


@end

/*
 拷贝规律：不可变 + copy = 浅拷贝，其余均为深拷贝
 
 源对象           方法           结果类型            拷贝类型
 NSString        copy           NSString           浅拷贝
 NSString        mutableCopy    NSMutableString    深拷贝
 NSMutableString copy           NSString           深拷贝
 NSMutableString mutableCopy    NSMutableString    深拷贝
 
 最佳实践：
 - NSString   → copy   修饰（防止被可变字符串污染）
 - NSMutable  → strong 修饰 + 赋值时手动 mutableCopy（保证独立可变副本）
 - copy 属性通过 setter 中的 [value copy] 操作，强制将外部传入的对象转为一个不可变的副本，从而实现“值语义”般的封装，是防止可变状态意外共享的关键机制。
 
 NSArray、NSSet、NSDictionary 对比
 
 特性       NSArray       NSSet          NSDictionary
 有序       ✅ 有序        ❌ 无序        ❌ 无序
 重复       ✅ 允许        ❌ 自动去重     key不重复/value可重复
 访问方式    索引 arr[i]    只能遍历/has    key dict[key]
 查找值      O(n)          O(1)均摊       O(1)均摊
 底层       环形缓冲区       哈希表         哈希表
 存储内容    单值           单值           键值对
 
 NSSet 解决的三个关键问题
 问题一：查找性能 O(n) → O(1)
 问题二：自动去重
 问题三：集合运算（数学集合操作）
 
 环形缓冲区的核心思想：环形缓冲区 = 固定连续内存 + head/tail 两个指针 + 取模运算

 物理内存：  [_][_][_][_][_][_][_][_]
              0  1  2  3  4  5  6  7

 逻辑上看成一个"环"：

         0
     7       1
   6           2
     5       3
         4

 head 和 tail 在环上移动

 head/tail重合就扩容，避免覆盖
 
 */
