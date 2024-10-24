//
//  MBState.h
//  MBCoder
//
//  Created by 叶修 on 2024/10/24.
//  Copyright © 2024 inke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MBTransition;

/**
 The `MBState` class defines a particular state with a state machine. Each state must have a unique name within the state machine in which it is used.
 */
@interface MBState : NSObject<NSCoding, NSCopying>

///-----------------------
/// @name Creating a State
///-----------------------

/**
 Creates and returns a new state object with the specified name and an optional userInfo dictionary.
 
 @param name The name of the state. Cannot be blank.
 @param userInfo An optional dictionary of user info.
 @return A newly created state object with the specified name.
 */
+ (instancetype)stateWithName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;

/**
 Creates and returns a new state object with the specified name. This method uses stateWithName:userInfo: with nil as userInfo parameter.
 
 @param name The name of the state. Cannot be blank.
 @return A newly created state object with the specified name.
 */
+ (instancetype)stateWithName:(NSString *)name;

///------------------------------------
/// @name Accessing the Name of a State
///------------------------------------

/**
 The name of the receiver. Cannot be `nil` and must be unique within the state machine that the receiver is added to.
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 An optional dictionary of user info.
 */
@property (nonatomic, copy, readonly) NSDictionary *userInfo;

///----------------------------------
/// @name Configuring Block Callbacks
///----------------------------------

/**
 Sets a block to be executed before the state machine transitions into the state modeled by the receiver.
 
 @param block The block to executed before a state machine enters the receiver's state. The block has no return value and takes two arguments: the state object and a transition object modeling the state change.
 */
- (void)setWillEnterStateBlock:(void (^)(MBState *state, MBTransition *transition))block;

/**
 Sets a block to be executed after the state machine has transitioned into the state modeled by the receiver.
 
 @param block The block to executed after a state machine enters the receiver's state. The block has no return value and takes two arguments: the state object and a transition object modeling the state change.
 */
- (void)setDidEnterStateBlock:(void (^)(MBState *state, MBTransition *transition))block;

/**
 Sets a block to be executed before the state machine transitions out of the state modeled by the receiver.
 
 @param block The block to executed before a state machine exits the receiver's state. The block has no return value and takes two arguments: the state object and a transition object modeling the state change.
 */
- (void)setWillExitStateBlock:(void (^)(MBState *state, MBTransition *transition))block;

/**
 Sets a block to be executed after the state machine has transitioned out of the state modeled by the receiver.
 
 @param block The block to executed after a state machine exit the receiver's state. The block has no return value and takes two arguments: the state object and a transition object modeling the state change.
 */
- (void)setDidExitStateBlock:(void (^)(MBState *state, MBTransition *transition))block;


@end

NS_ASSUME_NONNULL_END
