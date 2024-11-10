//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import "UINSApplicationDelegateHooks.h"
#import "MSPCatalystHelper.h"

void prepareUINSApplicationDelegate(void) {
    auto appDelegateClass = NSClassFromString(@"UINSApplicationDelegate");
    auto method = class_getInstanceMethod(appDelegateClass, @selector(didCreateUIScene:transitionContext:));
    auto impl = method_getImplementation(method);
    method_setImplementation(method, imp_implementationWithBlock(^(id _self, UIScene *scene, id context) {
        ((void (*)(id, SEL, UIScene *, id)) impl)(_self, nil, scene, context);
        
        UIWindowScene *windowScene = (UIWindowScene *) scene;
        if ([windowScene isKindOfClass:[UIWindowScene class]]) {
            auto window = windowScene.keyWindow;
            if (window) {
                auto windowProxy = msp_windowProxyForUIWindow(window);
                auto userInfo = @{
                    @"window": window,
                };
                [[NSNotificationCenter defaultCenter] postNotificationName:MSPNSWindowDidCreateNotificationName
                                                                    object:windowProxy
                                                                  userInfo:userInfo];
            }
        }
    }));
}

#endif
