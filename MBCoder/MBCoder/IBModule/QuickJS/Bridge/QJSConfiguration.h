//
//  QJSConfiguration.h
//  MBCoder
//
//  Created by 叶修 on 2024/10/17.
//  Copyright © 2024 inke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class QJSContext, QJSRuntime;

@interface QJSConfiguration : NSObject

- (void)setupContext:(QJSContext *)context;
- (void)setupRuntime:(QJSRuntime *)runtime;

@end

NS_ASSUME_NONNULL_END
