#import <Cocoa/Cocoa.h>

enum DateRangeMode {
	RelativeDateAndTime = 0,
	FixedTime,
	FixedDateAndTime
};

struct DateInfo {
	enum DateRangeMode mode;
	union {
		struct RelativeDateAndTime {
			int startOffset; // in minutes
			unsigned length; // in minutes
		} relative;
		struct FixedTime {
			int startOffset; // in days from today
			unsigned length; // in full days
			NSDate *startTime;
			NSDate *endTime;
		} fixedTime;
		struct FixedDateAndTime {
			NSDate *start;
			NSDate *end;
		} fixed;
	};
};

@protocol CustomDateManagerDelegate <NSObject>

@property (nonatomic) struct DateInfo customDateInfo;

@end

@interface CustomDateManager : NSObject {
	IBOutlet NSPanel *chooserPanel;
	IBOutlet NSView *fixedHeader, *relativeHeader, *fixedDate,
		*relativeDate, *fixedTime, *relativeTime;
	IBOutlet NSView *containerView;
	IBOutlet id<CustomDateManagerDelegate> delegate;
	
	enum DateRangeMode selectedMode;
	NSDate *fixedStartDate, *fixedStartTime, *fixedEndDate, *fixedEndTime;
	int relativeStartDays, relativeStartHours, relativeStartMins;
	unsigned daysLength, hoursLength, minsLength;
	
	unsigned char preventDelegateNotifications;
}

@property (nonatomic, assign) id<CustomDateManagerDelegate> delegate;

@end
