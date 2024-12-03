//
//  Created by ktiays on 2024/12/2.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MenuWindow)
@interface MSPMenuWindow : NSObject

@property (nonatomic, assign) CGRect frame;

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController;

- (void)popUpFromRect:(CGRect)frame inWindow:(UIWindow *)window;
- (void)close;

@end

NS_ASSUME_NONNULL_END

#endif
