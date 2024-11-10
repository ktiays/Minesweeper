//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <objc/runtime.h>
#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import "UINSWindowHooks.h"

void prepareUINSWindow(void) {
    auto windowClass = NSClassFromString(@"UINSWindow");
    auto method = class_getInstanceMethod(windowClass, @selector(setTitlebarAppearsTransparent:));
    auto impl = method_getImplementation(method);
    method_setImplementation(method, imp_implementationWithBlock(^(id _self, BOOL transparent) {
        ((void (*)(id, SEL, BOOL)) impl)(_self, nil, true);
    }));
}

#endif
