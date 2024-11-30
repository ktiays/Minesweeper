//
//  Created by ktiays on 2024/11/28.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ViewProxy)
@interface MSPViewProxy : NSObject

@property (nonatomic, assign) CGRect frame;

- (void)addSubview:(id)view;
- (void)removeFromSuperview;

@end

NS_ASSUME_NONNULL_END
