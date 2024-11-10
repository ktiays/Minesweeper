//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef _UISceneMacHelperUtilities_h
#define _UISceneMacHelperUtilities_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface _UISceneMacHelperUtilities : NSObject

- (BOOL)isFullScreenSceneWithSceneIdentifier:(NSString *)sceneIdentifier;
- (id)keyUIWindowAcrossAllScenes;
- (id)keyUIWindowForSceneIdentifier:(NSString *)sceneIdentifier;
- (void)rotateFullScreenSceneWithSceneIdentifier:(NSString *)sceneIdentifier
                          toInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                      resultSize:(CGSize)size;
- (NSString *)sceneIdentifierForUIScene:(UIScene *)scenen;
- (CGSize)sizeForFullScreenSceneWithSceneIdentifier:(NSString *)sceneIdentifier;
- (UIWindowScene *)uiWindowSceneWithSceneIdentifier:(NSString *)sceneIdentifier;
- (NSArray<UIWindow *> *)uiWindowsForSceneIdentifier:(NSString *)sceneIdentifier;
- (UIWindowScene *)_uiWindowSceneWithPersistentIdentifier:(id)arg0;
- (BOOL)attemptSceneDestructionForSceneIdentifier:(NSString *)sceneIdentifier;

@end

NS_ASSUME_NONNULL_END

#endif /* _UISceneMacHelperUtilities_h */
