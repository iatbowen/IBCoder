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

/* 红绿灯 */
- (void)testTheTrafficLights {
    
    // 1. 初始化状态机
    MBStateMachine *stateMachine = [[MBStateMachine alloc] init];
 
    // 2. 初始化 状态.  一个信号灯只有 ”红“，“绿”，”黄“ 三种状态。
        // 红灯
    MBState *green = [MBState stateWithName:@"green"];
        // 黄灯
    MBState *yellow = [MBState stateWithName:@"yellow"];
        // 红灯
    MBState *red = [MBState stateWithName:@"red"];
    
    // 3.添加状态到状态机。
    [stateMachine addStates:@[green,
                              yellow,
                              red]];
    // 设置默认的状态。
    stateMachine.initialState = green;
    
    
    // 4.初始化 事件。
    
   /*    绿灯 ---> 黄灯
    *    黄灯 ---> 红灯
    *    红灯 ----> 黄灯
    *    黄灯 ----> 绿灯
    */
        //警告
    MBEvent *warn = [MBEvent eventWithName:@"warn" transitioningFromStates:@[green] toState:yellow];
        //停止
    MBEvent *stop = [MBEvent eventWithName:@"stop" transitioningFromStates:@[yellow] toState:red];
        //准备
    MBEvent *ready = [MBEvent eventWithName:@"ready" transitioningFromStates:@[red] toState:yellow];
        //前进
    MBEvent *go = [MBEvent eventWithName:@"go" transitioningFromStates:@[yellow] toState:green];
    
     // 5.添加事件到状态机。
    [stateMachine addEvents:@[warn,
                              stop,
                              ready,
                              go]];
    
    // 6.启动状态机。
    [stateMachine activate];
    
    // 检测能否触发这个事件, 目前是 ”green“ 状态。
    if ([stateMachine canFireEvent:warn]) {
        NSLog(@"warn canFireEvent");
    };
    
    // 将要出发这个事件
    [warn setDidFireEventBlock:^(MBEvent *event, MBTransition *transition) {
         NSLog(@"did fire 'warn' event ");
    }];
    
    [stop setDidFireEventBlock:^(MBEvent *event, MBTransition *transition) {
        NSLog(@"did fire 'stop' event ");
    }];
  
    [ready setDidFireEventBlock:^(MBEvent *event, MBTransition *transition) {
        NSLog(@"did fire 'ready' event ");
    }];
     
    [go setDidFireEventBlock:^(MBEvent *event, MBTransition *transition) {
        NSLog(@"did fire 'go' event ");
    }];
        
    //“绿灯” 倒计时结束  ----->(告诉状态机)  将要触发这个事件：  “warn”
    
    [stateMachine fireEvent:warn userInfo:nil error:nil];
    [stateMachine fireEvent:stop userInfo:nil error:nil];
    [stateMachine fireEvent:ready userInfo:nil error:nil];
    [stateMachine fireEvent:go userInfo:nil error:nil];

}

@end

/**
 1. 概述
 有限状态机（英语：finite-state machine，缩写：FSM）又称有限状态自动机（英语：finite-state automaton，缩写：FSA），简称状态机。
 是表示有限个状态以及在这些状态之间的转移和动作等行为的数学计算模型
 1.1 特性
 有限状态机（Finite-state machine）是一个非常有用的模型，可以模拟世界上大部分事物，简单说，它有三个特征：
 状态总数（state）是有限的。
 任一时刻，只处在一种状态之中。
 某种条件下，会从一种状态转变（transition）到另一种状态。
 
 1.2 核心概念
 状态机有四个核心概念：
 状态 State：一个状态机至少要包含两个状态。
 事件 Event：事件就是执行某个操作的触发条件或者口令。
 动作 Action：事件发生以后要执行动作。
 变换 Transition：也就是从一个状态变化为另一个状态。
 
 1.3 状态机可归纳为4个要素，即现态、条件、动作、次态。“现态”和“条件”是因，“动作”和“次态”是果。详解如下：
 现态：是指当前所处的状态。
 条件：又称为“事件”。当一个条件被满足，将会触发一个动作，或者执行一次状态的迁移。
 动作：条件满足后执行的动作。动作执行完毕后，可以迁移到新的状态，也可以仍旧保持原状态。动作不是必需的，当条件满足后，也可以不执行任何动作，直接迁移到新状态。
 次态：条件满足后要迁往的新状态。
 
 1.4.组成部分
 状态（State）：系统可以处于的不同情况或阶段。
 事件（Event）：引发状态转换的外部或内部事件。
 转换（Transition）：状态之间的变化，通常是由事件触发的。
 初始状态（Initial State）：状态机开始时的状态。
 终止状态（Final State）：状态机可以结束的状态。
 
 2.开发流程
 2.1需求分析：
 理解系统的需求，确定需要建模的对象和其行为。
 收集相关的事件和状态，明确状态机的目标。
 2.2定义状态和事件：
 列出所有可能的状态，定义每个状态的特征。
 确定系统中会影响状态变化的事件。
 2.3设计状态转移图或状态表：
 创建状态转移图，直观地表示状态和事件之间的关系。
 或者，使用状态表列出状态、事件及对应的状态转移。
 2.4实现状态机：
 根据设计的状态图或状态表，将状态机编码实现，通常会使用适合的编程语言或框架。
 定义状态之间的转换逻辑和相关的行为。

 
 */
