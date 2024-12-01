//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import "UINSApplicationDelegateHooks.h"
#import "MSPCatalystHelper.h"
#import "MSPWindowProxy+Private.h"
#import "NSView.h"
#import "Minesweeper-Swift.h"
#import "MSPToolbar.h"

@interface NSObject (MinesweeperPrivate)

- (instancetype)initWithUIView:(UIView *)view;
- (void)_removeTitleTextField;
- (NSView *)_titleTextField;
- (NSAttributedString *)_currentTitleTextFieldAttributedString;
- (CGRect)_titlebarTitleRect;
- (CGFloat)_toolbarLeadingSpace;
- (instancetype)initWithContentNSView:(NSView *)contentNSView;

@end

void prepareUINSApplicationDelegate(void) {
    auto appDelegateClass = NSClassFromString(@"UINSApplicationDelegate");
    auto method = class_getInstanceMethod(appDelegateClass, @selector(didCreateUIScene:transitionContext:));
    auto impl = method_getImplementation(method);
    method_setImplementation(method, imp_implementationWithBlock(^(id _self, UIScene *scene, id context) {
        ((void (*)(id, SEL, UIScene *, id)) impl)(_self, nil, scene, context);
        
        UIWindowScene *windowScene = (UIWindowScene *) scene;
        if ([windowScene isKindOfClass:[UIWindowScene class]]) {
            auto window = windowScene.keyWindow;
            if (window) {
                auto windowProxy = msp_windowProxyForUIWindow(window);
                auto nsWindow = windowProxy->_window;
                auto themeFrame = nsWindow.contentView.superview;
                auto titleTextField = [themeFrame _titleTextField];
                [titleTextField removeFromSuperview];
                
                auto manager = [MSPToolbarManager sharedManager];
                manager.leadingSpace = [themeFrame _toolbarLeadingSpace];
                auto toolbar = [manager toolbarForWindow:window];
                [window addSubview:toolbar];
                UIView *textFieldUIView = [[NSClassFromString(@"_UINSView") alloc] initWithContentNSView:titleTextField];
                toolbar.titleTextField = textFieldUIView;
                auto size = [themeFrame _titlebarTitleRect].size;
                textFieldUIView.frame = CGRectMake(0, 0, size.width, size.height);
                
                // Patch `removeFromSuperview` method of system text field to avoid view hierarchy error.
                auto textFieldClass = [titleTextField class];
                auto newClassName = [NSString stringWithFormat:@"%@_%p", NSStringFromClass(textFieldClass), titleTextField];
                auto newTextFieldClass = objc_allocateClassPair(textFieldClass, newClassName.UTF8String, 0);
                object_setClass(titleTextField, newTextFieldClass);
                auto emptyImpl = imp_implementationWithBlock(^(id value) {});
                class_addMethod(newTextFieldClass, @selector(removeFromSuperview), emptyImpl, "v@:");
            }
        }
    }));
}

#endif
