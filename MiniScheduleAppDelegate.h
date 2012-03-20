#import <Cocoa/Cocoa.h>
#import "CustomDateManager.h"

typedef enum {
	Next12Hours = 0,
	Next24Hours,
	Today,
	Tomorrow,
	Custom
} DateType;

@interface MiniScheduleAppDelegate : NSObject <NSApplicationDelegate, CustomDateManagerDelegate> {
  @private
	IBOutlet NSWindow *window, *dateWindow, *settingsWindow;
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSMenu *dateTypeMenu;
	IBOutlet id dateManager;
	NSStatusItem *status;
	DateType dateType;
	void *hotKey;
	struct DateInfo customDateInfo;
	NSMutableArray *hiddenCalendars;
}

@property (nonatomic, readonly) NSArray *events, *calendars;

+ (MiniScheduleAppDelegate *)shared;
- (IBAction)takeDateTypeFrom:(NSMenuItem *)sender;
- (IBAction)openWindow:(id)sender;
- (IBAction)showSettings:(id)sender;
- (void)calendarsChanged:(id)sender;
- (void)eventsChanged:(id)sender;

@end
