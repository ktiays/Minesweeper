//
//  Created by ktiays on 2024/11/28.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef NSView_h
#define NSView_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NSWindow;

@interface NSView : NSObject

/// A Boolean value indicating whether the view uses a layer as its backing store.
@property (nonatomic, assign) BOOL wantsLayer;
@property (nonatomic, readonly, nullable) CALayer *layer;
@property (nonatomic, assign) NSRect frame;
@property (nonatomic, readonly) BOOL mouseDownCanMoveWindow;
@property (nullable, readonly, unsafe_unretained) NSView *superview;
@property (nullable, readonly, unsafe_unretained) NSWindow *window;
@property (nonatomic, assign) BOOL translatesAutoresizingMaskIntoConstraints;

@property (readonly, strong) NSLayoutYAxisAnchor *topAnchor;
@property (readonly, strong) NSLayoutXAxisAnchor *leftAnchor;
@property (readonly, strong) NSLayoutXAxisAnchor *rightAnchor;
@property (readonly, strong) NSLayoutXAxisAnchor *leadingAnchor;
@property (readonly, strong) NSLayoutXAxisAnchor *trailingAnchor;
@property (readonly, strong) NSLayoutYAxisAnchor *bottomAnchor;
@property (readonly, strong) NSLayoutXAxisAnchor *centerXAnchor;
@property (readonly, strong) NSLayoutYAxisAnchor *centerYAnchor;
@property (readonly, strong) NSLayoutDimension *widthAnchor;
@property (readonly, strong) NSLayoutDimension *heightAnchor;

/// Adds a view to the view’s subviews so it’s displayed above its siblings.
- (void)addSubview:(NSView *)view;
- (void)removeFromSuperview;

@end

NS_ASSUME_NONNULL_END

#endif /* NSView_h */
