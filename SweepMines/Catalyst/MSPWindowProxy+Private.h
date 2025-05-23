//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import "MSPWindowProxy.h"
#import "UINSWindowProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPWindowProxy () {
    @package
    __weak UINSWindowProxy *_windowProxy;
    __weak NSWindow *_window;
}

+ (instancetype)proxyWithUINSWindowProxy:(UINSWindowProxy *)proxy;

@end

NS_ASSUME_NONNULL_END
