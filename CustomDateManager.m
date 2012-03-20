#import "CustomDateManager.h"
#import "MiniScheduleAppDelegate.h"
#import "NSDate+DayTimeAdditions.h"

#define DAY_SECONDS (24*60*60)

@interface CustomDateManager ()

@property (nonatomic, retain) NSPanel *chooserPanel;
@property (nonatomic, retain) NSView *fixedHeader, *relativeHeader, *fixedDate,
								*relativeDate, *fixedTime, *relativeTime;
@property (nonatomic, assign) NSView *containerView;

@property (nonatomic) NSInteger relativeStart;
@property (nonatomic) NSUInteger relativeLength;
@property (nonatomic) enum DateRangeMode selectedMode;
@property (nonatomic, retain) NSDate *fixedStartDate, *fixedStartTime, *fixedEndDate, *fixedEndTime;
@property (nonatomic) int relativeStartDays, relativeStartHours, relativeStartMins;
@property (nonatomic) unsigned daysLength, hoursLength, minsLength;

@end

@implementation CustomDateManager

+ (NSSet *)keyPathsForValuesAffectingCustomDateInfo {
	static NSSet *dateInfoSet = nil;
	if(!dateInfoSet) dateInfoSet = [[NSSet alloc] initWithObjects:@"relativeStartDays", @"relativeStartHours", @"relativeStartMins", @"daysLength", @"hoursLength", @"minsLength", @"fixedStartDate", @"fixedEndDate", @"fixedStartTime", @"fixedEndTime", @"selectedMode", nil];
	return dateInfoSet;
}
+ (NSSet *)keyPathsForValuesAffectingRelativeStart {
	static NSSet *startSet = nil;
	if(!startSet) startSet = [[NSSet alloc] initWithObjects:@"relativeStartDays", @"relativeStartHours", @"relativeStartMins", nil];
	return startSet;
}
+ (NSSet *)keyPathsForValuesAffectingRelativeLength {
	static NSSet *lengthSet = nil;
	if(!lengthSet) lengthSet = [[NSSet alloc] initWithObjects:@"daysLength", @"hoursLength", @"minsLength", nil];
	return lengthSet;
}

@synthesize chooserPanel, fixedHeader, relativeHeader, fixedDate, relativeDate,
		fixedTime, relativeTime, containerView, relativeStartDays, relativeStartHours,
		relativeStartMins, daysLength, hoursLength, minsLength, fixedStartDate,
		fixedEndDate, fixedStartTime, fixedEndTime;

- (void)resetContainerView {
	[containerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	NSPoint origin = containerView.bounds.origin;
	NSView *currentView;
	origin.y += containerView.bounds.size.height + 2;
#define ADDVIEW(view) \
	currentView = (view),\
	origin.y -= 2 + currentView.frame.size.height,\
	[currentView setFrameOrigin:origin],\
	[containerView addSubview:currentView] 
	switch(selectedMode) {
		case RelativeDateAndTime:
			ADDVIEW(relativeHeader);
			ADDVIEW(relativeDate);
			ADDVIEW(relativeTime);
			break;
		case FixedTime:
			ADDVIEW(relativeHeader);
			ADDVIEW(relativeDate);
			ADDVIEW(fixedHeader);
			ADDVIEW(fixedTime);
			break;
		case FixedDateAndTime:
			ADDVIEW(fixedHeader);
			ADDVIEW(fixedDate);
			ADDVIEW(fixedTime);
			break;
	}
#undef ADDVIEW
	NSRect frame = chooserPanel.frame;
	frame.origin.y += origin.y;
	frame.size.height -= origin.y;
	[chooserPanel setFrame:frame display:YES animate:YES];
}

- (void)awakeFromNib {
	[self resetContainerView];
}

- (enum DateRangeMode)selectedMode {
	return selectedMode;
}
- (void)setSelectedMode:(enum DateRangeMode)newMode {
	if(selectedMode != newMode) {
		++preventDelegateNotifications;
		switch(selectedMode) {
			case RelativeDateAndTime:
				switch(newMode) {
					case RelativeDateAndTime:
						break;
					case FixedDateAndTime:
						self.fixedStartDate = [NSDate dateWithTimeIntervalSinceNow:DAY_SECONDS * self.relativeStartDays];
						self.fixedEndDate = [self.fixedStartDate dateByAddingTimeInterval:DAY_SECONDS * self.daysLength];
					case FixedTime:
						self.fixedStartTime = [NSDate dateWithTimeIntervalSinceNow:(self.relativeStartHours*60 + self.relativeStartMins)*60];
						self.fixedEndTime = [self.fixedStartTime dateByAddingTimeInterval:(self.hoursLength*60 + self.minsLength)*60];
						break;
				}
				break;
			case FixedTime:
				switch(newMode) {
					case RelativeDateAndTime: {
						SInt64 offset = (SInt64)[self.fixedStartTime timeIntervalIntoDay];
						SInt64 length = (SInt64)[self.fixedEndTime timeIntervalIntoDay] - offset;
						offset -= (SInt64)[[NSDate date] timeIntervalIntoDay];
						UInt64 tmp = (offset < 0 ? offset + DAY_SECONDS : offset) / 60;
						self.relativeStartMins = tmp % 60;
						self.relativeStartHours = tmp / 60;
						tmp = (length < 0 ? length + DAY_SECONDS : length) / 60;
						self.minsLength = tmp % 60;
						self.hoursLength = tmp / 60;
					}
						break;
					case FixedTime:
						break;
					case FixedDateAndTime:
						self.fixedStartDate = [NSDate dateWithTimeIntervalSinceNow:DAY_SECONDS * self.relativeStartDays];
						self.fixedEndDate = [self.fixedStartDate dateByAddingTimeInterval:DAY_SECONDS * self.daysLength];
						break;
				}
				break;
			case FixedDateAndTime:
				switch(newMode) {
					case RelativeDateAndTime: {
						self.relativeStartDays = [self.fixedStartDate timeIntervalSinceNow] / DAY_SECONDS;
						self.daysLength = [self.fixedEndDate timeIntervalSinceDate:self.fixedStartDate] / DAY_SECONDS;
					}
					case FixedTime: {
						SInt64 offset = (SInt64)[self.fixedStartTime timeIntervalIntoDay];
						SInt64 length = (SInt64)[self.fixedEndTime timeIntervalIntoDay] - offset;
						offset -= (SInt64)[[NSDate date] timeIntervalIntoDay];
						UInt64 tmp = (offset < 0 ? offset + DAY_SECONDS : offset) / 60;
						self.relativeStartMins = tmp % 60;
						self.relativeStartHours = tmp / 60;
						tmp = (length < 0 ? length + DAY_SECONDS : length) / 60;
						self.minsLength = tmp % 60;
						self.hoursLength = tmp / 60;
					}
						break;
					case FixedDateAndTime:
						break;
				}
				break;
		}
		selectedMode = newMode;
		[self resetContainerView];
		--preventDelegateNotifications;
	}
}

- (NSInteger)relativeStart {
	return relativeStartDays * (24*60) + relativeStartHours * 60 + relativeStartMins;
}
- (void)setRelativeStart:(NSInteger)relativeStart {
	[self willChangeValueForKey:@"relativeStartDays"];
	[self willChangeValueForKey:@"relativeStartHours"];
	[self willChangeValueForKey:@"relativeStartMins"];
	relativeStartMins = relativeStart % 60;
	relativeStart /= 60;
	relativeStartHours = relativeStart % 24;
	relativeStartDays = relativeStart / 24;
	[self didChangeValueForKey:@"relativeStartMins"];
	[self didChangeValueForKey:@"relativeStartHours"];
	[self didChangeValueForKey:@"relativeStartDays"];
}
- (NSUInteger)relativeLength {
	return daysLength * (24*60) + hoursLength * 60 + minsLength;
}
- (void)setRelativeLength:(NSUInteger)relativeLength {
	[self willChangeValueForKey:@"daysLength"];
	[self willChangeValueForKey:@"hoursLength"];
	[self willChangeValueForKey:@"minsLength"];
	minsLength = relativeLength % 60;
	relativeLength /= 60;
	hoursLength = relativeLength % 24;
	daysLength = relativeLength / 24;
	[self didChangeValueForKey:@"minsLength"];
	[self didChangeValueForKey:@"hoursLength"];
	[self didChangeValueForKey:@"daysLength"];
}

- (id<CustomDateManagerDelegate>)delegate {
	return delegate;
}
- (void)setDelegate:(id<CustomDateManagerDelegate>)newDelegate {
	if(delegate != newDelegate) {
		if(delegate) {
			[self removeObserver:self forKeyPath:@"customDateInfo"];
			delegate = nil;
		}
		if(newDelegate) {
			++preventDelegateNotifications;
			struct DateInfo info = newDelegate.customDateInfo;
			switch(info.mode) {
				case RelativeDateAndTime:
					self.relativeStart = info.relative.startOffset;
					self.relativeLength = info.relative.length;
					break;
				case FixedTime:
					self.relativeStartDays = info.fixedTime.startOffset;
					self.daysLength = info.fixedTime.length;
					self.fixedStartTime = info.fixedTime.startTime;
					self.fixedEndTime = info.fixedTime.endTime;
					break;
				case FixedDateAndTime:
					self.fixedStartDate = info.fixed.start;
					self.fixedStartTime = info.fixed.start;
					self.fixedEndDate = info.fixed.end;
					self.fixedEndTime = info.fixed.end;
					break;
			}
			self.selectedMode = info.mode;
			delegate = newDelegate;
			[self addObserver:self forKeyPath:@"customDateInfo" options:0 context:NULL];
			--preventDelegateNotifications;
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath isEqualToString:@"customDateInfo"] && object == self) {
		if(preventDelegateNotifications) return;
		struct DateInfo info;
		info.mode = self.selectedMode;
		switch(info.mode) {
			case RelativeDateAndTime:
				info.relative.startOffset = self.relativeStart;
				info.relative.length = self.relativeLength;
				break;
			case FixedTime:
				info.fixedTime.startOffset = self.relativeStartDays;
				info.fixedTime.length = self.daysLength;
				info.fixedTime.startTime = self.fixedStartTime;
				info.fixedTime.endTime = self.fixedEndTime;
				break;
			case FixedDateAndTime:
				info.fixed.start = [self.fixedStartDate dateWithTimeIntoDayFromDate:self.fixedStartTime];
				info.fixed.end = [self.fixedEndDate dateWithTimeIntoDayFromDate:self.fixedEndTime];
				break;
		}
		delegate.customDateInfo = info;
	} else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
