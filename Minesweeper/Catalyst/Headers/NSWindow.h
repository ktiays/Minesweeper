//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef UINSWindow_h
#define UINSWindow_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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

@interface NSWindow

@property (nonatomic, assign) BOOL titlebarAppearsTransparent;

@property (nonatomic, assign) NSSize minSize;
@property (nonatomic, assign) NSSize maxSize;
@property (nonatomic, assign, readonly) NSRect frame;

+ (instancetype)_windowWithContentViewController:(id)viewController styleMask:(NSUInteger)styleMask;
- (instancetype)animator;

- (void)setFrame:(CGRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animateFlag;

@end

NS_ASSUME_NONNULL_END

#endif /* UINSWindow_h */
