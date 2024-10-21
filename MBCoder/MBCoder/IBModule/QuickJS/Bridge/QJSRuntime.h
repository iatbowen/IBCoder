//
//  QJSRuntime.h
//  MBCoder
//
//  Created by 叶修 on 2024/10/17.
//  Copyright © 2024 inke. All rights reserved.
//

#import "QJSConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class QJSContext;

typedef struct JSRuntime JSRuntime;

@interface QJSRuntime : NSObject

@property (nonatomic, assign) JSRuntime *rt;

+ (instancetype)shared;

+ (NSUInteger)numberOfRuntimes;

- (instancetype)init;

- (instancetype)initWithConfiguration:(QJSConfiguration *)config;

- (QJSContext *)newContext;

- (NSUInteger)numberOfContexts;

@end

NS_ASSUME_NONNULL_END
