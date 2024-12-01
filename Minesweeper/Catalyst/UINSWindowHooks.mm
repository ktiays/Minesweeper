//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "MSPToolbar.h"
#import "Minesweeper-Swift.h"
#import "NSView.h"
#import "UINSWindowHooks.h"
#import "MSPCatalystHelper.h"

static void configureTitlebarAppearsTransparent(void) {
    auto windowClass = NSClassFromString(@"UINSWindow");
    auto method = class_getInstanceMethod(windowClass, @selector(setTitlebarAppearsTransparent:));
    auto impl = method_getImplementation(method);
    auto newImpl = imp_implementationWithBlock(^(id _self, BOOL transparent) {
        ((void (*)(id, SEL, BOOL)) impl)(_self, nil, true);
    });
    method_setImplementation(method, newImpl);
    
    auto setStyleMaskSelector = sel_registerName("setCollectionBehavior:");
    auto setStyleMaskImpl = imp_implementationWithBlock(^(NSWindow *window, NSUInteger collectionBehavior) {
        const auto NSWindowCollectionBehaviorFullScreenPrimary = 1 << 7;
        if ([window isKindOfClass:NSClassFromString(@"UINSWindow")]) {
            collectionBehavior &= ~NSWindowCollectionBehaviorFullScreenPrimary;
        }
        struct objc_super superInfo = {.receiver = window, .super_class = class_getSuperclass([window class])};
        ((void (*)(struct objc_super *, SEL, NSUInteger)) objc_msgSendSuper)(&superInfo, setStyleMaskSelector, collectionBehavior);
    });
    class_addMethod(windowClass, setStyleMaskSelector, setStyleMaskImpl, "v@:Q");
}

static void configureTitlebarHeight(void) {
    auto themeFrameClass = NSClassFromString(@"NSThemeFrame");
    auto method = class_getInstanceMethod(themeFrameClass, sel_registerName("_titlebarHeight"));
    auto impl = method_getImplementation(method);
    auto newImpl = imp_implementationWithBlock(^CGFloat (NSView *_self) {
        auto window = _self.window;
        if ([window isKindOfClass:NSClassFromString(@"UINSWindow")]) {
            return MSPToolbarManager.defaultToolbarHeight;
        }
        return ((CGFloat (*)(id, SEL)) impl)(_self, nil);
    });
    method_setImplementation(method, newImpl);

    auto shouldCenterTrafficLightsSelector = sel_registerName("_shouldCenterTrafficLights");
    auto trafficLightsMethod = class_getInstanceMethod(themeFrameClass, shouldCenterTrafficLightsSelector);
    auto trafficLightsImpl = method_getImplementation(trafficLightsMethod);
    auto newTrafficLightsImpl = imp_implementationWithBlock(^BOOL (NSView *_self) {
        auto window = _self.window;
        if ([window isKindOfClass:NSClassFromString(@"UINSWindow")]) {
            return YES;
        }
        return ((BOOL (*)(id, SEL)) trafficLightsImpl)(_self, nil);
    });
    method_setImplementation(trafficLightsMethod, newTrafficLightsImpl);
}

static void configureTitleBarVisibility(void) {
    auto titleBarClass = NSClassFromString(@"NSTitlebarContainerView");
    auto selector = sel_registerName("viewDidMoveToSuperview");
    auto impl = imp_implementationWithBlock(^(NSView *_self) {
        struct objc_super superInfo = {.receiver = _self, .super_class = class_getSuperclass([_self class])};
        ((void (*)(struct objc_super *, SEL)) objc_msgSendSuper)(&superInfo, selector);
        
        auto superview = _self.superview;
        BOOL isVisible = superview != nil;
        
        id window = isVisible ? superview.window : _self.window;
        if (![NSStringFromClass([window class]) isEqualToString:@"UINSWindow"]) {
            return;
        }
        NSArray<UIWindow *> *uiWindows = [window valueForKey:@"uiWindows"];
        UIWindow *uiWindow;
        for (UIWindow *window in uiWindows) {
            if (window.isKeyWindow) {
                uiWindow = window;
                break;
            }
        }
        if (!uiWindow) {
            return;
        }
        auto userInfo = @{
            @"UIWindow": uiWindow,
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:MSPNSTitlebarContainerViewVisibilityDidChangeNotificationName
                                                            object:@(isVisible)
                                                          userInfo:userInfo];
    });
    class_addMethod(titleBarClass, selector, impl, "v@:");
}

static void configureToolbarLayout(void) {
    auto method = class_getInstanceMethod(UIWindow.class, @selector(layoutSubviews));
    auto impl = method_getImplementation(method);
    auto newImpl = imp_implementationWithBlock(^(UIWindow *window) {
        ((void (*)(id, SEL)) impl)(window, nil);

        auto toolbarManager = [MSPToolbarManager sharedManager];
        auto toolbar = [toolbarManager toolbarForWindow:window];
        if (toolbar.superview != window) {
            return;
        }
        auto isVisible = [toolbarManager isTitleBarVisibleForWindow:window];
        auto leadingSpace = toolbarManager.leadingSpace * (isVisible ? 1 : 0);
        toolbar.frame = CGRectMake(leadingSpace, 0, window.bounds.size.width - leadingSpace, MSPToolbarManager.defaultToolbarHeight);
    });
    method_setImplementation(method, newImpl);
}

static void configureTitlebar(void) {
    configureTitlebarAppearsTransparent();
    configureTitlebarHeight();
    configureTitleBarVisibility();

    auto titlebarViewClass = NSClassFromString(@"NSTitlebarView");
    auto selector = @selector(addSubview:);
    auto impl = imp_implementationWithBlock(^(id _self, NSView *subview) {
        struct objc_super superInfo = {.receiver = _self, .super_class = class_getSuperclass([_self class])};
        if ([NSStringFromClass([subview class]) isEqualToString:@"NSTextField"]) {
            return;
        }
        ((void (*)(struct objc_super *, SEL, NSView *)) objc_msgSendSuper)(&superInfo, selector, subview);
    });
    class_addMethod(titlebarViewClass, selector, impl, "v@:@");
}

void prepareUINSWindow(void) {
    configureTitlebar();
    configureToolbarLayout();
}

#endif
