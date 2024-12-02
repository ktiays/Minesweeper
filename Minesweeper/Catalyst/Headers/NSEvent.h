//
//  Created by ktiays on 2024/12/2.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#ifndef NSEvent_h
#define NSEvent_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NSEventType) {        /* various types of events */
    NSEventTypeLeftMouseDown             = 1,
    NSEventTypeLeftMouseUp               = 2,
    NSEventTypeRightMouseDown            = 3,
    NSEventTypeRightMouseUp              = 4,
    NSEventTypeMouseMoved                = 5,
    NSEventTypeLeftMouseDragged          = 6,
    NSEventTypeRightMouseDragged         = 7,
    NSEventTypeMouseEntered              = 8,
    NSEventTypeMouseExited               = 9,
    NSEventTypeKeyDown                   = 10,
    NSEventTypeKeyUp                     = 11,
    NSEventTypeFlagsChanged              = 12,
    NSEventTypeAppKitDefined             = 13,
    NSEventTypeSystemDefined             = 14,
    NSEventTypeApplicationDefined        = 15,
    NSEventTypePeriodic                  = 16,
    NSEventTypeCursorUpdate              = 17,
    NSEventTypeScrollWheel               = 22,
    NSEventTypeTabletPoint               = 23,
    NSEventTypeTabletProximity           = 24,
    NSEventTypeOtherMouseDown            = 25,
    NSEventTypeOtherMouseUp              = 26,
    NSEventTypeOtherMouseDragged         = 27,
    /* The following event types are available on some hardware on 10.5.2 and later */
    NSEventTypeGesture= 29,
    NSEventTypeMagnify= 30,
    NSEventTypeSwipe  = 31,
    NSEventTypeRotate = 18,
    NSEventTypeBeginGesture = 19,
    NSEventTypeEndGesture = 20,
    
    NSEventTypeSmartMagnify = 32,
    NSEventTypeQuickLook = 33,
    
    NSEventTypePressure = 34,
    NSEventTypeDirectTouch = 37,

    NSEventTypeChangeMode = 38,
};

@interface NSEvent : NSObject

@property (class, readonly) NSPoint mouseLocation;
/// The window object associated with the event.
@property (readonly, nullable, weak) NSWindow *window;
/// The event location in the base coordinate system of the associated window.
@property (readonly) NSPoint locationInWindow;
/// The virtual code for the key associated with the event.
@property (readonly) unsigned short keyCode;
@property (readonly) NSEventType type;

/// Installs an event monitor that receives copies of events the system posts to this app prior to their dispatch.
+ (id)addLocalMonitorForEventsMatchingMask:(NSUInteger)mask
                                   handler:(NSEvent * _Nullable (^)(NSEvent *event))block;

/// Installs an event monitor that receives copies of events the system posts to other applications.
+ (id)addGlobalMonitorForEventsMatchingMask:(NSUInteger)mask
                                    handler:(void (^)(NSEvent *event))block;

/// Removes the specified event monitor.
+ (void)removeMonitor:(id)eventMonitor;

@end

NS_ASSUME_NONNULL_END

#endif /* NSEvent_h */
