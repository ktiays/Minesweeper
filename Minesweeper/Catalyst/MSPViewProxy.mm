//
//  Created by ktiays on 2024/11/28.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import "MSPViewProxy+Private.h"
#import "MSPUIHostingView.h"

@implementation MSPViewProxy {
    __weak NSView *_view;
}

+ (instancetype)proxyWithNSView:(NSView *)view {
    auto instance = [MSPViewProxy new];
    instance->_view = view;
    return instance;
}

- (CGRect)frame {
    return _view.frame;
}

- (void)setFrame:(CGRect)frame {
    _view.frame = frame;
}

- (void)addSubview:(id)view {
    if ([view isKindOfClass:[MSPUIHostingView class]]) {
        [(id) _view addSubview:[(MSPUIHostingView *) view hostingView]];
    } else if ([view isKindOfClass:[MSPViewProxy class]]) {
        [(id) _view addSubview:((MSPViewProxy *) view)->_view];
    } else {
        [(id) _view addSubview:view];
    }
}

- (void)removeFromSuperview {
    [(id) _view removeFromSuperview];
}

@end

#endif
