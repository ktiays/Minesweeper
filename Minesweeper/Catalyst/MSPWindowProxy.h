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

@property (nonatomic, assign, readonly) CGRect frame;

/// Sets the origin and size of the window’s frame rectangle, with optional animation, according to a given frame rectangle,
/// thereby setting its position and size onscreen.
///
/// @param frameRect The new frame rectangle for the window.
/// @param displayFlag Specifies whether the window redraws the views that need to be displayed. When `YES` the window sends a `displayIfNeeded` message down its view hierarchy, thus redrawing all views.
/// @param animateFlag Specifies whether the window performs a smooth resize. `YES` to perform the animation, whose duration is specified by `animationResizeTime:`.
- (void)setFrame:(CGRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animateFlag;

@end

NS_ASSUME_NONNULL_END
