//
//  Created by ktiays on 2024/11/30.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#ifndef _UINSView_h
#define _UINSView_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NSView;

@interface _UINSView : UIView

@property (nonatomic, strong) NSView *contentNSView;

- (instancetype)initWithContentNSView:(NSView *)view;

@end

NS_ASSUME_NONNULL_END

#endif /* _UINSView_h */
