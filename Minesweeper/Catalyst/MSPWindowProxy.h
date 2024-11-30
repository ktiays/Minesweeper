//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import <Foundation/Foundation.h>

#import "MSPViewProxy.h"

NS_ASSUME_NONNULL_BEGIN

@class NSToolbar;

NS_SWIFT_NAME(WindowProxy)
@interface MSPWindowProxy : NSObject

/// The minimum size to which the window's frame (including its title bar) can be sized.
@property (nonatomic, assign) CGSize minSize;

/// The maximum size to which the window's frame (including its title bar) can be sized.
@property (nonatomic, assign) CGSize maxSize;

/// The window's frame rectangle in screen coordinates, including the title bar.
@property (nonatomic, assign, readonly) CGRect frame;

/// The window's toolbar.
@property (nonatomic, strong) NSToolbar *toolbar;

@property (nonatomic, strong, nullable) MSPViewProxy *toolbarView;

@property (nonatomic, strong, nullable) MSPViewProxy *contentView;

/// Sets the origin and size of the window's frame rectangle, with optional animation, according to a given frame rectangle,
/// thereby setting its position and size onscreen.
///
/// @param frameRect The new frame rectangle for the window.
/// @param displayFlag Specifies whether the window redraws the views that need to be displayed. When `YES` the window sends a `displayIfNeeded` message down its view hierarchy, thus redrawing all views.
/// @param animateFlag Specifies whether the window performs a smooth resize. `YES` to perform the animation, whose duration is specified by `animationResizeTime:`.
- (void)setFrame:(CGRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animateFlag;

@end

NS_ASSUME_NONNULL_END
