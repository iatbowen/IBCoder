//
//  MBStateMachine.m
//  MBCoder
//
//  Created by 叶修 on 2024/10/24.
//  Copyright © 2024 inke. All rights reserved.
//

#import "MBStateMachine.h"
#import "MBState.h"
#import "MBEvent.h"
#import "MBTransition.h"

@interface MBEvent ()

@property (nonatomic, copy) BOOL (^shouldFireEventBlock)(MBEvent *, MBTransition *);
@property (nonatomic, copy) void (^willFireEventBlock)(MBEvent *, MBTransition *);
@property (nonatomic, copy) void (^didFireEventBlock)(MBEvent *, MBTransition *);

@end

@interface MBState ()

@property (nonatomic, copy) void (^willEnterStateBlock)(MBState *, MBTransition *);
@property (nonatomic, copy) void (^didEnterStateBlock)(MBState *, MBTransition *);
@property (nonatomic, copy) void (^willExitStateBlock)(MBState *, MBTransition *);
@property (nonatomic, copy) void (^didExitStateBlock)(MBState *, MBTransition *);

@end

NSString *const MBErrorDomain = @"org.bowen.state.machine.errors";
NSString *const MBStateMachineDidChangeStateNotification = @"MBStateMachineDidChangeStateNotification";
NSString *const MBStateMachineDidChangeStateTransitionUserInfoKey = @"transition";

NSString *const MBStateMachineIsImmutableException = @"MBStateMachineIsImmutableException";

#define MBRaiseIfActive() \
if ([self isActive]) [NSException raise:MBStateMachineIsImmutableException format:@"Unable to modify state machine: The state machine has already been activated."];

@interface MBStateMachine ()

@property (nonatomic, strong) NSMutableSet *mutableStates;
@property (nonatomic, strong) NSMutableSet *mutableEvents;
@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, strong, readwrite) MBState *currentState;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation MBStateMachine

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"states"]) {
        NSSet *affectingKey = [NSSet setWithObject:@"mutableStates"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    } else if ([key isEqualToString:@"events"]) {
        NSSet *affectingKey = [NSSet setWithObject:@"mutableEvents"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }
    return keyPaths;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mutableStates = [NSMutableSet set];
        self.mutableEvents = [NSMutableSet set];
        self.lock = [NSRecursiveLock new];
    }
    return self;
}

- (void)setInitialState:(MBState *)initialState
{
    MBRaiseIfActive();
    _initialState = initialState;
}

- (void)setCurrentState:(MBState *)currentState
{
    if (currentState == nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Cannot assign currentState to `nil`: Expected a `MBState` object. (%@)", self];
    }
    _currentState = currentState;
}

- (NSSet *)states
{
    return [NSSet setWithSet:self.mutableStates];
}

- (void)addState:(MBState *)state
{
    MBRaiseIfActive();
    if (![state isKindOfClass:[MBState class]]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Expected a `MBState` object, instead got a `%@` (%@)", [state class], state];
    }
    if ([self stateNamed: state.name]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"State with name `%@` already exists", state.name];
    }
    
    if (self.initialState == nil) {
        self.initialState = state;
    }
    [self.mutableStates addObject:state];
}

- (void)addStates:(NSArray *)arrayOfStates
{
    MBRaiseIfActive();
    for (MBState *state in arrayOfStates) {
        [self addState:state];
    }
}

- (MBState *)stateNamed:(NSString *)name
{
    for (MBState *state in self.mutableStates) {
        if ([state.name isEqualToString:name]) return state;
    }
    return nil;
}

- (BOOL)isInState:(id)stateOrStateName
{
    if (![stateOrStateName isKindOfClass:[MBState class]] && ![stateOrStateName isKindOfClass:[NSString class]]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Expected a `MBState` object or `NSString` object specifying the name of a state, instead got a `%@` (%@)",
         [stateOrStateName class], stateOrStateName];
    }
    MBState *state = [stateOrStateName isKindOfClass:[MBState class]] ? stateOrStateName : [self stateNamed:stateOrStateName];
    if (!state) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot find a State named '%@'", stateOrStateName];
    }
    return [self.currentState isEqual:state];
}

- (NSSet *)events
{
    return [NSSet setWithSet:self.mutableEvents];
}

- (void)addEvent:(MBEvent *)event
{
    MBRaiseIfActive();
    if (!event) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot add a `nil` event to the state machine."];
    }
    if (event.sourceStates) {
        for (MBState *state in event.sourceStates) {
            if (![self.mutableStates containsObject:state]) {
                [NSException raise:NSInternalInconsistencyException
                            format:@"Cannot add event '%@' to the state machine: the event references a state '%@', which has not been added to the state machine.", event.name, state.name];
            }
        }
    }
    if (![self.mutableStates containsObject:event.destinationState]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Cannot add event '%@' to the state machine: the event references a state '%@', which has not been added to the state machine.", event.name, event.destinationState.name];
    }
    [self.mutableEvents addObject:event];
}

- (void)addEvents:(NSArray *)arrayOfEvents
{
    MBRaiseIfActive();
    for (MBEvent *event in arrayOfEvents) {
        [self addEvent:event];
    }
}

- (MBEvent *)eventNamed:(NSString *)name
{
    for (MBEvent *event in self.mutableEvents) {
        if ([event.name isEqualToString:name]) return event;
    }
    return nil;
}

- (void)activate
{
    if (self.isActive) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"The state machine has already been activated."];
    }
    [self.lock lock];
    self.active = YES;
    
    // Dispatch callbacks to establish initial state
    if (self.initialState.willEnterStateBlock) {
        self.initialState.willEnterStateBlock(self.initialState, nil);
    }
    self.currentState = self.initialState;
    if (self.initialState.didEnterStateBlock) {
        self.initialState.didEnterStateBlock(self.initialState, nil);
    }
    [self.lock unlock];
}

- (BOOL)canFireEvent:(id)eventOrEventName
{
    if (![eventOrEventName isKindOfClass:[MBEvent class]] && ![eventOrEventName isKindOfClass:[NSString class]]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Expected a `MBEvent` object or `NSString` object specifying the name of an event, instead got a `%@` (%@)",
         [eventOrEventName class], eventOrEventName];
    }
    MBEvent *event = [eventOrEventName isKindOfClass:[MBEvent class]] ? eventOrEventName : [self eventNamed:eventOrEventName];
    if (!event) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot find an Event named '%@'", eventOrEventName];
    }
    return event.sourceStates == nil || [event.sourceStates containsObject:self.currentState];
}

- (BOOL)fireEvent:(id)eventOrEventName userInfo:(NSDictionary *)userInfo error:(NSError *__autoreleasing *)error
{
    [self.lock lock];
    if (!self.isActive) {
        [self activate];
    }
    if (![eventOrEventName isKindOfClass:[MBEvent class]] && ![eventOrEventName isKindOfClass:[NSString class]]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Expected a `MBEvent` object or `NSString` object specifying the name of an event, instead got a `%@` (%@)",
         [eventOrEventName class], eventOrEventName];
    }
    MBEvent *event = [eventOrEventName isKindOfClass:[MBEvent class]] ? eventOrEventName : [self eventNamed:eventOrEventName];
    if (!event) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot find an Event named '%@'", eventOrEventName];
    }
    
    // Check that this transition is permitted
    if (event.sourceStates != nil && ![event.sourceStates containsObject:self.currentState]) {
        NSString *failureReason = [NSString stringWithFormat:@"An attempt was made to fire the '%@' event while in the '%@' state, but the event can only be fired from the following states: %@", event.name, self.currentState.name, [[event.sourceStates valueForKey:@"name"] componentsJoinedByString:@", "]];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"The event cannot be fired from the current state.",
                                   NSLocalizedFailureReasonErrorKey: failureReason };
        if (error) *error = [NSError errorWithDomain:MBErrorDomain code:MBInvalidTransitionError userInfo:userInfo];
        [self.lock unlock];
        return NO;
    }
    
    MBTransition *transition = [MBTransition transitionForEvent:event fromState:self.currentState inStateMachine:self userInfo:userInfo];
    if (event.shouldFireEventBlock) {
        if (!event.shouldFireEventBlock(event, transition)) {
            NSString *failureReason = [NSString stringWithFormat:@"An attempt to fire the '%@' event was declined because `shouldFireEventBlock` returned `NO`.", event.name];
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"The event declined to be fired.",
                                       NSLocalizedFailureReasonErrorKey: failureReason};
            if (error) {
                *error = [NSError errorWithDomain:MBErrorDomain code:MBTransitionDeclinedError userInfo:userInfo];
            }
            [self.lock unlock];
            return NO;
        }
    }
    
    MBState *oldState = self.currentState;
    MBState *newState = event.destinationState;
    
    if (event.willFireEventBlock) {
        event.willFireEventBlock(event, transition);
    }
    if (oldState.willExitStateBlock) {
        oldState.willExitStateBlock(oldState, transition);
    }
    if (newState.willEnterStateBlock) {
        newState.willEnterStateBlock(newState, transition);
    }
    self.currentState = newState;
    
    NSMutableDictionary *notificationInfo = [userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    [notificationInfo addEntriesFromDictionary:@{MBStateMachineDidChangeStateTransitionUserInfoKey: transition}];
    [[NSNotificationCenter defaultCenter] postNotificationName:MBStateMachineDidChangeStateNotification object:self userInfo:notificationInfo];
    
    if (oldState.didExitStateBlock) {
        oldState.didExitStateBlock(oldState, transition);
    }
    if (newState.didEnterStateBlock) {
        newState.didEnterStateBlock(newState, transition);
    }
    if (event.didFireEventBlock) {
        event.didFireEventBlock(event, transition);
    }
    [self.lock unlock];
    
    return YES;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.initialState = [aDecoder decodeObjectForKey:@"initialState"];
    self.currentState =[aDecoder decodeObjectForKey:@"currentState"];
    self.mutableStates = [[aDecoder decodeObjectForKey:@"states"] mutableCopy];
    self.mutableEvents = [[aDecoder decodeObjectForKey:@"events"] mutableCopy];
    self.active = [aDecoder decodeBoolForKey:@"isActive"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.initialState forKey:@"initialState"];
    [aCoder encodeObject:self.currentState forKey:@"currentState"];
    [aCoder encodeObject:self.states forKey:@"states"];
    [aCoder encodeObject:self.events forKey:@"events"];
    [aCoder encodeBool:self.isActive forKey:@"isActive"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MBStateMachine *copiedStateMachine = [[[self class] allocWithZone:zone] init];
    copiedStateMachine.active = NO;
    copiedStateMachine.initialState = self.initialState;
    
    for (MBState *state in self.states) {
        [copiedStateMachine addState:[state copy]];
    }
    
    for (MBEvent *event in self.events) {
        NSMutableArray *sourceStates = [NSMutableArray arrayWithCapacity:[event.sourceStates count]];
        for (MBState *sourceState in event.sourceStates) {
            [sourceStates addObject:[copiedStateMachine stateNamed:sourceState.name]];
        }
        MBState *destinationState = [copiedStateMachine stateNamed:event.destinationState.name];
        MBEvent *copiedEvent = [MBEvent eventWithName:event.name transitioningFromStates:sourceStates toState:destinationState];
        [copiedStateMachine addEvent:copiedEvent];
    }
    return copiedStateMachine;
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p %ld States, %ld Events. currentState=%@, initialState='%@', isActive=%@>",
            NSStringFromClass([self class]), self, (unsigned long) [self.mutableStates count], (unsigned long) [self.mutableEvents count],
            self.currentState.name, self.initialState.name, self.isActive ? @"YES" : @"NO"];
}

- (NSString *)dotDescription
{
    NSMutableString *dotDescription = [[NSMutableString alloc] initWithString:@"digraph StateMachine {\n"];
    if (self.initialState) {
        [dotDescription appendFormat:@"  \"\" [style=\"invis\"]; \"\" -> \"%@\" [dir=both, arrowtail=dot]; // Initial State\n", self.initialState.name];
    }
    if (self.currentState) {
        [dotDescription appendFormat:@"  \"%@\" [style=bold]; // Current State\n", self.currentState.name];
    }
    for (MBEvent *event in self.events) {
        for (MBState *sourceState in event.sourceStates) {
            [dotDescription appendFormat:@"  \"%@\" -> \"%@\" [label=\"%@\", fontname=\"Menlo Italic\", fontsize=9];\n", sourceState.name, event.destinationState.name, event.name];
        }
    }
    [dotDescription appendString:@"}"];
    return [dotDescription copy];
}


@end
