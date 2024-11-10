//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(WindowProxy)
@interface MSPWindowProxy : NSObject

@property (nonatomic, assign) CGSize minSize;

@property (nonatomic, assign) CGSize maxSize;

@end

NS_ASSUME_NONNULL_END
