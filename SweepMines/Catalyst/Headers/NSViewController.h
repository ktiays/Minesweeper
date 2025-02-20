//
//  Created by ktiays on 2024/11/28.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef NSViewController_h
#define NSViewController_h

#import <Foundation/Foundation.h>

@class NSWindow;
@class NSView;

@interface NSViewController : NSObject

@property (atomic, readwrite, copy) NSString *title;
@property (atomic, readwrite, retain) NSView *view;
@property (getter=isViewLoaded, atomic, readonly) BOOL viewLoaded;

@end

#endif /* NSViewController_h */
