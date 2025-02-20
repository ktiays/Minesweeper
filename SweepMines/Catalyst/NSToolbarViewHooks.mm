//
//  Created by ktiays on 2024/11/29.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import <objc/runtime.h>

#import "NSToolbarViewHooks.h"
#import "NSView.h"

void prepareNSToolbarView(void) {
    auto classes = @[@"NSToolbarView", @"NSView", @"UINSSceneView", @"NSTitlebarContainerView"];
    for (NSString *className in classes) {
        auto viewClass = NSClassFromString(className);
        auto method = class_getInstanceMethod(viewClass, @selector(mouseDownCanMoveWindow));
        method_setImplementation(method, imp_implementationWithBlock(^BOOL (id _self) {
            return NO;
        }));
    }
}

#endif
