//
//  Created by ktiays on 2024/11/30.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Toolbar)
@interface MSPToolbar : UIView

@property (nonatomic, strong, nullable) UIView *titleTextField;

@property (nonatomic, strong, nullable) UIView *replayButtonView;

- (void)updateHierarchy;

@end

NS_ASSUME_NONNULL_END
