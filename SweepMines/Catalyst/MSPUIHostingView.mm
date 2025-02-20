//
//  Created by ktiays on 2024/11/29.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import <objc/runtime.h>
#import <objc/message.h>

#import "MSPUIHostingView.h"
#import "NSView.h"

@implementation MSPUIHostingView {
    NSView *_hostingView;
}

- (instancetype)initWithUIView:(UIView *)view {
    self = [super init];
    if (self) {
        const auto className = @"UINSSceneHostingView";
        auto viewClass = NSClassFromString(className);
        _hostingView = [[viewClass alloc] initWithUIView:view];
        _mouseDownCanMoveWindow = YES;
        
        auto newClassName = [NSString stringWithFormat:@"%@_%p", className, self];
        auto newClass = objc_allocateClassPair(viewClass, newClassName.UTF8String, 0);
        objc_registerClassPair(newClass);
        object_setClass(_hostingView, newClass);
        
        typeof(self) __weak weakSelf = self;
        class_addMethod(newClass, @selector(mouseDownCanMoveWindow), imp_implementationWithBlock(^BOOL (id _self) {
            if (!weakSelf) {
                return NO;
            }
            
            typeof(weakSelf) __strong strongSelf = weakSelf;
            return strongSelf->_mouseDownCanMoveWindow;
        }), "c@:");
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    UIView *uiView = [_hostingView valueForKey:@"uiView"];
    return uiView.intrinsicContentSize;
}

- (id)hostingNSView {
    return _hostingView;
}

- (CGRect)frame {
    return _hostingView.frame;
}

- (void)setFrame:(CGRect)frame {
    _hostingView.frame = frame;
}

- (void)removeFromSuperview {
    [_hostingView removeFromSuperview];
}

@end

#endif
