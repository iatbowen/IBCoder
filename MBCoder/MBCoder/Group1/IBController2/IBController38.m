//
//  IBController38.m
//  IBCoder1
//
//  Created by Bowen on 2018/7/27.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController38.h"
#import <KVOController.h>

/*************************模型*****************************/

@interface CellModel : NSObject
 
@property (nonatomic, copy) NSString *title;
  
@end
 
@implementation CellModel

@end

/*************************cell声明*****************************/

@interface TableViewCell : UITableViewCell
 
@property (nonatomic, weak) UILabel *lable;
@property (nonatomic, strong) CellModel *model;

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end

/*************************视图模型*****************************/

@interface CellViewModel : NSObject

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSString *selectedData;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (TableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation CellViewModel
  
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}
 
- (void)setupData
{
    self.dataSource = @[].mutableCopy;
    for (int i = 0; i < 20; i++) {
        CellModel *model = [[CellModel alloc] init];
        model.title = [NSString stringWithFormat:@"标题%d", i];
        [self.dataSource addObject:model];
    }
}
  
- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}
 
- (TableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCell *cell = [TableViewCell cellWithTableView:tableView];
    cell.model = self.dataSource[indexPath.row];
    return cell;
}
 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *str = [NSString stringWithFormat:@"点击了第%ld行", (long)indexPath.row];
    self.selectedData = str;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

@end

/*************************视图*****************************/
 
@implementation TableViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self);
}
 
+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self identifier]];
    if (!cell) {
        cell = [[TableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[self identifier]];
    }
    return cell;
}
 
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, 30)];
        label.font = [UIFont systemFontOfSize:20.0f];
        [self.contentView addSubview:label];
        self.lable = label;
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}
 
- (void)setModel:(CellModel *)model
{
    _model = model;
    self.lable.text = model.title;
}

@end

@interface IBController38 ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CellViewModel *viewModel;
@property (nonatomic, strong) UILabel *toastLabel;

@end

@implementation IBController38

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.viewModel = [[CellViewModel alloc] init];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    self.toastLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-75, 100, 150, 30)];
    self.toastLabel.alpha = 0.0;
    self.toastLabel.textAlignment = NSTextAlignmentCenter;
    self.toastLabel.layer.cornerRadius = 5;
    self.toastLabel.layer.masksToBounds = YES;
    self.toastLabel.backgroundColor = UIColor.blackColor;
    self.toastLabel.textColor = UIColor.whiteColor;
    [self.view addSubview:self.toastLabel];

    [self.KVOController observe:self.viewModel keyPath:@"selectedData" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary<NSString *,id> * change) {
        [self showToast:change[@"new"]];
    }];
}

- (void)showToast:(NSString *)toast
{
    self.toastLabel.text = toast;
    [UIView animateWithDuration:0.25 animations:^{
        self.toastLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            self.toastLabel.alpha = 0.0;
        }];
    }];
    
}
 
#pragma mark - UITableViewDataSource
 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.viewModel numberOfItemsInSection:section];
}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}
 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.viewModel tableView:tableView didSelectRowAtIndexPath:indexPath];
}
 
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}
 
@end

/*
 一、MVC:
 视图（View）：用户界面.
 控制器（controller）：业务逻辑
 模型（Model）： 数据保存
 
 1、理想化的MVC
 相互联系：
 Controller持有Model和View，
 Model和View相互独立，都不持有Controller。
 通信方式：
 Model改变通过Notification和KVO的方式传递给Controller，Controller跟新View。
 View接受响应事件则通过delegate，target-action，block等方式告诉Controller，Controller跟新Model。
 优缺点：
 优点：View和Model可以重复利用，可以独立使用
 缺点：Controller的代码过于臃肿
 
 2、变种的MVC
 相互联系：
 View持有了Model，View依据Model来展示数据，VC组装Model，组装展示是在View中实现。
 优缺点：
 优点：对Controller进行瘦身，将View的内部细节封装起来了，外界不知道View内部的具体实现
 缺点：View依赖于Model
 解决办法：
 通过让View分类持有Model，组装数据

 二、MVP
 V层：UIView和UIViewController以及子类
 P层：中介(关联M和V)，业务逻辑，负责调用数据加载，然后再通过界面接口，将数据模型组合传递给V去展示
 M层：数据层(数据:数据库,网络,文件等等)
 
 相互关系：
 V层和P层之间是相互持有的关系，P层单向持有M层
 
 优缺点：
 优点：模型与视图完全分离；presenter可以被多个视图复用
 缺点：V层和P层关联，V层更新P层也需要更新
 
 三、MVVM（比MVP多了双向绑定）
 1. 三大核心组件
 - Model(模型)：负责数据和业务逻辑，不关心 UI 如何展示
 - View(视图)：负责界面展示，只关注用户界面和交互，通过数据绑定与 ViewModel 交互,不直接调用业务逻辑
 - ViewModel(视图模型)：View 与 Model 之间的桥梁，暴露数据和命令(Command)给 View，处理 View 的展示逻辑,但不持有 View 的引用
 
 2.架构关系图
 ┌─────────┐  数据绑定    ┌────────────┐  调用    ┌─────────┐
 │  View   │ ←────────→  │ ViewModel  │ ───────→ │  Model  │
 │  (UI)   │  命令绑定    │ (状态/逻辑) │ ←─────── │ (数据)  │
 └─────────┘             └────────────┘  数据返回 └─────────┘
 
 3. 核心规则
 规则                                 说明
 ✅ View → ViewModel                 View 可引用 ViewModel,反之不可
 ✅ ViewModel → Model                ViewModel 可引用 Model,反之不可
 ✅ ViewController 拥有 ViewModel     VC 持有 VM 实例
 ✅ ViewModel 之间可依赖               支持组合复用
 
 4. ViewModel 的双向绑定
 ViewModel 是 View 与 Model 的桥梁,通过 Observer(观察者) 实现双向通信:
 
 ┌──────────────────────────────────┐
 │          ViewModel               │
 │  ┌────────────────────────────┐  │
 │  │  Observable 可观察数据       │  │
 │  └────────────────────────────┘  │
 └────▲──────────────────────▲──────┘
      │ 监听数据变化           │ 监听UI事件
      │ (数据绑定)            │ (事件监听)
 ┌────┴──────────┐      ┌────┴──────────┐
 │     View      │      │    Model      │
 │  (UI 显示)     │      │  (数据存储)    │
 └───────────────┘      └───────────────┘


 方向             含义                  实现方式
 Model → View    数据变化驱动 UI 更新    数据绑定
 View → Model    UI 操作驱动数据变化     事件监听

 5. 优缺点：
 优点：低耦合，可重用性，可测试
 缺点：数据绑定使得 MVVM 变得复杂和难用

 四、MVI
 强调单一数据流和不可变状态。MVI 的核心思想是通过 Intent 驱动状态变化，并用单一的状态对象来描述整个 UI。
 1、Model 职责：处理数据逻辑，包括从网络或数据库获取数据。
 2、View 职责：展示 UI 并响应用户交互，渲染单一的状态对象。
 3、Intent 职责：用户意图的封装，触发状态变化。
 4、State 职责：表示 UI 的单一状态。
 
 MVI 强调数据的单向流动，主要分为以下几步：
 1、用户操作以 Intent 的形式通知 Model
 2、Model 基于 Intent 更新 State
 3、View 接收到 State 变化刷新 UI。
 
 与MVVM主要区别在 于 Model 与 View 层交互的部分
 Model 层承载 UI 状态，并暴露出 ViewState 供 View 订阅，ViewState 是个 data class,包含所有页面状态
 View 层通过 Intent 更新 ViewState，替代 MVVM 通过调用 ViewModel 方法交互的方式
 通过 Intent 通信，有利于 View 与 ViewModel 之间的进一步解耦，同时所有调用以 Intent 的形式汇总到一处，也有利于对行为的集中分析和监控
 
 五、Flux
 基本概念
 View： 应用视图，可展示Store数据，并实时响应Store的更新。
 Action（动作）：动作消息，包含动作类型与动作描述。
 Dispatcher（派发器）：接收到Action，并将它们发送给Store
 Store（数据层）：数据中心，持有应用程序的数据，并会响应Action消息
 
 Flux 的最大特点，就是数据的"单向流动"。
 1、视图产生动作消息，将动作传递给调度器
 2、调度器将动作消息发送给每一个数据中心
 3、数据中心再将数据传递给视图

 六、Redux
 Flux的基本原则是“单向数据流”，Redux在此基础上强调三个基本原则：
 1、唯一数据源（Single Source of Truth）：整个应用只保持一个Store，所有组件的数据源就是这个Store上的状态。
 2、保持状态只读（State is read-only）：不直接修改状态，要修改Store的状态，必须要通过派发一个action对象完成。
 3、数据改变只能通过纯函数完成（Changes are made with pure funtions）：这里所说的纯函数是指reducer。reducer函数接受两个参数：reducer(state,action)。
   第一个参数state是当前的状态，第二个参数action是收受到的action对象，
   reducer函数要做个事情就是根据state和action的值产生一个新的对象返回（返回的结果必须完全由参数state和action决定，而且不应产生任何副作用）。
 
*/
