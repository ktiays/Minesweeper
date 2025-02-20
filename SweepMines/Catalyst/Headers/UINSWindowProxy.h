//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef UINSWindowProxy_h
#define UINSWindowProxy_h

#import <UIKit/UIKit.h>

#import "NSWindow.h"

NS_ASSUME_NONNULL_BEGIN

@interface UINSWindowProxy : NSObject

@property (nonatomic, strong) NSWindow *attachedWindow;

- (UIWindow *)uiWindow;
- (NSArray<UIWindow *> *)uiWindows;

@end

NS_ASSUME_NONNULL_END

#endif /* UINSWindowProxy_h */
