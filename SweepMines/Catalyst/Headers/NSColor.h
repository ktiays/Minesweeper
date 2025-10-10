//
//  Created by ktiays on 2025/10/10.
//  Copyright (c) 2025 ktiays. All rights reserved.
// 

#ifndef NSColor_h
#define NSColor_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * NSColorName;

@interface NSColor : NSObject

/// Creates a color object from the provided name, which corresponds to a color in the default asset catalog of the app's main bundle.
+ (instancetype)colorNamed:(NSColorName)name;

/// Creates a new color object that has the same color space and component values as the current color object, but the specified alpha component.
- (NSColor *)colorWithAlphaComponent:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END

#endif /* NSColor_h */
