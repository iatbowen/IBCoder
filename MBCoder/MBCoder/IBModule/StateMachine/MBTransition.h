//
//  MBTransition.h
//  MBCoder
//
//  Created by 叶修 on 2024/10/24.
//  Copyright © 2024 inke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MBEvent, MBState, MBStateMachine;

/**
 The `MBTransition` class models a state change in response to an event firing within a state machine. It encapsulates all details about the change and is yielded as an argument to all block callbacks within TransitionKit. The optional dictionary of `userInfo` can be used to broadcast arbitrary data across callbacks.
 */
@interface MBTransition : NSObject

///----------------------------
/// @name Creating a Transition
///----------------------------

/**
 Creates and returns a new transition object describing a state change occurring within a state machine in response to the firing of an event.

 @param event The event being fired that is causing the transition to occur.
 @param sourceState The state of the machine when the event was fired.
 @param stateMachine The state machine in which the transition is occurring.
 @param userInfo An optional dictionary of user info supplied with the event when it was fired.
 */
+ (instancetype)transitionForEvent:(MBEvent *)event fromState:(MBState *)sourceState inStateMachine:(MBStateMachine *)stateMachine userInfo:(nullable NSDictionary *)userInfo;

///-----------------------------------
/// @name Accessing Transition Details
///-----------------------------------

/**
 The event that was fired, causing the transition to occur.
 */
@property (nonatomic, strong, readonly) MBEvent *event;

/**
 The state of the state machine when the transition starts.
 */
@property (nonatomic, strong, readonly) MBState *sourceState;

/**
 The state of the state machine after the transition finishes.
 */
@property (nonatomic, strong, readonly) MBState *destinationState;

/**
 The state machine in which the transition is occurring.
 */
@property (nonatomic, strong, readonly) MBStateMachine *stateMachine;

/**
 An optional dictionary of user info supplied with the event when fired.
 */
@property (nonatomic, copy, readonly) NSDictionary *userInfo;

@end

NS_ASSUME_NONNULL_END
