//
//  Created by ktiays on 2024/12/2.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import <objc/message.h>
#import <objc/runtime.h>

#import "MSPCatalystHelper.h"
#import "MSPMenuWindow.h"
#import "MSPUIHostingView.h"
#import "MSPWindowProxy+Private.h"
#import "SweepMines-Swift.h"
#import "NSAnimationContext.h"
#import "NSEvent.h"
#import "NSView.h"
#import "NSViewController.h"
#import "NSWindow.h"
#import "NSScreen.h"
#import "NSGlassEffectView.h"
#import "NSColor.h"

@implementation MSPMenuWindow {
    NSWindow *_window;
    MSPUIHostingView *_hostingView;

    id _localMonitor;
    id _globalMonitor;
}

- (void)dealloc {
    [self unregisterMonitor];
}

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController {
    self = [super init];
    if (self) {
        auto contentView = contentViewController.view;
        _hostingView = [[MSPUIHostingView alloc] initWithUIView:contentView];
        id nsViewController = [[NSClassFromString(@"NSViewController") alloc] init];
        // Create a new subclass for view controller.
        const auto className = [NSString stringWithFormat:@"%@_%p", @"MSPMenuViewController", nsViewController];
        auto menuViewControllerClass = objc_allocateClassPair([nsViewController class], className.UTF8String, 0);
        objc_registerClassPair(menuViewControllerClass);
        object_setClass(nsViewController, menuViewControllerClass);

        typeof(self) __weak weakSelf = self;        
        auto loadViewImpl = imp_implementationWithBlock(^(NSViewController *_self) {
            struct objc_super superInfo = {.receiver = _self, .super_class = class_getSuperclass([_self class])};
            ((void (*)(struct objc_super *, SEL)) objc_msgSendSuper)(&superInfo, @selector(loadView));

            if (!weakSelf) {
                return;
            }
            typeof(weakSelf) __strong self = weakSelf;

            _self.view.wantsLayer = true;
            _self.view.layer.cornerRadius = 10;
            _self.view.layer.cornerCurve = kCACornerCurveContinuous;
            _self.view.layer.masksToBounds = true;

            NSView *effectView;
            if (@available(macCatalyst 26, *)) {
                NSGlassEffectView *glassEffectView = [[NSClassFromString(@"NSGlassEffectView") alloc] init];
                auto glassTintColor = (NSColor *) [NSClassFromString(@"NSColor") colorNamed:@"BoardBackgroundColor"];
                glassEffectView.tintColor = [glassTintColor colorWithAlphaComponent:0.2];
                effectView = glassEffectView;
            } else {
                effectView = [[NSClassFromString(@"NSVisualEffectView") alloc] init];
                [effectView setValue:@(21) forKey:@"material"];
                [effectView setValue:@(1) forKey:@"state"];
            }
            [_self.view addSubview:effectView];
            effectView.translatesAutoresizingMaskIntoConstraints = false;
            [NSLayoutConstraint activateConstraints:@[
                [effectView.topAnchor constraintEqualToAnchor:_self.view.topAnchor],
                [effectView.bottomAnchor constraintEqualToAnchor:_self.view.bottomAnchor],
                [effectView.leadingAnchor constraintEqualToAnchor:_self.view.leadingAnchor],
                [effectView.trailingAnchor constraintEqualToAnchor:_self.view.trailingAnchor]
            ]];

            NSView *contentView = self->_hostingView.hostingNSView;
            [_self.view addSubview:contentView];
            contentView.translatesAutoresizingMaskIntoConstraints = false;
            [NSLayoutConstraint activateConstraints:@[
                [contentView.topAnchor constraintEqualToAnchor:effectView.topAnchor],
                [contentView.bottomAnchor constraintEqualToAnchor:effectView.bottomAnchor],
                [contentView.leadingAnchor constraintEqualToAnchor:effectView.leadingAnchor],
                [contentView.trailingAnchor constraintEqualToAnchor:effectView.trailingAnchor]
            ]];
        });
        class_addMethod(menuViewControllerClass, @selector(loadView), loadViewImpl, "v@:");

        const auto styleMask = NSWindowStyleMaskBorderless | NSWindowStyleMaskFullSizeContentView;
        _window = [NSWindow _windowWithContentViewController:nsViewController styleMask:styleMask];
        _window.opaque = false;
        _window.backgroundColor = [NSClassFromString(@"NSColor") clearColor];
        _window.level = kCGPopUpMenuWindowLevel;
        
        const auto eventMask = (1ULL << NSEventTypeLeftMouseDown) | (1ULL << NSEventTypeRightMouseDown) | (1ULL << NSEventTypeOtherMouseDown) | (1ULL << NSEventTypeKeyDown);
        _localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:eventMask handler:^NSEvent *(NSEvent *event) {
            if (weakSelf) {
                typeof(self) __strong self = weakSelf;
                [self handleEvents:event];
            }
            
            return event;
        }];
        _globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:eventMask handler:^(NSEvent *event) {
            if (weakSelf) {
                typeof(self) __strong self = weakSelf;
                [self handleEvents:event];
            }
        }];
    }
    return self;
}

- (void)popUpFromRect:(CGRect)frame inWindow:(UIWindow *)window {
    auto containerWindow = msp_windowProxyForUIWindow(window)->_window;
    if (!containerWindow) {
        return;
    }
    const auto flippedFrame = CGRectMake(frame.origin.x, containerWindow.frame.size.height - frame.origin.y - frame.size.height, frame.size.width, frame.size.height);
    const auto anchor = [containerWindow convertRectToScreen:flippedFrame];
    const auto menuSize = _hostingView.intrinsicContentSize;
    self.frame = CGRectMake(0, 0, menuSize.width, menuSize.height);
    [_window setFrameTopLeftPoint:CGPointMake(anchor.origin.x, anchor.origin.y - 8)];
    const auto visibleFrame = CGRectInset(_window.screen.visibleFrame, 8, 8);
    self.frame = adjustRectBoundedByContainer(_window.frame, visibleFrame);
    [containerWindow addChildWindow:_window ordered:NSWindowAbove];

    [[MSPMenuManager sharedManager] addMenu:self];
}

- (void)handleEvents:(NSEvent *)event {
    if (event.type == NSEventTypeKeyDown) {
        if (event.keyCode == 53) {
            [self close];
        }
        return;
    }
    
    CGPoint mouseLocation;
    auto eventWindow = event.window;
    if (eventWindow) {
        auto location = event.locationInWindow;
        mouseLocation = [eventWindow convertPointToScreen:location];
    } else {
        mouseLocation = NSEvent.mouseLocation;
    }

    const auto windowSize = _window.frame.size;
    const auto windowBounds = CGRectMake(0, 0, windowSize.width, windowSize.height);
    auto menuWindowFrame = [_window convertRectToScreen:windowBounds];
    if (!CGRectContainsPoint(menuWindowFrame, mouseLocation)) {
        [self close];
    }
}

- (void)close {
    [self unregisterMonitor];
    [self dismissMenu];
}

- (void)dismissMenu {
    _window.ignoresMouseEvents = true;
    [NSAnimationContext
        runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.24;
            [self->_window animator].alphaValue = 0;
        }
        completionHandler:^{
            [self->_window close];
            [[MSPMenuManager sharedManager] removeMenu:self];
        }];
}

- (void)unregisterMonitor {
    if (_localMonitor) {
        [NSEvent removeMonitor:_localMonitor];
        _localMonitor = nil;
    }
    if (_globalMonitor) {
        [NSEvent removeMonitor:_globalMonitor];
        _globalMonitor = nil;
    }
}

#pragma mark - Getters & Setters

- (void)setFrame:(CGRect)frame {
    [_window setFrame:frame display:YES];
}

- (CGRect)frame {
    return _window.frame;
}

@end

#endif
