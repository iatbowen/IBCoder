//
//  MBTransition.m
//  MBCoder
//
//  Created by 叶修 on 2024/10/24.
//  Copyright © 2024 inke. All rights reserved.
//

#import "MBTransition.h"
#import "MBEvent.h"

@interface MBTransition ()

@property (nonatomic, strong, readwrite) MBEvent *event;
@property (nonatomic, strong, readwrite) MBState *sourceState;
@property (nonatomic, strong, readwrite) MBStateMachine *stateMachine;
@property (nonatomic, copy, readwrite) NSDictionary *userInfo;

@end

@implementation MBTransition

+ (instancetype)transitionForEvent:(MBEvent *)event fromState:(MBState *)sourceState inStateMachine:(MBStateMachine *)stateMachine userInfo:(NSDictionary *)userInfo
{
    MBTransition *transition = [[self alloc] init];
    transition.event = event;
    transition.sourceState = sourceState;
    transition.stateMachine = stateMachine;
    transition.userInfo = userInfo;
    return transition;
}

- (MBState *)destinationState
{
    return self.event.destinationState;
}

@end
