//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef UINSApplicationDelegate_h
#define UINSApplicationDelegate_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "_UISceneMacHelperUtilities.h"
#import "UINSWindowProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface UINSApplicationDelegate : NSObject

@property (nonatomic, strong) _UISceneMacHelperUtilities *sceneUtilities;

- (UINSWindowProxy *)hostWindowForUIWindow:(UIWindow *)window;

- (void)didCreateUIScene:(UIScene *)scene transitionContext:(id)transitionContext;

@end

NS_ASSUME_NONNULL_END

#endif /* UINSApplicationDelegate_h */
