//
//  Created by ktiays on 2025/10/10.
//  Copyright (c) 2025 ktiays. All rights reserved.
// 

#ifndef NSGlassEffectView_h
#define NSGlassEffectView_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NSView, NSColor;

typedef NS_ENUM(NSInteger, NSGlassEffectViewStyle) {
    /// Standard glass effect style.
    NSGlassEffectViewStyleRegular,
    /// Clear glass effect style.
    NSGlassEffectViewStyleClear
} API_AVAILABLE(macos(26.0)) NS_SWIFT_NAME(NSGlassEffectView.Style);

API_AVAILABLE(macos(26.0))
@interface NSGlassEffectView : NSView

/// The view to embed in glass.
@property (nonatomic, strong) __kindof NSView *contentView;

/// The amount of curvature for all corners of the glass.
@property (nonatomic, assign) CGFloat cornerRadius;

/// The style of glass this view uses.
@property (nonatomic, assign) NSGlassEffectViewStyle style;

/// The color the glass effect view uses to tint the background and glass effect toward.
@property (nonatomic, copy) NSColor *tintColor;

@end

NS_ASSUME_NONNULL_END

#endif /* NSGlassEffectView_h */
