#import <Cocoa/Cocoa.h>

typedef enum {
	Next12Hours = 0,
	Next24Hours,
	Today,
	Tomorrow,
	Custom
} DateType;

@interface MiniScheduleAppDelegate : NSObject <NSApplicationDelegate> {
  @private
	IBOutlet NSWindow *window, *dateWindow, *settingsWindow;
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSMenu *dateTypeMenu;
	NSStatusItem *status;
	DateType dateType;
	void *hotKey;
	NSDate *customDate;
	NSMutableArray *hiddenCalendars;
}

@property (nonatomic, retain) NSDate *customDate;
@property (nonatomic, readonly) NSArray *events, *calendars;

+ (MiniScheduleAppDelegate *)shared;
- (IBAction)takeDateTypeFrom:(NSMenuItem *)sender;
- (IBAction)openWindow:(id)sender;
- (IBAction)showSettings:(id)sender;
- (void)calendarsChanged:(id)sender;
- (void)eventsChanged:(id)sender;

@end
