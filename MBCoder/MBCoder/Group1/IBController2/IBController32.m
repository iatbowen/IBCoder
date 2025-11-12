//
//  IBController32.m
//  IBCoder1
//
//  Created by Bowen on 2018/6/1.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController32.h"
#import "GCDQueue.h"

@interface IBController32 ()

@end

@implementation IBController32

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"关联属性,关联对象";
    self.view.backgroundColor = [UIColor whiteColor];
//    连接：https://draveness.me/ao
    
}


/*
 
 一、关联对象原理
 
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
 解决办法：
 通常的做法是创建一个中间对象来持有弱引用，然后将中间对象与关联属性关联起来。

 */

@end
