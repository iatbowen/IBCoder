//
//  IBController16.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/9.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController16.h"
#import "Son.h"

@interface IBKVOExp : NSObject

@property (nonatomic, copy) NSString *name;

@end

@implementation IBKVOExp

@end

@interface IBController16 ()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) IBKVOExp *kvoExp;

@end

/*
 https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOImplementation.html
 一、KVO底层实现原理
 1. KVO的底层流程
 注册观察者
 当你调用 addObserver:forKeyPath:options:context: 方法时，KVO 会做以下工作：
 - 判断被观察对象的类（实际类型）。
 - 动态创建一个名为 NSKVONotifying_原有类名 的子类（以被观察对象的类名为前缀）。
 - 将被观察对象的 isa 指针，指向这个新建的子类。
 - 子类重写对应被观察属性的 setter 方法，实现属性变化时自动通知观察者。
 
 属性改变
 当被观察属性的 setter 方法被调用（如 person.name = @"Tom"），实际调用的是 NSKVONotifying_Person 子类中的 setter：
 - 子类 setter 先调用 willChangeValueForKey:。
 - 然后执行父类的 setter 方法，真正修改值。
 - 最后调用 didChangeValueForKey:，触发通知观察者。
 
 通知过程
 属性值改变后，通过调用注册的观察者回调 observeValueForKeyPath:ofObject:change:context:。

 移除观察者
 调用 removeObserver:forKeyPath: 后，KVO 会恢复对象的 isa 指针指向原来的类，销毁动态子类。

 2. 主要技术点解释
 isa-swizzle
 - KVO 把对象的类型从原类“切换”为 KVO 动态生成的子类，实现方法拦截。这是 Objective-C Runtime 的强大功能。

 动态子类
 - 这个子类只针对当前被观察对象，具有自己的 setter、dealloc 等实现，因此能区分哪些对象在接受观察。

 setter方法重写
 - 其核心就是对 setter 方法拦截，调用通知流程。
 
 补充：KVO的这套实现机制中苹果还偷偷重写了class方法，让我们误认为还是使用的当前类，从而达到隐藏生成的派生类
 
 二、KVC底层实现原理
 KVC（Key-Value Coding，键值编码）是 iOS/Objective-C 一种可以通过字符串 key 来访问对象属性的机制，其底层实现原理涉及方法查找、成员变量查找、Runtime 动态访问等
 
 分为三大步
 - 查找 setter 方法：优先查找是否存在 set<Key>:，其次查找 _set<Key>:，最后查找 setIs<Key>:
 - 查找成员变量：判断 accessInstanceVariablesDirectly，返回 YES 时才允许成员变量的直接访问_key，_isKey，key，isKey
 - 未找到则触发异常：- (void)setValue:(id)value forUndefinedKey:(NSString *)key，你重载该方法，可以自行处理

 注意:禁止使用KVC修改只读属性，使用如下方法
 + (BOOL)accessInstanceVariablesDirectly {
    return NO;
 }
 
 */

@implementation IBController16

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    self.kvoExp = [[IBKVOExp alloc] init];
    [self.kvoExp addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    self.kvoExp.name = @"123";
    
    Son *son = [[Son alloc] init];
    [son setValue:@"xiaolan" forKey:@"_girlfriend"];
//    [son setValue:@(2) forKey:@"_parents"];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.name = @"456";
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@",object);
}

- (void)dealloc
{
    [self.kvoExp removeObserver:self forKeyPath:@"name"];
    [self removeObserver:self forKeyPath:@"name"];
}


@end
