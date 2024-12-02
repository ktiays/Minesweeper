//
//  Created by ktiays on 2024/11/29.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSPUIHostingView : NSObject

@property (nonatomic, readonly) id hostingNSView;
@property (nonatomic, readonly) CGSize intrinsicContentSize;
@property (nonatomic, assign) CGRect frame;

@property (nonatomic, assign) BOOL mouseDownCanMoveWindow;

- (instancetype)initWithUIView:(UIView *)view;

- (void)removeFromSuperview;

@end

NS_ASSUME_NONNULL_END
