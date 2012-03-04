#import <Cocoa/Cocoa.h>

@class MiniScheduleAppDelegate;

@interface ScheduleView : NSView

- (NSFont *)titleFont;
- (NSColor *)titleColor;
- (float)itemHeight;
- (BOOL)autosizesWidth;

@end
