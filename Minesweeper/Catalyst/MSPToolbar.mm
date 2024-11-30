//
//  Created by ktiays on 2024/11/30.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import "MSPToolbar.h"
#import "Minesweeper-Swift.h"
#import "NSApplication.h"

@implementation MSPToolbar {
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    auto bounds = self.bounds;
    if (_titleTextField) {
        auto size = [_titleTextField bounds].size;
        auto origin = CGPointMake(12, (bounds.size.height - size.height) / 2);
        _titleTextField.frame = CGRectMake(origin.x, origin.y, size.width, size.height);
    }
}

#pragma mark - Public Methods

- (void)updateTitleLabel {
    
}

#pragma mark - Getters & Setters

- (void)setTitleTextField:(UIView *)titleTextField {
    _titleTextField = titleTextField;
    [self addSubview:titleTextField];
}

@end
#endif
