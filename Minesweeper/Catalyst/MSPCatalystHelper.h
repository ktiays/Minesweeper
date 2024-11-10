//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if TARGET_OS_MACCATALYST

#import "MSPWindowProxy.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT MSPWindowProxy *msp_windowProxyForUIWindow(UIWindow *window);

FOUNDATION_EXPORT const NSNotificationName MSPNSWindowDidCreateNotificationName;

NS_SWIFT_NAME(CatalystHelper)
@interface MSPCatalystHelper : NSObject

@end

NS_ASSUME_NONNULL_END

#endif
