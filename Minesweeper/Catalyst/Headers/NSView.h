//
//  Created by ktiays on 2024/11/28.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef NSView_h
#define NSView_h

#import <Foundation/Foundation.h>

@class NSWindow;

@interface NSView : NSObject

@property (nonatomic, assign) NSRect frame;
@property (nonatomic, readonly) BOOL mouseDownCanMoveWindow;
@property (nullable, readonly, unsafe_unretained) NSView *superview;
@property (nullable, readonly, unsafe_unretained) NSWindow *window;

- (void)removeFromSuperview;

@end

#endif /* NSView_h */
