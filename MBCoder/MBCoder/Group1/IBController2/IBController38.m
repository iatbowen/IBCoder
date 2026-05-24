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

 ============================================================
 iOS 架构模式 面试题总结
 ============================================================

 一、MVC
 ──────────────────────────────────────────

 【三层职责】
 - View       ：用户界面，负责展示内容和接收用户交互
 - Controller ：业务逻辑，持有 Model 和 View，负责协调两者通信
 - Model      ：数据层，负责数据存储、网络请求和业务规则

 【通信方式】
 - Model → Controller ：Notification / KVO
 - Controller → View  ：直接调用 / 属性赋值
 - View → Controller  ：delegate / target-action / block

 【理想化 MVC】
 Controller 持有 Model 和 View，Model 与 View 相互独立、互不持有 Controller。
 优点：View 和 Model 可独立复用
 缺点：Controller 容易承担过多职责，代码臃肿（Massive View Controller）

 【变种 MVC（iOS 常见写法）】
 View 持有 Model，直接根据 Model 渲染内容；VC 只负责组装和传递 Model。
 优点：对 Controller 瘦身，View 内部封装渲染细节，外界不感知实现
 缺点：View 与 Model 耦合，复用性降低
 解决：通过 Category（分类）让 View 持有 Model，将组装逻辑内聚在 View 内部


 ============================================================
 二、MVP
 ============================================================

 【三层职责】
 - View      ：UIView + UIViewController，只负责 UI 展示和转发用户事件，不含业务逻辑
 - Presenter ：中介层，持有 View（通过 Protocol）和 Model，处理所有业务逻辑
 - Model     ：数据层（网络 / 数据库 / 文件）

 【持有关系】
 View ←──── Presenter ────→ Model
 （View 和 Presenter 互相持有；Presenter 单向持有 Model）

 【与 MVC 的关键区别】
 MVC 中 ViewController 既是 Controller 又持有 View，业务与 UI 难以分离。
 MVP 中 ViewController 归属于 View 层，Presenter 通过 Protocol 与 View 通信，
 不持有具体 View 对象，Presenter 可单独做单元测试。

 优点：Model 与 View 完全分离；Presenter 可被多个 View 复用；易于单元测试
 缺点：View 每次变动需同步维护对应的 Protocol 接口，接口膨胀时维护成本高


 ============================================================
 三、MVVM
 ============================================================

 【三层职责】
 - Model     ：数据和业务逻辑，不关心 UI 展示
 - View      ：界面展示，通过数据绑定与 ViewModel 交互，不直接调用业务逻辑
 - ViewModel ：View 与 Model 的桥梁，暴露可观察数据和命令给 View，不持有 View 的引用

 【架构关系】
 ┌─────────┐  数据绑定    ┌────────────┐  调用    ┌─────────┐
 │  View   │ ←────────→  │ ViewModel  │ ─── ──→ │  Model  │
 │  (UI)   │  命令绑定    │ (状态/逻辑) │ ←─────── │ (数据)   │
 └─────────┘             └────────────┘  数据返回 └─────────┘

 【核心规则】
 ✅ View 可引用 ViewModel，反之不可（ViewModel 不持有 View）
 ✅ ViewModel 可引用 Model，反之不可
 ✅ ViewController 持有 ViewModel 实例

 【双向绑定原理】
 ViewModel 暴露可观察的数据，View 订阅变化后自动刷新 UI；
 View 的用户操作通过事件传递给 ViewModel 驱动 Model 更新。

 方向             含义                  实现机制
 Model → View    数据变化驱动 UI 更新    数据绑定（观察者）
 View → Model    UI 操作驱动数据变化     事件绑定 / 命令模式

 优点：低耦合；ViewModel 不依赖 UIKit，易于单元测试；数据绑定减少胶水代码
 缺点：数据绑定学习成本高；数据流链路长时难以追踪；小项目引入成本偏高


 ============================================================
 四、MVI
 ============================================================

 【核心思想】单一数据流 + 不可变状态

 【四个核心概念】
 - View   ：渲染 ViewState，将用户交互封装为 Intent 发出，不含任何逻辑
 - Intent ：用户意图的封装，描述"用户想做什么"，是状态变化的唯一入口
 - Model  ：承载完整的 UI 状态（ViewState），每次更新生成新的不可变状态对象
 - State  ：描述某一时刻 UI 的完整快照，包含页面所需的全部数据

 【单向数据流】
 Intent → Model（处理 Intent，生成新 State）→ View（渲染 State）→ Intent…

 【与 MVVM 的关键区别】
 - MVVM：View 直接调用 ViewModel 方法；状态可能分散在多个属性中
 - MVI ：View 只能发出 Intent，禁止直接调用方法；所有状态集中在单一 ViewState 对象
 - MVI 的状态不可变，每次更新生成新 State，支持历史状态回放，便于调试
 - 所有 Intent 汇总到一处，有利于行为监控和埋点分析

 iOS 实现：可结合 Combine / RxSwift 实现，Swift 中常配合 async/await 使用


 ============================================================
 五、Flux
 ============================================================

 【四个核心概念】
 - View       ：展示 Store 数据，响应 Store 更新触发重新渲染
 - Action     ：动作消息，包含 type（动作类型）和 payload（携带数据）
 - Dispatcher ：接收所有 Action，将其广播给所有 Store
 - Store      ：数据中心，响应 Action 更新状态，通知 View 重新渲染

 【单向数据流】
 View → Action → Dispatcher → Store → View（更新）

 Flux 解决了传统 MVC 中 Model 与 View 双向依赖导致的数据流混乱问题，
 强制所有状态变更必须经过 Dispatcher，使数据流向清晰可追踪。


 ============================================================
 六、Redux
 ============================================================

 Flux 的演进版本，在单向数据流基础上强调三个原则：

 1. 唯一数据源（Single Source of Truth）
    整个应用只有一个 Store，所有状态存在同一棵状态树中，便于调试和持久化。

 2. 状态只读（State is read-only）
    不直接修改 State，只能通过 dispatch(action) 触发状态变更，保证变更可追踪。

 3. 纯函数变更（Pure Reducer）
    reducer(state, action) → newState
    Reducer 是纯函数：相同输入必然产生相同输出，无副作用，极易测试和回放。
    入参 state 是当前状态，action 是动作对象；必须返回全新 state，不能修改原有对象。

 iOS 实现：ReSwift 库是 Redux 思想的 Swift 实现，适合需要全局状态管理的应用。


 ============================================================
 七、VIPER
 ============================================================

 【五层职责】
 - View       ：展示 UI，将用户事件转发给 Presenter，不含任何业务/数据逻辑
 - Interactor ：业务逻辑层，处理 Use Case（用例），与 Entity 交互获取数据，不依赖 UIKit
 - Presenter  ：协调层，从 Interactor 取数据后格式化，驱动 View 展示；调用 Router 跳转
 - Entity     ：纯数据模型，只有数据结构，不含业务逻辑
 - Router     ：路由层，负责模块间页面跳转，Presenter 通过 Router 触发导航

 【数据流向（严格单向）】
 用户交互 → View → Presenter → Interactor → Entity（获取数据）
                      ↑              ↓（回调结果）
                   View 刷新 ←── Presenter（格式化数据后驱动 View）
                      ↓
                   Router（需要跳转时触发）

 【与 MVC/MVVM 的关键区别】
 - 单一职责彻底落地：每一层只做一件事，职责边界极其清晰
 - Interactor 纯 Swift/ObjC 逻辑，完全不依赖 UIKit，单元测试极为友好
 - Router 层解耦模块跳转，各模块互不依赖，适合大型团队多人并行开发

 优点：职责单一，可测试性最强，适合大型复杂项目
 缺点：一个页面通常需要 5+ 个文件 + 多个 Protocol，小项目成本极高


 ============================================================
 八、MVC 的 Massive ViewController 问题与瘦身方案
 ============================================================

 【问题根源】
 iOS 中 UIViewController 承担了过多职责：
 网络请求、数据解析、业务逻辑、布局计算、事件响应、生命周期管理……
 导致 VC 动辄数千行，难以维护和测试。

 【常见瘦身方案】
 1. 抽取独立的 DataSource / Delegate 对象
    将 UITableView 的 dataSource 封装为单独的类，VC 只负责创建和持有

 2. 抽取业务逻辑到 Service / Manager / UseCase 层
    网络请求、本地存储、数据加工逻辑从 VC 中抽离

 3. 使用 Category（分类）拆分 VC 功能模块
    按功能域拆分（如 +Network、+TableView、+Layout），一个 VC 多个文件

 4. 升级为 MVP / MVVM
    将展示逻辑移入 Presenter / ViewModel，VC 只剩 UI 组装和绑定


 ============================================================
 九、MVVM 在 iOS 中的双向绑定实现方式
 ============================================================

 1. KVO + KVOController（Facebook 开源）
    手动注册 keyPath 观察；KVOController 解决了原生 KVO 忘记 removeObserver 导致崩溃的问题。
    本文件代码即采用此方式监听 viewModel.selectedData：
    [self.KVOController observe:self.viewModel keyPath:@"selectedData" ...]

 2. ReactiveCocoa（RAC）
    函数响应式编程（FRP）框架，通过 RACSignal 实现声明式数据流绑定：
    RAC(self.label, text) = RACObserve(self.viewModel, title);

 3. RxSwift
    Swift 版 FRP 框架，通过 Observable / Subject 实现绑定：
    viewModel.title.bind(to: label.rx.text).disposed(by: bag)

 4. Combine（Apple 官方，iOS 13+）
    原生 FRP 框架，通过 Publisher / Subscriber 实现绑定：
    viewModel.$title.receive(on: RunLoop.main).assign(to: \.text, on: label)

 5. 手动 Closure 回调（轻量级，无三方依赖）
    ViewModel 暴露 var onTitleChanged: ((String) -> Void)?
    数据变化时执行 closure，View 层在 closure 中更新 UI


 ============================================================
 十、各架构横向对比
 ============================================================

 ┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
 │  维度    │   MVC    │   MVP    │   MVVM   │  VIPER   │   MVI    │
 ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
 │ 复杂度   │  低      │  中      │  中      │  高      │  中高    │
 ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
 │ 可测试性  │  低      │  高      │  高      │  最高    │  高      │
 ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
 │ 耦合度   │  高      │  低      │  低      │  最低    │  低      │
 ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
 │ 文件数量  │  少      │  较多    │  较多    │  很多    │  较多    │
 ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
 │ 数据流向  │  双向    │  双向    │  双向绑定 │  单向    │  严格单向 │
 ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
 │ 适用场景  │ 小型项目  │ 中型项目  │ 中大型   │ 大型项目  │ 复杂状态  │
 └──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘


 ============================================================
 十一、如何选择架构
 ============================================================

 - 小型 / 快速迭代项目  → MVC，开发速度最快，团队上手成本低
 - 需要单元测试        → MVP 或 MVVM，Presenter / ViewModel 不依赖 UIKit，易于独立测试
 - 数据驱动 UI 较重    → MVVM + Combine / RxSwift，数据绑定减少模板代码
 - 大型团队 / 多人协作  → VIPER，职责边界明确，各层可并行开发，互不阻塞
 - 复杂页面状态管理    → MVI，状态不可变、可回放，便于调试历史状态
 - 全局状态共享场景    → Redux（ReSwift），集中状态管理，适合多模块共享数据

 ⚠️ 没有最好的架构，只有最适合当前团队和项目规模的架构。
    过度设计（如小项目用 VIPER）比 MVC 臃肿更难维护。

*/
