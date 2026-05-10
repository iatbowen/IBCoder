//
//  IBController10.m
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
 一、关联对象 API

 // 设置
 objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy)
 // 获取
 objc_getAssociatedObject(id object, const void *key)
 // 移除所有关联（通常在 dealloc 里不需要手动调，对象销毁时 runtime 自动清理）
 objc_removeAssociatedObjects(id object)

 关联策略（objc_AssociationPolicy）：
 策略                              语义
 OBJC_ASSOCIATION_ASSIGN           弱引用（unsafe_unretained，不置 nil，慎用）
 OBJC_ASSOCIATION_RETAIN_NONATOMIC strong，非原子（最常用）
 OBJC_ASSOCIATION_COPY_NONATOMIC   copy，非原子
 OBJC_ASSOCIATION_RETAIN           strong，原子
 OBJC_ASSOCIATION_COPY             copy，原子

 二、关联对象底层数据结构

 // 全局唯一管理器，内含自旋锁保证线程安全
 class AssociationsManager {
     static AssociationsHashMap *_map;  // 全局哈希表（单例）
 };

 // 对象地址 → 该对象的关联数据表
 class AssociationsHashMap : public unordered_map<disguised_ptr_t, ObjectAssociationMap *> {};

 // key（void*，通常是静态变量地址/selector）→ 关联值包装
 class ObjectAssociationMap : public std::map<void *, ObjcAssociation> {};

 // 单条关联数据：存 policy + value
 class ObjcAssociation {
     uintptr_t _policy;
     id _value;
 };

 查找路径（objc_getAssociatedObject）：
   AssociationsManager（加锁）
     → AssociationsHashMap（以 object 地址查）
       → ObjectAssociationMap（以 key 查）
         → ObjcAssociation.value（解锁，返回）
   任一层找不到则返回 nil

 对象销毁时（dealloc）：
   runtime 自动遍历该对象的 ObjectAssociationMap，按 policy 对每个 value 执行 release/free，无需手动清理

 三、关联对象为何不支持 weak 策略

 - AssociationsHashMap 只支持「持有者 → key → value」正向查找
 - weak 需要反向：当 value 对象销毁时，找到所有指向它的弱引用并置 nil
 - 哈希表扩容时对象地址会变化，无法可靠做反向遍历

 四、weak 底层实现

 1. 编译器层：Clang 把 weak 操作改写为 runtime 调用
   __weak id obj = someObject;   → objc_initWeak(&obj, someObject)
   obj = other;                  → objc_storeWeak(&obj, other)
   id tmp = obj;                 → id tmp = objc_loadWeak(&obj)
   // 变量超出作用域时       → objc_destroyWeak(&obj)

 2. Runtime 层：全局 weak 表（SideTable → weak_table_t）

   // 全局 SideTable 数组（64 个），以对象地址哈希分桶
   struct SideTable {
       spinlock_t slock;
       RefcountMap refcnts;    // 引用计数表
       weak_table_t weak_table;
   };

   struct weak_table_t {
       weak_entry_t *weak_entries; // 哈希数组
       size_t num_entries;
   };

   struct weak_entry_t {
       DisguisedPtr<objc_object> referent; // 被弱引用的对象
       // 指向该对象的所有 weak 指针地址（定长内联数组 or 动态数组）
       union { objc_object **referrers; struct { ... } inline_referrers; };
   };

   查找路径：
     SideTablesMap → SideTable（对象地址哈希）→ weak_table_t → weak_entry_t → weak 指针地址列表

 3. 自动置 nil 流程（对象 dealloc 时）
   ① objc_object::rootDealloc → weak_clear_no_lock
   ② 以对象地址为 key，在 weak_table 中找到 weak_entry_t
   ③ 遍历所有 weak 指针地址，逐一置 *ptr = nil
   ④ 从 weak_table 中移除该 entry

 五、weak 与关联对象对比

 维度         weak                             关联对象
 关注点        谁在引用我                        我能挂载什么额外数据
 生命周期      不影响被引用者；被引用者销毁后置 nil   随宿主对象销毁而自动释放
 查找方向      反向（被引用者 → 所有引用者）         正向（宿主 → key → value）
 线程安全      SideTable 自旋锁保护               AssociationsManager 自旋锁保护

 六、关联对象 key 的四种常见写法

 1. 静态变量地址（推荐）
    static const void *kKey = &kKey;
    优点：唯一性强，编译期确定

 2. @selector(propertyName)
    objc_setAssociatedObject(obj, @selector(name), value, ...)
    优点：简洁，利用 SEL 地址作 key，name 即 getter selector

 3. _cmd（在方法内部）
    - (id)property { return objc_getAssociatedObject(self, _cmd); }
    优点：极简，_cmd 就是当前方法的 SEL，无需额外变量

 4. &_cmd / 字符串字面量地址
    不推荐，字符串常量地址可能被优化合并，存在风险

 ============================================================
 七、常见面试问答
 ============================================================

 Q：关联对象存储在哪里？对象销毁时如何释放？
 A：存储在全局的 AssociationsHashMap（AssociationsManager 持有），以对象地址为 key，
    不在对象本身的内存中。对象调用 dealloc 时，runtime 会调用 _object_remove_assocations，
    遍历该对象的 ObjectAssociationMap，按 policy 对每个 value 执行对应的 release/free，
    无需在 dealloc 中手动调 objc_removeAssociatedObjects。

 Q：为什么关联对象没有 weak 策略？如何实现 weak 关联？
 A：AssociationsHashMap 是正向查找（宿主 → key → value），不支持反向追踪。
    weak 要求被引用对象销毁时反向找到所有引用并置 nil，结构上无法做到。
    实现 weak 关联的方案：用中间 WeakBox 容器包装 weak 指针，
    将容器以 RETAIN 策略关联到宿主，通过 box.weakObj 间接获得 weak 语义。

 Q：weak 变量为何能在对象销毁后自动置 nil？
 A：objc_storeWeak 将 weak 指针地址（**ptr）注册到对象对应的 weak_table_t 中。
    对象 dealloc 时，objc_clearDeallocating 遍历 weak_entry_t 中所有 weak 指针地址，
    依次执行 *ptr = nil，然后从 weak_table 中移除该 entry。
    关键点：置的是指针本身所在的内存（**ptr），而不是指针指向的对象。

*/

@end
