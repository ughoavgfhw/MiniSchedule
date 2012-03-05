#import "ScheduleView.h"
#import "MiniScheduleAppDelegate.h"
#import <CalendarStore/CalendarStore.h>

#define XOFFSET 21
#define DEFAULT_TEXT @"No Events"

@implementation ScheduleView

- (void)awakeFromNib {
	[[MiniScheduleAppDelegate shared] addObserver:self forKeyPath:@"events" options:0 context:nil];
	[self observeValueForKeyPath:@"events" ofObject:[MiniScheduleAppDelegate shared] change:nil context:nil];
}
- (void)dealloc {
	[[MiniScheduleAppDelegate shared] removeObserver:self forKeyPath:@"events"];
	[super dealloc];
}

- (NSString *)descriptionForEvent:(CalEvent *)event {
	static NSDateFormatter *formatter = nil;
	if(!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[formatter setTimeStyle:NSDateFormatterShortStyle];
		[formatter setDateStyle:NSDateFormatterNoStyle];
	}
	NSString *str;
	if(event.isAllDay) str = event.title;
	else str = [NSString stringWithFormat:@"%@: %@",[formatter stringFromDate:event.startDate],event.title];
	if(event.location) str = [str stringByAppendingFormat:@" -- %@",event.location];
	return str;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath isEqualToString:@"events"]) {
		NSArray *events = [MiniScheduleAppDelegate shared].events;
		NSUInteger count = [events count];
		NSSize size = {self.frame.size.width,[self itemHeight]};
		if(count) {
			if([self autosizesWidth]) {
				NSDictionary *textOpts = [NSDictionary dictionaryWithObjectsAndKeys:[self titleFont],NSFontAttributeName,[self titleColor],NSForegroundColorAttributeName,nil];
				size.width = 0;
				for(CalEvent *event in events) {
					NSSize eventSize = [[self descriptionForEvent:event] sizeWithAttributes:textOpts];
					if(eventSize.width > size.width) size.width = eventSize.width;
				}
				size.width += 2*XOFFSET;
				if(size.width > 512) size.width = 512;
			}
			size.height *= count;
		} else {
			if([self autosizesWidth]) {
				NSDictionary *textOpts = [NSDictionary dictionaryWithObjectsAndKeys:[self titleFont],NSFontAttributeName,[self titleColor],NSForegroundColorAttributeName,nil];
				size.width = [DEFAULT_TEXT sizeWithAttributes:textOpts].width + 2*XOFFSET;
			}
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
    NSArray *events = [[MiniScheduleAppDelegate shared] events];
	NSDictionary *textOpts = [NSDictionary dictionaryWithObjectsAndKeys:[self titleFont],NSFontAttributeName,[self titleColor],NSForegroundColorAttributeName,nil];
	if([events count] == 0) {
		[DEFAULT_TEXT drawAtPoint:NSMakePoint(XOFFSET,0) withAttributes:textOpts];
		return;
	}
	NSRect rect = self.bounds;
	rect.size.width -= XOFFSET*2;
	rect.origin.x += XOFFSET;
	NSRectClip(rect);
	NSPoint point = (NSPoint){XOFFSET,0};
	float height = [self itemHeight];
	for(CalEvent *event in events) {
		[[self descriptionForEvent:event] drawAtPoint:point withAttributes:textOpts];
		point.y += height;
	}
}

@end
