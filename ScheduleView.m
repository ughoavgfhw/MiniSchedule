#import "ScheduleView.h"
#import "MiniScheduleAppDelegate.h"
#import <CalendarStore/CalendarStore.h>

#define XOFFSET 21

@implementation ScheduleView

- (void)awakeFromNib {
	[[MiniScheduleAppDelegate shared] addObserver:self forKeyPath:@"events" options:0 context:nil];
	[self observeValueForKeyPath:@"events" ofObject:[MiniScheduleAppDelegate shared] change:nil context:nil];
}
- (void)dealloc {
	[[MiniScheduleAppDelegate shared] removeObserver:self forKeyPath:@"events"];
	[super dealloc];
}

// TODO: calculate necessary width
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath isEqualToString:@"events"]) {
		NSUInteger count = [[[MiniScheduleAppDelegate shared] events] count];
		NSSize size;
		if(count) {
			size.width = self.frame.size.width;
			if([self autosizesWidth]) {
				
			}
			size.height = count * [self itemHeight];
		} else {
			count = 1;
			size.width = self.frame.size.width;
			size.height = [self itemHeight];
		}
		[self setFrameSize:size];
		[self setNeedsDisplay:YES];
	} else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (BOOL)isFlipped {
	return YES;
}

- (NSFont *)titleFont {
	return [NSFont systemFontOfSize:14];
}
- (NSColor *)titleColor {
	return [NSColor whiteColor];
}
- (float)itemHeight {
	return 20;
}
- (BOOL)autosizesWidth {
	return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
	static NSDateFormatter *formatter = nil;
    NSArray *events = [[MiniScheduleAppDelegate shared] events];
	NSDictionary *textOpts = [NSDictionary dictionaryWithObjectsAndKeys:[self titleFont],NSFontAttributeName,[self titleColor],NSForegroundColorAttributeName,nil];
	if([events count] == 0) {
		[@"No Events" drawAtPoint:NSMakePoint(XOFFSET,0) withAttributes:textOpts];
		return;
	}
	if(!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[formatter setTimeStyle:NSDateFormatterShortStyle];
		[formatter setDateStyle:NSDateFormatterNoStyle];
	}
	NSRect rect = self.bounds;
	rect.size.width -= XOFFSET*2;
	rect.origin.x += XOFFSET;
	NSRectClip(rect);
	NSPoint point = (NSPoint){XOFFSET,0};
	float height = [self itemHeight];
	for(CalEvent *event in events) {
		NSString *str;
		if(event.isAllDay) str = event.title;
		else str = [NSString stringWithFormat:@"%@: %@",[formatter stringFromDate:event.startDate],event.title];
		if(event.location) str = [str stringByAppendingFormat:@" -- %@",event.location];
		[str drawAtPoint:point withAttributes:textOpts];
		point.y += height;
	}
}

@end
