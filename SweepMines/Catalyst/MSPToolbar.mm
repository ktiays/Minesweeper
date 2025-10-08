//
//  Created by ktiays on 2024/11/30.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import <UIKit/UIKit.h>
#import "MSPToolbar.h"
#import "SweepMines-Swift.h"
#import "NSApplication.h"
#import "NSView.h"

@implementation MSPToolbar {
    UIView *_buttonContainerView;
    NSUInteger _animationID;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _animationID = 0;
        _buttonContainerView = [[UIView alloc] init];
        [self addSubview:_buttonContainerView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    auto bounds = self.bounds;
    const CGFloat padding = 12;
    if (_titleTextField) {
        auto titleRect = [(NSView *) _themeFrmae _titlebarTitleRect];
        auto titleSize = titleRect.size;
        _titleTextField.frame = CGRectMake(
            CGRectGetMinX(titleRect),
            (bounds.size.height - titleSize.height) / 2,
            titleSize.width,
            titleSize.height
        );
    }
    if (_replayButtonView) {
        auto size = [_replayButtonView intrinsicContentSize];
        auto origin = CGPointMake(bounds.size.width - size.width - padding, (bounds.size.height - size.height) / 2);
        _buttonContainerView.frame = CGRectMake(origin.x, origin.y, size.width, size.height);
        _replayButtonView.frame = CGRectMake(0, 0, size.width, size.height);
    }
}

#pragma mark - Public Methods

- (void)updateHierarchy {
    auto superview = self.superview;
    [superview bringSubviewToFront:self];
}

#pragma mark - Getters & Setters

- (void)setTitleTextField:(UIView *)titleTextField {
    _titleTextField = titleTextField;
    [self addSubview:titleTextField];
}

- (void)setReplayButtonView:(UIView *)replayButtonView {
    if (replayButtonView) {
        // Add new button.
        _buttonContainerView.alpha = 0;
        [_buttonContainerView addSubview:replayButtonView];
        if (!_replayButtonView) {
            [UIView animateWithDuration:0.28 animations:^{
                self->_buttonContainerView.alpha = 1;
            }];
        }
    } else {
        // Remove old button with animation.
        auto oldButton = _replayButtonView;
        auto animationID = ++_animationID;
        [UIView animateWithDuration:0.28 animations:^{
            self->_buttonContainerView.alpha = 0;
        } completion:^(BOOL finished) {
            if (animationID == self->_animationID) {
                [oldButton removeFromSuperview];
            }
        }];
    }
    
    _replayButtonView = replayButtonView;
    [self setNeedsLayout];
}

@end
#endif
