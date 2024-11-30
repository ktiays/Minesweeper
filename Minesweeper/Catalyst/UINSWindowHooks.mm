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

static void configureTitlebarAppearsTransparent(void) {
    auto windowClass = NSClassFromString(@"UINSWindow");
    auto method = class_getInstanceMethod(windowClass, @selector(setTitlebarAppearsTransparent:));
    auto impl = method_getImplementation(method);
    auto newImpl = imp_implementationWithBlock(^(id _self, BOOL transparent) {
        ((void (*)(id, SEL, BOOL)) impl)(_self, nil, true);
    });
    method_setImplementation(method, newImpl);
}

static void configureTitlebarHeight(void) {
    auto themeFrameClass = NSClassFromString(@"NSThemeFrame");
    auto method = class_getInstanceMethod(themeFrameClass, sel_registerName("_titlebarHeight"));
    auto newImpl = imp_implementationWithBlock(^CGFloat(id _self) {
        return 52;
    });
    method_setImplementation(method, newImpl);

    auto trafficLightsImpl = imp_implementationWithBlock(^BOOL(id _self) {
        return YES;
    });
    method_setImplementation(class_getInstanceMethod(themeFrameClass, sel_registerName("_shouldCenterTrafficLights")), trafficLightsImpl);
}

static void configureToolbarLayout(void) {
    auto method = class_getInstanceMethod(UIWindow.class, @selector(layoutSubviews));
    auto impl = method_getImplementation(method);
    auto newImpl = imp_implementationWithBlock(^(UIWindow *window) {
        ((void (*)(id, SEL)) impl)(window, nil);

        auto toolbarManager = [MSPToolbarManager sharedManager];
        auto toolbar = [toolbarManager toolbarForWindow:window];
        auto leadingSpace = toolbarManager.leadingSpace;
        toolbar.frame = CGRectMake(leadingSpace, 0, window.frame.size.width - leadingSpace, 52);
    });
    method_setImplementation(method, newImpl);
}

static void configureTitlebar(void) {
    configureTitlebarAppearsTransparent();
    configureTitlebarHeight();

    auto titlebarViewClass = NSClassFromString(@"NSTitlebarView");
    auto selector = @selector(addSubview:);
    auto method = class_getInstanceMethod(titlebarViewClass, selector);
    auto impl = imp_implementationWithBlock(^(id _self, NSView *subview) {
        struct objc_super superInfo = {.receiver = _self, .super_class = class_getSuperclass([_self class])};
        if ([NSStringFromClass([subview class]) isEqualToString:@"NSTextField"]) {
            return;
        }
        ((void (*)(struct objc_super *, SEL, NSView *)) objc_msgSendSuper)(&superInfo, selector, subview);
    });
    class_addMethod(titlebarViewClass, sel_registerName("addSubview:"), impl, "v@:@");
}

void prepareUINSWindow(void) {
    configureTitlebar();
    configureToolbarLayout();
}

#endif
