//
//  Created by ktiays on 2024/12/2.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef NSScreen_h
#define NSScreen_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSScreen : NSObject

/// Returns the screen object containing the window with the keyboard focus.
@property (class, readonly, nullable, strong) NSScreen *mainScreen;
/// The dimensions and location of the screen.
@property (readonly) NSRect frame;
/// The current location and dimensions of the visible screen.
@property (readonly) NSRect visibleFrame;

@end

NS_ASSUME_NONNULL_END

#endif /* NSScreen_h */
