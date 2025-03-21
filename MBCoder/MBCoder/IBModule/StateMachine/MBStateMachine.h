//
//  MBStateMachine.h
//  MBCoder
//
//  Created by 叶修 on 2024/10/24.
//  Copyright © 2024 inke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class MBEvent, MBState;

/**
 The `MBStateMachine` class provides an interface for modeling a state machine. The state machine supports the registration of an arbitrary number of states and events that trigger transitions between the states.
 
 ## Callback Sequence
 
 When a state machine is activated, the following callbacks are invoked:
 
 1. Initial State: willEnterState - The block set with `setWillEnterStateBlock:` on the `initialState` is invoked.
 1. The `currentState` changes from `nil` to `initialState`
 1. Initial State: didEnterState - The block set with `setDidEnterStateBlock:` on the `initialState` is invoked.
 
 Each time an event is fired, the following callbacks are invoked:
 
 1. Event: shouldFireEvent - The block set with `setShouldFireEventBlock:` on the event being fired is consulted to determine if the event can be fired. If `NO` is returned then the event is declined and no further callbacks are invoked
 1. Event: willFireEvent - The block set with `setWillFireEventBlock:` on the event being fired is invoked.
 1. Old State: willExitState - The block set with `setWillExitStateBlock:` on the outgoing state is invoked.
 1. New State: willEnterState - The block set with `setWillEnterStateBlock:` on the incoming state is invoked.
 1. The `currentState` changes from the old state to the new state.
 1. Old State: didExitState - The block set with `setDidExitStateBlock:` on the old state is invoked.
 1. New State: didEnterState - The block set with `setDidEnterStateBlock:` on the new current state is invoked.
 1. Event: didFireEvent - The block set with `setDidFireEventBlock:` on the event being fired is invoked.
 1. Notification: After the event has completed and all block callbacks
 
 ## Copying and Serialization Support
 
 The `MBStateMachine` class is both `NSCoding` and `NSCopying` compliant. When copied, a new inactive state machine instance is created with the same states, events, and initial state. All blocks associated with the events and states are copied. When archived, the current state, initial state, states, events and activation state is preserved. All block callbacks associated with the states and events become `nil`.
 */
@interface MBStateMachine : NSObject <NSCoding, NSCopying>

///----------------------
/// @name Managing States
///----------------------

/**
 The set of states that have been added to the receiver. Each instance of the set is a `MBState` object.
 */
@property (nonatomic, readonly) NSSet *states;

/**
 The initial state of the receiver.
 
 When the machine is activated, it transitions into the initial state.
 */
@property (nonatomic, strong) MBState *initialState;

/**
 The current state of the receiver.
 
 When the machine is activated, the current state transitions from `nil` to the `initialState`. Subsequent state transitions are trigger by the firing of events.
 
 @see `fireEvent:error:`
 */
@property (nonatomic, strong, readonly) MBState *currentState;

/**
 Adds a state to the receiver.
 
 Before a state can be used in an event, it must be registered with the state machine.
 
 @param state The state to be added.
 @raises MBStateMachineIsImmutableException Raised if an attempt is made to modify the state machine after it has been activated.
 */
- (void)addState:(MBState *)state;

/**
 Adds an array of state objects to the receiver.
 
 This is a convenience method whose implementation is equivalent to the following example code:
 
    for (MBState *state in arrayOfStates) {
        [self addState:state];
    }
 
 @param arrayOfStates An array of `MBState` objects to be added to the receiver.
 */
- (void)addStates:(NSArray *)arrayOfStates;

/**
 Retrieves the state with the given name from the receiver.
 
 @param name The name of the state to retrieve.
 @returns The state object with the given name or `nil` if it could not be found.
 */
- (MBState *)stateNamed:(NSString *)name;

/**
 Returns a Boolean value that indicates if the receiver is in the specified state.
 
 This is a convenience method whose functionality is equivalent to comparing the given state with the `currentState`.
 
 @param stateOrStateName A `MBState` object or an `NSString` object that identifies a state by name. The specified state is compared with the value of the `currentState` property.
 @returns `YES` if the receiver is in the specified state, else `NO`.
 @raises NSInvalidArgumentException Raised if an invalid object is given.
 @raises NSInvalidArgumentException Raised if a string value is given that does not identify a registered state.
 */
- (BOOL)isInState:(id)stateOrStateName;

///----------------------
/// @name Managing Events
///----------------------

/**
 The set of events that have been added to the receiver. Each instance of the set is a `MBEvent` object.
 */
@property (nonatomic, readonly) NSSet *events;

/**
 Adds an event to the receiver.
 
 The state objects references by the event must be registered with the receiver.
 
 @param event The event to be added.
 @raises MBStateMachineIsImmutableException Raised if an attempt is made to modify the state machine after it has been activated.
 @raises NSInternalInconsistencyException Raised if the given event references a `MBState` that has not been registered with the receiver.
 */
- (void)addEvent:(MBEvent *)event;

/**
 Adds an array of event objects to the receiver.
 
 This is a convenience method whose implementation is equivalent to the following example code:
 
    for (MBEvent *event in arrayOfEvents) {
        [self addEvent:event];
    }
 
 @param arrayOfEvents An array of `MBEvent` objects to be added to the receiver.
 */
- (void)addEvents:(NSArray *)arrayOfEvents;

/**
 Retrieves the event with the given name from the receiver.
 
 @param name The name of the event to retrieve.
 @returns The event object with the given name or `nil` if it could not be found.
 */
- (MBEvent *)eventNamed:(NSString *)name;

///-----------------------------------
/// @name Activating the State Machine
///-----------------------------------

/**
 Activates the receiver by making it immutable and transitioning into the initial state.
 
 Once the state machine has been activated no further changes can be made to the registered events and states. Note that although callbacks will be dispatched for transition into the initial state upon activation, they will have a `nil` transition argument as no event has been fired.
 */
- (void)activate;

/**
 Returns a Boolean value that indicates if the receiver has been activated.
 */
- (BOOL)isActive;

///--------------------
/// @name Firing Events
///--------------------

/**
 Returns a Boolean value that indicates if the specified event can be fired.
 
 @param eventOrEventName A `MBEvent` object or an `NSString` object that identifies an event by name. The source states of the specified event is compared with the current state of the receiver. If the `sourceStates` of the event is `nil`, then the event can be fired from any state. If the `sourcesStates` is not `nil`, then the event can only be fired if it includes the `currentState` of the receiver.
 @return `YES` if the event can be fired, else `NO`.
 */
- (BOOL)canFireEvent:(id)eventOrEventName;

/**
 Fires an event to transition the state of the receiver. If the event fails to fire, then `NO` is returned and an error is set.
 
 If the receiver has not yet been activated, then the first event fired will activate it. If the specified transition is not permitted, then `NO` will be returned and an `MBInvalidTransitionError` will be created. If the `shouldFireEventBlock` of the specified event returns `NO`, then the event is declined, `NO` will be returned, and an `MBTransitionDeclinedError` will be created.
 
 @param eventOrEventName A `MBEvent` object or an `NSString` object that identifies an event by name.
 @param userInfo An optional dictionary of user info to be delivered as part of the state transition.
 @param error A pointer to an `NSError` object that will be set if the event fails to fire.
 @return `YES` if the event is fired, else `NO`.
 */
- (BOOL)fireEvent:(id)eventOrEventName userInfo:(nullable NSDictionary *)userInfo error:(NSError **)error;

///------------------
/// @name Description
///------------------

/**
 A description of the state machine in the DOT graph description language.
 
 @see http://en.wikipedia.org/wiki/DOT_(graph_description_language)
 */
@property (readonly) NSString *dotDescription;

@end

///----------------
/// @name Constants
///----------------

/**
 The domain for errors raised by TransitionKit.
 */
extern NSString *const MBErrorDomain;

/**
 A Notification posted when the `currentState` of a `MBStateMachine` object changes to a new value.
 */
extern NSString *const MBStateMachineDidChangeStateNotification;

/**
 A key in the `userInfo` dictionary of a `MBStateMachineDidChangeStateNotification` notification specifying the transition (MBTransition) between states.
 */
extern NSString *const MBStateMachineDidChangeStateTransitionUserInfoKey;

/**
 An exception raised when an attempt is made to mutate an immutable `MBStateMachine` object.
 */
extern NSString *const MBStateMachineIsImmutableException;

/**
 Error Codes
 */
typedef enum {
    MBInvalidTransitionError    =   1000,   // An invalid transition was attempted.
    MBTransitionDeclinedError   =   1001,   // The transition was declined by the `shouldFireEvent` guard block.
} MBErrorCode;

NS_ASSUME_NONNULL_END
