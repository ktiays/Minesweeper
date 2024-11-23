//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import "MSPWindowProxy+Private.h"

@implementation MSPWindowProxy {
    UINSWindowProxy *_windowProxy;
    NSWindow *_window;
}

+ (instancetype)proxyWithUINSWindowProxy:(UINSWindowProxy *)proxy {
    auto instance = [MSPWindowProxy new];
    instance->_windowProxy = proxy;
    instance->_window = proxy.attachedWindow;
    return instance;
}

- (CGSize)minSize {
    return _window.minSize;
}

- (void)setMinSize:(CGSize)minSize {
    _window.minSize = minSize;
}

- (CGSize)maxSize {
    return _window.maxSize;
}

- (void)setMaxSize:(CGSize)maxSize {
    _window.maxSize = maxSize;
}

- (CGRect)frame {
    return _window.frame;
}

- (void)setFrame:(CGRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animateFlag {
    [[_window animator] setFrame:frameRect display:displayFlag animate:animateFlag];
}

@end

#endif
