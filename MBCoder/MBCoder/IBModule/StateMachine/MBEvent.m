//
//  MBEvent.m
//  MBCoder
//
//  Created by 叶修 on 2024/10/24.
//  Copyright © 2024 inke. All rights reserved.
//

#import "MBEvent.h"
#import "MBState.h"

static NSString *MBDescribeSourceStates(NSArray *states)
{
    if (! [states count]) return @"any state";
    
    NSMutableString *description = [NSMutableString string];
    [states enumerateObjectsUsingBlock:^(MBState *state, NSUInteger idx, BOOL *stop) {
        NSString *separator = @"";
        if (idx < [states count] - 1) separator = (idx == [states count] - 2) ? @" and " : @", ";
        [description appendFormat:@"'%@'%@", state.name, separator];
    }];
    return description;
}

@interface MBEvent ()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSArray *sourceStates;
@property (nonatomic, strong, readwrite) MBState *destinationState;
@property (nonatomic, copy) BOOL (^shouldFireEventBlock)(MBEvent *, MBTransition *);
@property (nonatomic, copy) void (^willFireEventBlock)(MBEvent *, MBTransition *);
@property (nonatomic, copy) void (^didFireEventBlock)(MBEvent *, MBTransition *);

@end

@implementation MBEvent

+ (instancetype)eventWithName:(NSString *)name transitioningFromStates:(NSArray *)sourceStates toState:(MBState *)destinationState
{
    if (! [name length]) [NSException raise:NSInvalidArgumentException format:@"The event name cannot be blank."];
    if (!destinationState) [NSException raise:NSInvalidArgumentException format:@"The destination state cannot be nil."];
    MBEvent *event = [[self alloc] init];
    event.name = name;
    event.sourceStates = sourceStates;
    event.destinationState = destinationState;
    return event;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p '%@' transitions from %@ to '%@'>", NSStringFromClass([self class]), self, self.name, MBDescribeSourceStates(self.sourceStates), self.destinationState.name];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.sourceStates = [aDecoder decodeObjectForKey:@"sourceStates"];
    self.destinationState = [aDecoder decodeObjectForKey:@"destinationState"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.sourceStates forKey:@"sourceStates"];
    [aCoder encodeObject:self.destinationState forKey:@"destinationState"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MBEvent *copiedEvent = [[[self class] allocWithZone:zone] init];
    copiedEvent.name = self.name;
    copiedEvent.sourceStates = self.sourceStates;
    copiedEvent.destinationState = self.destinationState;
    copiedEvent.shouldFireEventBlock = self.shouldFireEventBlock;
    copiedEvent.willFireEventBlock = self.willFireEventBlock;
    copiedEvent.didFireEventBlock = self.didFireEventBlock;
    return copiedEvent;
}

@end
