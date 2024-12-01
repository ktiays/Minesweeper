//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import <QuartzCore/QuartzCore.h>

#import "MSPWindowProxy+Private.h"
#import "MSPViewProxy+Private.h"

@implementation MSPWindowProxy

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

- (void)setToolbar:(id)toolbar {
    _window.toolbar = toolbar;
}

- (id)toolbar {
    return _window.toolbar;
}

- (MSPViewProxy *)toolbarView {
    auto toolbar = (NSObject *) _window.toolbar;
    auto toolbarView = (NSView *) [toolbar valueForKey:@"_toolbarView"];
    return [MSPViewProxy proxyWithNSView:toolbarView];
}

- (MSPViewProxy *)contentView {
    return [MSPViewProxy proxyWithNSView:_window.contentView];
}

- (BOOL)isFullScreen {
    return _window.styleMask & NSWindowStyleMaskFullScreen;
}

@end

#endif
