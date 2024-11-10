//
//  Created by ktiays on 2024/11/8.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef NSApplication_h
#define NSApplication_h

#import <Foundation/Foundation.h>

#import "UINSApplicationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSApplication : NSObject

@property (nonatomic, weak) UINSApplicationDelegate *delegate;

+ (NSApplication *)sharedApplication;

@end

NS_ASSUME_NONNULL_END

#endif /* NSApplication_h */
