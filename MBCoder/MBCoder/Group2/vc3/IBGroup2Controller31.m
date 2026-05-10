//
//  IBGroup2Controller31.m
//  MBCoder
//
//  Created by 叶修 on 2024/10/24.
//  Copyright © 2024 inke. All rights reserved.
//

#import "IBGroup2Controller31.h"
#import "MBStateMachine.h"
#import "MBState.h"
#import "MBEvent.h"
#import "MBTransition.h"

@interface IBGroup2Controller31 ()

@end

@implementation IBGroup2Controller31

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self testTheTrafficLights];
}

/* 红绿灯状态机示例
 状态迁移：Green → Yellow → Red → Yellow → Green（循环）
 事件驱动：warn（绿→黄）/ stop（黄→红）/ ready（红→黄）/ go（黄→绿）
 */
- (void)testTheTrafficLights {

    // 1. 初始化状态机
    MBStateMachine *stateMachine = [[MBStateMachine alloc] init];

    // 2. 定义状态
    MBState *green  = [MBState stateWithName:@"green"];
    MBState *yellow = [MBState stateWithName:@"yellow"];
    MBState *red    = [MBState stateWithName:@"red"];

    [stateMachine addStates:@[green, yellow, red]];
    stateMachine.initialState = green;

    // 3. 定义事件（State × Event → NextState）
    MBEvent *warn  = [MBEvent eventWithName:@"warn"  transitioningFromStates:@[green]  toState:yellow];
    MBEvent *stop  = [MBEvent eventWithName:@"stop"  transitioningFromStates:@[yellow] toState:red];
    MBEvent *ready = [MBEvent eventWithName:@"ready" transitioningFromStates:@[red]    toState:yellow];
    MBEvent *go    = [MBEvent eventWithName:@"go"    transitioningFromStates:@[yellow] toState:green];

    [stateMachine addEvents:@[warn, stop, ready, go]];

    // 4. 启动状态机
    [stateMachine activate];

    // 5. 注册事件回调
    [warn  setDidFireEventBlock:^(MBEvent *e, MBTransition *t) { NSLog(@"warn  fired: green  → yellow"); }];
    [stop  setDidFireEventBlock:^(MBEvent *e, MBTransition *t) { NSLog(@"stop  fired: yellow → red");    }];
    [ready setDidFireEventBlock:^(MBEvent *e, MBTransition *t) { NSLog(@"ready fired: red    → yellow"); }];
    [go    setDidFireEventBlock:^(MBEvent *e, MBTransition *t) { NSLog(@"go    fired: yellow → green");  }];

    // 6. 合法性检查 + 触发事件
    if ([stateMachine canFireEvent:warn]) {
        [stateMachine fireEvent:warn  userInfo:nil error:nil];
        [stateMachine fireEvent:stop  userInfo:nil error:nil];
        [stateMachine fireEvent:ready userInfo:nil error:nil];
        [stateMachine fireEvent:go    userInfo:nil error:nil];
    }
}

@end


/*

 ============================================================
 有限状态机（FSM）面试题总结
 ============================================================

 一、概念与核心要素
 ──────────────────────────────────────────

 【定义】
 有限状态机（Finite-State Machine，FSM）是一种数学计算模型，
 用于描述系统在有限个状态之间的转移行为。

 【三个基本特征】
 1. 状态总数有限（Finite States）
 2. 任意时刻只处于唯一一种状态
 3. 在特定条件（事件）下，从一种状态迁移到另一种状态

 【四个核心要素】
 现态（Current State）    ：系统当前所处的状态
 事件（Event）            ：触发状态迁移的条件或输入
 动作（Action）           ：事件发生时执行的操作（可选）
 次态（Next State）       ：迁移后进入的新状态

 【五个组成部分】
 State（状态）            ：系统可处于的所有情况集合（至少两个）
 Event（事件）            ：引发状态转换的内部或外部触发
 Transition（转换）       ：从一个状态到另一个状态的迁移规则
 Initial State（初始状态）：状态机启动时所处的状态
 Final State（终止状态）  ：状态机可结束的状态（非必须）


 ============================================================
 二、两种经典类型
 ============================================================

 【Moore 状态机】
 输出仅取决于当前状态，与触发事件无关。
 特点：状态转移逻辑和输出逻辑分离，结构清晰，易于测试。
 示例：红绿灯（灯的颜色只由当前状态决定，与触发事件无关）

 【Mealy 状态机】
 输出取决于当前状态和触发事件的组合。
 特点：用更少的状态表达更多行为，但逻辑耦合在转换上，相对复杂。
 示例：自动售货机（找零金额取决于当前余额状态 + 本次投入金额事件）

 实际开发中两者常混用，MBStateMachine 等库多为 Mealy 风格。


 ============================================================
 三、三种实现方式
 ============================================================

 【方式一：switch-case 枚举（最简单）】
 用枚举表示状态，在事件处理函数中用 switch-case 分发逻辑。

 typedef NS_ENUM(NSInteger, TrafficLightState) {
     TrafficLightStateGreen,
     TrafficLightStateYellow,
     TrafficLightStateRed,
 };

 - (void)handleEvent:(TrafficLightEvent)event {
     switch (self.currentState) {
         case TrafficLightStateGreen:
             if (event == EventWarn) self.currentState = TrafficLightStateYellow;
             break;
         // ... 其他状态
     }
 }

 优点：实现简单，状态少时直观
 缺点：状态和事件增多后，switch 嵌套爆炸，难以维护

 【方式二：状态模式（State Pattern，面向对象）】
 将每个状态封装为独立的类，状态类持有 Context（状态机）引用，
 自行决定如何响应事件并触发迁移，符合开闭原则。

 优点：各状态职责单一，扩展性强（新增状态只加类），符合 OCP
 缺点：状态类数量多，对象创建开销大，迁移关系分散在各状态类中

 【方式三：状态转移表（Table-Driven，推荐用于复杂场景）】
 用二维表（State × Event → NextState + Action）驱动状态机，将逻辑数据化。
 MBStateMachine、TKStateMachine 等框架均基于此思路。

 优点：逻辑与执行分离，所有迁移规则集中在表中，一目了然，支持动态配置
 缺点：初始配置较繁琐，极简场景下引入表结构有点重


 ============================================================
 四、层次状态机（Hierarchical State Machine，HSM）
 ============================================================

 【概念】
 状态可以包含子状态机（嵌套状态），父状态定义通用行为，子状态覆盖或扩展特定行为。
 未被子状态处理的事件会"冒泡"到父状态处理，类似 OOP 的继承机制。

 【优点】
 避免状态爆炸：平铺 FSM 需要 n × m 个状态节点，HSM 只需 n + m 个
 公共行为复用：多个子状态共享的逻辑定义在父状态中，无需重复

 【示例：音视频播放器】
 Playing（父状态）
   ├── Normal（正常播放）
   ├── Buffering（缓冲中）
   └── Seeking（跳转中）
 Paused（父状态）
 Stopped（父状态）

 Playing 父状态处理"暂停"事件 → 三个子状态均能响应，无需各自重复实现。
 Seeking 子状态处理"跳转完成"事件 → 回到 Normal，父状态不需要知道细节。


 ============================================================
 五、FSM 在 iOS 中的典型应用场景
 ============================================================

 1. 音视频播放器状态管理
    Idle → Loading → Buffering → Playing → Paused → Stopped → Error
    各状态控制 UI 展示（菊花/播放按钮/进度条）和底层播放器行为

 2. 直播推流 / 拉流状态
    Idle → Connecting → Connected → Publishing → Disconnecting → Reconnecting → Error
    网络抖动时自动在 Reconnecting 和 Connected 间迁移

 3. 用户登录 / 鉴权流程
    Guest → LoggingIn → LoggedIn → TokenExpired → RefreshingToken → LoggedOut

 4. 下载任务状态管理
    Waiting → Downloading → Paused → Completed → Failed
    支持断点续传（Paused → Downloading）和失败重试（Failed → Waiting）

 5. 支付流程
    Idle → Confirming → Processing → Success → Failed → Refunding

 6. 游戏角色行为
    Idle → Running → Jumping → Attacking → Dead
    同一事件在不同状态触发不同动画和逻辑


 ============================================================
 六、FSM 开发流程
 ============================================================

 1. 需求分析：确定需要建模的对象，收集所有可能的状态和触发事件
 2. 定义状态与事件：枚举所有状态，明确每个状态的含义和约束
 3. 设计状态转移表（或状态图）：State × Event → NextState + Action，确保无歧义、无死状态
 4. 实现状态机：选择合适方式（switch / State Pattern / Table-Driven），添加非法迁移保护
 5. 测试：针对每条迁移路径编写单元测试，覆盖正常路径和非法事件输入


 ============================================================
 七、常见面试问题
 ============================================================

 Q：什么是状态机？为什么要使用状态机？
 A：状态机是描述系统在有限状态间迁移的模型。使用状态机的好处：
    ① 将复杂条件判断结构化，减少 if-else 嵌套；
    ② 状态与行为解耦，易于扩展和维护；
    ③ 非法状态迁移可在框架层面拦截，提高健壮性；
    ④ 状态转移图可视化，便于团队沟通和文档化。

 Q：状态模式和策略模式有什么区别？
 A：状态模式（State Pattern）：状态对象自己决定何时切换状态，关注"随状态变化的行为"，
    状态之间有迁移关系，状态对象通常持有 Context 引用。
    策略模式（Strategy Pattern）：策略对象是无状态的，由外部选择使用哪个策略，关注"算法替换"，
    策略之间互相独立，没有迁移概念。
    本质区别：状态模式封装了"什么时候切换"，策略模式只封装"如何执行"。

 Q：如何防止非法的状态迁移？
 A：在 fireEvent 前通过 canFireEvent: 检查当前状态是否在该事件的合法来源状态列表中，
    不在则忽略事件或返回错误，不执行迁移。
    MBStateMachine 的 canFireEvent: 方法即实现此功能。

 Q：状态机如何与 UI 解耦？
 A：状态机只负责维护状态和迁移逻辑，通过 Block 回调/Delegate/通知/KVO 将状态变化
    通知给 ViewController，VC 根据新状态更新 UI。
    状态机本身不持有任何 UI 对象，实现完全解耦，也便于对状态机逻辑单独进行单元测试。

 Q：什么时候应该用状态机，什么时候用普通 if-else？
 A：当系统满足以下条件时，使用状态机更合适：
    ① 状态数量 ≥ 3 个，且状态之间存在明确的迁移规则；
    ② 同一事件在不同状态下行为不同；
    ③ 需要防止非法操作（如播放器未加载完不能 seek）；
    ④ 状态逻辑复杂，if-else 嵌套已难以维护。
    状态数量 ≤ 2 个或逻辑极简时，普通 if-else 更直接。

*/
