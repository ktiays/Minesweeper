//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef NSWindow_h
#define NSWindow_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NSToolbar;
@class NSView;
@class NSViewController;
@class NSEvent;
@class NSScreen;

typedef NS_OPTIONS(NSUInteger, NSWindowStyleMask) {
    NSWindowStyleMaskBorderless = 0,
    NSWindowStyleMaskTitled = 1 << 0,
    NSWindowStyleMaskClosable = 1 << 1,
    NSWindowStyleMaskMiniaturizable = 1 << 2,
    NSWindowStyleMaskResizable = 1 << 3,
    NSWindowStyleMaskUnifiedTitleAndToolbar = 1 << 12,
    NSWindowStyleMaskFullScreen = 1 << 14,
    NSWindowStyleMaskFullSizeContentView = 1 << 15,
    NSWindowStyleMaskUtilityWindow = 1 << 4,
    NSWindowStyleMaskDocModalWindow = 1 << 6,
    NSWindowStyleMaskNonactivatingPanel = 1 << 7,
    NSWindowStyleMaskHUDWindow = 1 << 13
};

typedef NS_ENUM(NSInteger, NSWindowOrderingMode) {
    NSWindowAbove =  1,
    NSWindowBelow = -1,
    NSWindowOut =  0
};

@interface NSWindow : NSObject

@property (nonatomic, assign) BOOL titlebarAppearsTransparent;

@property (nonatomic, assign) NSSize minSize;
@property (nonatomic, assign) NSSize maxSize;
@property (nonatomic, assign, readonly) NSRect frame;
@property (nonatomic, strong) NSToolbar *toolbar;
@property (nonatomic, assign) CGFloat titlebarHeight;
@property (getter=isOpaque) BOOL opaque;
@property (nonatomic, copy) id backgroundColor;
@property (nonatomic, assign) NSInteger level;
/// A Boolean value that indicates whether the responder accepts first responder status.
@property (readonly) BOOL acceptsFirstResponder;
/// The window's alpha value.
@property CGFloat alphaValue;
/// The screen the window is on.
@property(nullable, readonly, strong) NSScreen *screen;

@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSViewController *contentViewController;

@property (nonatomic, assign) NSWindowStyleMask styleMask;
/// A Boolean value that indicates whether the window is transparent to mouse events.
@property BOOL ignoresMouseEvents;

+ (instancetype)_windowWithContentViewController:(NSViewController *)viewController styleMask:(NSWindowStyleMask)styleMask;
- (instancetype)animator;

/// Sets the origin and size of the window's frame rectangle according to a given frame rectangle,
/// thereby setting its position and size onscreen.
- (void)setFrame:(NSRect)frameRect
         display:(BOOL)flag;
- (void)setFrame:(CGRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animateFlag;
/// Positions the bottom-left corner of the window's frame rectangle at a given point in screen coordinates.
- (void)setFrameOrigin:(NSPoint)point;
/// Positions the top-left corner of the window's frame rectangle at a given point in screen coordinates.
- (void)setFrameTopLeftPoint:(NSPoint)point;
- (NSTimeInterval)animationResizeTime:(NSRect)newFrame;

/// Makes the window the key window.
- (void)makeKeyWindow;
/// Moves the window to the front of the screen list, within its level, and makes it the key window;
/// that is, it shows the window.
- (void)makeKeyAndOrderFront:(nullable id)sender;
- (void)resignKeyWindow;
/// Removes the window from the screen list, which hides the window.
- (void)orderOut:(nullable id)sender;
/// Informs the window that it has become the key window.
- (void)becomeKeyWindow;
/// Moves the window to the front of its level in the screen list, without changing either the key window or the main window.
- (void)orderFront:(nullable id)sender;
/// Attempts to make a given responder the first responder for the window.
- (BOOL)makeFirstResponder:(nullable id)responder;

/// Removes the window from the screen.
- (void)close;

/// Forces the field editor to give up its first responder status and prepares it for its next assignment.
- (void)endEditingFor:(nullable id)object;

/// Starts a window drag based on the specified mouse-down event.
- (void)performWindowDragWithEvent:(NSEvent *)event;

/// Invalidates the window shadow so that it is recomputed based on the current window shape.
- (void)invalidateShadow;

/// Adds a given window as a child window of the window.
- (void)addChildWindow:(NSWindow *)childWindow
               ordered:(NSWindowOrderingMode)place;

/// Converts a point to the screen coordinate system from the window's coordinate system.
- (NSPoint)convertPointToScreen:(NSPoint)point;

/// Converts a rectangle to the screen coordinate system from the window's coordinate system.
- (NSRect)convertRectToScreen:(NSRect)rect;

@end

NS_ASSUME_NONNULL_END

#endif /* NSWindow_h */
