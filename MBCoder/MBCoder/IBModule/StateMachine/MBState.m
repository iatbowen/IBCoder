//
//  MBState.m
//  MBCoder
//
//  Created by 叶修 on 2024/10/24.
//  Copyright © 2024 inke. All rights reserved.
//

#import "MBState.h"

@interface MBState ()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSDictionary *userInfo;
@property (nonatomic, copy) void (^willEnterStateBlock)(MBState *, MBTransition *);
@property (nonatomic, copy) void (^didEnterStateBlock)(MBState *, MBTransition *);
@property (nonatomic, copy) void (^willExitStateBlock)(MBState *, MBTransition *);
@property (nonatomic, copy) void (^didExitStateBlock)(MBState *, MBTransition *);

@end

@implementation MBState

+ (instancetype)stateWithName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    if (! [name length]) [NSException raise:NSInvalidArgumentException format:@"The `name` cannot be blank."];
    MBState *state = [[self alloc] init];
    state.name = name;
    state.userInfo = userInfo;
    return state;
}

+ (instancetype)stateWithName:(NSString *)name
{
    return [self stateWithName:name userInfo:nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p '%@'>", NSStringFromClass([self class]), self, self.name];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    MBState *copiedState = [[[self class] allocWithZone:zone] init];
    copiedState.name = self.name;
    copiedState.willEnterStateBlock = self.willEnterStateBlock;
    copiedState.didEnterStateBlock = self.didEnterStateBlock;
    copiedState.willExitStateBlock = self.willExitStateBlock;
    copiedState.didExitStateBlock = self.didExitStateBlock;
    return copiedState;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.name = [aDecoder decodeObjectForKey:@"name"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
}


@end
