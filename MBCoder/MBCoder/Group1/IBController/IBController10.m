//
//  IBController9.m
//  IBCoder1
//
//  Created by Bowen on 2018/5/3.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController10.h"
#import "GCDQueue.h"

@interface IBController10 ()

@end

@implementation IBController10

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"关联对象和weak属性";
    self.view.backgroundColor = [UIColor whiteColor];
//    连接：https://draveness.me/ao
    
}


/*
 
 一、关联策略（objc_AssociationPolicy）
 常用选项：
 OBJC_ASSOCIATION_ASSIGN（弱引用/unsafe_unretained）
 OBJC_ASSOCIATION_RETAIN_NONATOMIC（强引用，非原子）
 OBJC_ASSOCIATION_COPY_NONATOMIC（拷贝，非原子）
 OBJC_ASSOCIATION_RETAIN（强引用，原子）
 OBJC_ASSOCIATION_COPY（拷贝，原子）

 
 二、底层实现原理
 
 1、实现关联对象技术的核心对象
 
 1）AssociationsManager
 
 class AssociationsManager {
     static AssociationsHashMap *_map;
 public:
     AssociationsManager()   { AssociationsManagerLock.lock(); }
     ~AssociationsManager()  { AssociationsManagerLock.unlock(); }
     
     AssociationsHashMap &associations() {
         if (_map == NULL)
             _map = new AssociationsHashMap();
         return *_map;
     }
 };
 
 2）AssociationsHashMap
 
 class AssociationsHashMap : public unordered_map<disguised_ptr_t, ObjectAssociationMap *> {
 };
 
 3）ObjectAssociationMap
 
 class ObjectAssociationMap : public std::map<void *key, ObjcAssociation> {

 };
 
 4）ObjcAssociation
 
 class ObjcAssociation {
     uintptr_t _policy;
     id _value;
 };

 4）解释：
 - 映射关系
 AssociationsHashMap：  对象地址 (id) → 关联数据存储结构 (ObjectAssociationMap)
 ObjectAssociationMap：  key (void*，常用 selector 或静态地址) → value（包装了对象、policy 等）

 - 关联对象存储在全局的统一的一个AssociationsManager中，如果设置关联对象为nil，就相当于是移除关联对象。
 - AssociationsManager的构造函数和析构函数有自旋锁，控制存储值线程安全
 
 5）关联对象无弱引用的原因:
 关联对象的实现并没有包含跟踪对象生命周期并自动清空弱引用的机制
 关联对象完全是运行时层面的动态机制，不适合再加一套自动清零弱引用系统，成本和复杂度太高
 解决办法：
 通常的做法是创建一个中间对象来持有弱引用，然后将中间对象与关联属性关联起来。
 
 
 三、weak 底层实现
 “真正 weak”需要编译器 + runtime 合作维护弱引用表
 
 1. 编译器层：把 weak 操作改写成 runtime 函数
 原始代码：
 __weak id obj = someObject;
 obj = nil;
 id tmp = obj;
 
 编译后不会直接是简单的指针赋值，而会被 Clang 改写成对 runtime 的调用，大致类似：
 id obj;
 objc_initWeak(&obj, someObject);   // 初始化 weak 变量
 objc_storeWeak(&obj, nil);         // 赋值（包括置 nil）
 id tmp = objc_loadWeak(&obj);      // 读 weak 值
 objc_destroyWeak(&obj);            // 变量销毁时调用
 常见的 weak 相关 runtime API（在 objc-weak.h/NSObject.mm 里）：

 objc_initWeak(id *location, id value)
 objc_storeWeak(id *location, id value)
 objc_loadWeak(id *location)
 objc_destroyWeak(id *location)
 结论：
 编译器负责识别哪些变量是 weak，并在所有赋值/销毁位置插入这些函数调用； runtime 负责具体维护数据结构和清零指针。
 
 
 2. Runtime 层：全局 weak 表（weak table）
 weak策略表明该属性定义了一种“非拥有关系” (nonowning relationship)。为这种属性设置新值时，设置方法既不保留新值，也不释放旧值。

 struct weak_table_t {
     weak_entry_t *weak_entries; // 哈希表数组
     size_t num_entries;
     spinlock_t lock;
 };

 struct weak_entry_t {
     DisguisedPtr<objc_object> referent; // 被弱引用的对象
     union {
         objc_object **referrers; // 指向这个对象的 weak 指针地址数组
         struct { ... } inline_referrers;
     };
     // referrers + referrers_count + capacity 等
 };
 
 存储映射关系
 (静态变量)SideTablesMap->(对象地址找到)SideTable->weak_table_t（以对象地址hash算法找索引，取出weak_entry_t）
 ->weak_entry_t（定长数组，动态数组（以弱指针的地址hash算法找索引，取出weak_referrer_t））-> weak_referrer_t
 
 3. 那么runtime如何实现weak变量的自动置nil？
 runtime对注册的类，会将 weak 对象放入一个hash表中。用weak指向的对象内存地址作为key，当此对象的引用计数为0的时候会调
 用对象的dealloc方法，假设weak指向的对象内存地址是a，那么就会以a为key，在这个weak hash表中搜索，找到所有以a为key的weak对象，
 从而设置为 nil。
 
 
 四、对比
 weak —— 强调的是“我被谁引用”，并且我销毁时，所有引用立刻失效（自动归零）。强调自己
 关联对象 —— 强调“我能动态扩展什么属性”，随时可给对象加功能。宿主对象销毁，关联对象才会销毁。强调宿主对象
 
 
 */

@end

