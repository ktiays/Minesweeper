//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import "MSPCatalystHelper.h"

#if TARGET_OS_MACCATALYST

#import "UINSWindowHooks.h"
#import "UINSApplicationDelegateHooks.h"

#import "NSApplication.h"
#import "MSPWindowProxy+Private.h"

const NSNotificationName MSPNSWindowDidCreateNotificationName = @"MSPNSWindowDidCreateNotification";

MSPWindowProxy *msp_windowProxyForUIWindow(UIWindow *window) {
    if (!window) {
        return nil;
    }
    
    auto application = [NSClassFromString(@"NSApplication") sharedApplication];
    UINSApplicationDelegate *delegate = application.delegate;
    auto windowProxy = [delegate hostWindowForUIWindow:window];
    return [MSPWindowProxy proxyWithUINSWindowProxy:windowProxy];
}

@implementation MSPCatalystHelper

+ (void)load {
    prepareUINSWindow();
    prepareUINSApplicationDelegate();
}

@end

#endif
