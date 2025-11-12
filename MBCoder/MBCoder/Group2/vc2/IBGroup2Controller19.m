//
//  IBGroup2Controller19.m
//  MBCoder
//
//  Created by BowenCoder on 2019/11/26.
//  Copyright © 2019 inke. All rights reserved.
//

#import "IBGroup2Controller19.h"

@interface IBGroup2Controller19 ()

@end

@implementation IBGroup2Controller19

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

/*
 
 参考：https://www.cnblogs.com/jiangds/p/6596595.html
 
 前言：统一建模语言(Unified Modeling Language，UML)
 1、关系
 1）用例视图：用例图
 2）设计视图：类图、对象图
 3）进程视图：时序图、协作图、状态图、活动图
 4）实现视图：构件图
 5）拓扑视图：部署图
 
 还可分为静态视图和动态视图
 静态图分为：用例图，类图，对象图，包图，构件图，部署图。
 动态图分为：状态图，活动图，协作图，序列图。
 
 2、用例图：用例图主要回答了两个问题（是谁用软件；软件的功能）
 
 3、类图：根据用例图抽象成类，描述类的内部结构和类与类之间的关系
   继承：空心三角形+实线表示
   实现：空心三角形+虚线
   组合：实心的菱形+实线箭头
   聚合：空心的菱形+实线箭头
   关联：实线箭头表示
   依赖：虚线箭头表示
 
 4、对象图：描述的是参与交互的各个对象在交互过程中某一时刻的状态。对象图可以被看作是类图在某一时刻的实例。
 
 5、状态图：是一种由状态、变迁、事件和活动组成的状态机，用来描述类的对象所有可能的状态以及时间发生时状态的转移条件。
 
 6、活动图：本质是一种流程图，它描述了活动到活动的控制流，它可以用来对业务过程、工作流建模，也可以对用例实现甚至是程序实现来建模。
 
 7、时序图：描述了对象之间消息发送的先后顺序，强调时间顺序
 
 8、协作图：描述了收发消息的对象的组织关系，强调对象之间的合作关系，按照空间结构布图
 
 9、构件图：表示系统中构件与构件之间，类或接口与构件之间的关系图
 
 10、部署图：描述了系统运行时进行处理的结点以及在结点上活动的构件的配置。强调了物理设备以及之间的连接关系。

  
 一、设计模式六大原则
 1、单一职责原则（Single Responsibility Principle，简称SRP）
 核心：一个类只负责一个功能领域中的相应职责
 目的：降低复杂度，提高可维护性
 关键：类的变更只能由一个原因引起
 
 2、里氏替换原则（Liskov Substitution Principle，简称LSP）
 核心：子类必须能完全替代父类且不影响程序正确性
 本质：继承时子类不破坏父类原有功能逻辑
 注意：避免重写父类非抽象方法

 3、依赖倒置原则（Dependence Inversion Principle，简称DIP）
 核心：高层模块不依赖底层模块，二者共同依赖抽象
 实践：面向接口编程，通过抽象解耦
 价值：提高系统灵活性，降低修改成本
 
 4、接口隔离原则（Interface Segregation Principle，简称ISP）
 核心：建立最小化专用接口，避免臃肿接口
 要点：客户端不应被迫依赖其不需要的方法
 效果：降低耦合，提高内聚性
 
 5、迪米特法则（Law of Demeter，简称LoD）
 核心：减少类间依赖
 别名：最少知识原则
 实现：通过中介类解耦间接调用
 
 6、开放封闭原则（Open Close Principle,简称OCP）
 核心：对扩展开放，对修改关闭
 手段：通过抽象和多态实现功能扩展
 目标：提升系统稳定性和可扩展性
 
 概括:
 1）单一职责原则告诉我们实现类要职责单一；
 2）里氏替换原则告诉我们不要破坏继承体系；
 3）依赖倒置原则告诉我们要面向接口编程；
 4）接口隔离原则告诉我们在设计接口的时候要精简单一；
 5）迪米特法则告诉我们要降低耦合。
 6）开闭原则是总纲，他告诉我们要对扩展开放，对修改关闭。
 
 设计核心思想：高内聚（SRP/ISP）驱动 低耦合（DIP/LoD），通过 抽象扩展（OCP/LSP）实现系统进化

 
 二、例子：
 
 1、单一职责原则（Single Responsibility Principle，简称SRP）

 class OrderList: NSObject { // 订单列表
     var waitPayList: WaitPayList? // 待支付
     var waitGoodsList: WaitGoodsList? // 待收货
     var receivedGoodsList: ReceivedGoodsList? // 已收货
 }
 class WaitPayList: NSObject {

 }
 class WaitGoodsList: NSObject {

 }
 class ReceivedGoodsList: NSObject {

 }
 
 2、里氏替换原则（Liskov Substitution Principle，简称LSP）

 修改之前

 class Car {
     func run() {
         print("汽车跑起来了")
     }
 }

 class BaoMaCar: Car {
     override func run() {
         super.run()
         print("当前行驶速度是80Km/h")
     }
 }
 
 可以看到我们重写了run方法，增加了汽车行驶速度的逻辑，这样是不满足的里氏替换原则的。因为所有基类Car替换成子类BaoMaCar，run方法的行为跟以前不是一模一样了。

 修改之后

 class Car {
     func run() {
         print("汽车跑起来了")
     }
 }

 class BaoMaCar: Car {
     func showSpeed() {
         print("当前行驶速度是80Km/h")
     }
 }
 
 3、依赖倒置原则（Dependence Inversion Principle，简称DIP）

 修改之前

 class Car {
     func refuel(_ gaso: Gasoline90) {
         print("加90号汽油")
     }
     func refuel(_ gaso: Gasoline93) {
         print("加93号汽油")
     }
 }

 class Gasoline90 {

 }

 class Gasoline93 {

 }
 
 上面这段代码有什么问题，可以看到Car高层模块依赖了底层模块Gasoline90和Gasoline93，这样写是不符合依赖倒置原则的。

 修改之后

 class Car {
     func refuel(_ gaso: IGasoline) {
         print("加\(gaso.name)汽油")
     }
 }

 protocol IGasoline {
     var name: String { get }
 }

 class Gasoline90: IGasoline {
     var name: String = "90号"
 }

 class Gasoline93: IGasoline {
     var name: String = "93号"
 }
 
 修改之后我们高层模块Car依赖了抽象IGasoline，底层模块Gasoline90和Gasoline93也依赖了抽象IGasoline，这种设计是符合依赖倒置原则的。

 4、接口隔离原则（Interface Segregation Principle，简称ISP）

 修改之前

 protocol ICar {
     func run()
     func showSpeed()
     func playMusic()
 }

 class Car: ICar {
     func run() {
         print("汽车跑起来了")
     }

     func showSpeed() {
         print("当前行驶速度是80Km/h")
     }

     func playMusic() {
         print("播放音乐")
     }
 }
 
 可以看到我们定义Car实现了ICar的接口，但是并不是每个车都有播放音乐的功能的，这样对于一般的低端车没有这个功能，对于他们来说，这个接口的设计就是冗余的。

 修改之后

 protocol IProfessionalCar {//具备一般功能的车
     func run()
     func showSpeed()
 }

 protocol IEntertainingCar {//具备娱乐功能的车
     func run()
     func showSpeed()
     func playMusic()
 }

 class SangTaNaCar: IProfessionalCar {//桑塔纳轿车
     func run() {
         print("汽车跑起来了")
     }

     func showSpeed() {
         print("当前行驶速度是80Km/h")
     }
 }

 class BaoMaCar: IEntertainingCar {//宝马轿车
     func run() {
         print("汽车跑起来了")
     }

     func showSpeed() {
         print("当前行驶速度是80Km/h")
     }

     func playMusic() {
         print("播放音乐")
     }
 }

 
 5、迪米特法则（Law of Demeter，简称LoD）
 
 例子：实现一个给汽车加油的设计，使的我们可以随时保证加油的质量过关。

 修改之前

 class Person {
     var car: Car?

     func refuel(_ gaso: IGasoline) {
         if gaso.isQuality == true {//如果汽油质量过关，我们就给汽车加油
             car?.refuel(gaso)
         }
     }
 }

 class Car {
     func refuel(_ gaso: IGasoline) {
         print("加\(gaso.name)汽油")
     }
 }

 protocol IGasoline {
     var name: String { get }
     var isQuality: Bool { get }
 }

 class Gasoline90: IGasoline {
     var name: String = "90号"
     var isQuality: Bool = false
 }

 class Gasoline93: IGasoline {
     var name: String = "93号"
     var isQuality: Bool = true
 }
 
 可以看到上面有个问题，我们怎么知道汽油的质量是否过关呢，即时我们知道，加油判断油的质量这个事情也不应该由我们来做。

 修改之后

 import Foundation

 class Person {//给车加油的人
     var car: Car?

     func refuel(_ worker: WorkerInPetrolStation, _ gaso: IGasoline) {
         guard let car = car else {return}

         worker.refuel(car, gaso)
     }
 }

 class WorkerInPetrolStation {//加油站工作人员
     func refuel(_ car: Car, _ gaso: IGasoline) {
         if gaso.isQuality == true {//如果汽油质量过关，我们就给汽车加油
             car.refuel(gaso)
         }
     }
 }

 class Car {
     func refuel(_ gaso: IGasoline) {
         print("加\(gaso.name)汽油")
     }
 }

 protocol IGasoline {
     var name: String { get }
     var isQuality: Bool { get }
 }

 class Gasoline90: IGasoline {
     var name: String = "90号"
     var isQuality: Bool = false
 }

 class Gasoline93: IGasoline {
     var name: String = "93号"
     var isQuality: Bool = true
 }
 
 6、开放封闭原则（Open Close Principle,简称OCP）

 修改之前代码

 class PayHelper {
     func pay(send: PaySendModel) {
         if send.type == 0 {
             //支付宝支付
         }
         else if send.type == 1 {
             //微信支付
         }
     }
 }

 class PaySendModel {
     var type: Int = 0
     var info: [String: AnyHashable]?
 }
 
 修改之后

 class PayHelper {
     var processors: [Int: PayProcessor]?

     func pay(send: PaySendModel)  {
         guard let processors = processors else {return}
         guard let payProcessor: PayProcessor = processors[send.type] else {return}

         payProcessor.handle(send: send)//支付
     }
 }

 class PaySendModel {
     var type: Int = 0
     var info: [String: AnyHashable]?
 }

 protocol PayProcessor {
     func handle(send: PaySendModel)
 }

 class AliPayProcessor: PayProcessor {
     func handle(send: PaySendModel) {

     }
 }

 class WeChatPayProcessor: PayProcessor {
     func handle(send: PaySendModel) {

     }
 }

*/

@end
