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
*/

@end
