//
//  Created by ktiays on 2024/12/2.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef NSAnimationContext_h
#define NSAnimationContext_h

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAnimationContext : NSObject

@property (class, readonly, strong) NSAnimationContext *currentContext;
/// Determine if animations are enabled or not for animations that occur as a result of another property change.
@property BOOL allowsImplicitAnimation;
/// The duration used by animations created as a result of setting new values for an animatable property.
@property NSTimeInterval duration;
/// The timing function used for all animations within this animation proxy group.
@property (strong) CAMediaTimingFunction *timingFunction;

/// Allows you to specify a completion block body after the set of animation actions whose completion will trigger the completion block.
+ (void)runAnimationGroup:(void (^)(NSAnimationContext *context))changes
        completionHandler:(void (^)(void))completionHandler;

/// Creates a new animation grouping.
+ (void)beginGrouping;
/// Ends the current animation grouping.
+ (void)endGrouping;

@end

NS_ASSUME_NONNULL_END

#endif /* NSAnimationContext_h */
