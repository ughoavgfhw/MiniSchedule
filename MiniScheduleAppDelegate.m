#import "MiniScheduleAppDelegate.h"
#import <CalendarStore/CalendarStore.h>
#import <Carbon/Carbon.h>

#define DAY_SECONDS (24*60*60)

static MiniScheduleAppDelegate *shared;

@interface MiniScheduleAppDelegate ()

@property (nonatomic, retain) NSWindow *window, *dateWindow, *settingsWindow;
@property (nonatomic, retain) NSMenu *statusMenu;
@property (nonatomic) DateType dateType;
@property (nonatomic, retain) NSMutableArray *hiddenCalendars;

@end

OSStatus HotKeyEventHandlerProc(EventHandlerCallRef inCallRef, EventRef ev, void* inUserData) {
	if(GetEventKind(ev) != kEventHotKeyPressed) return eventNotHandledErr;
	if([shared.window isVisible]) [shared.window performClose:nil]; else
		[shared openWindow:nil];
	return noErr;
}

@interface NSDate (DayStartAddition)
- (NSDate *)dateWithTimeIntervalIntoDay:(NSTimeInterval)interval;
@end

@implementation MiniScheduleAppDelegate

@synthesize statusMenu, customDate, hiddenCalendars;

+ (NSSet *)keyPathsForValuesAffectingEvents {
	return [NSSet setWithObjects:@"customDate",@"calendars",@"hiddenCalendars",@"dateType",nil];
}

+ (MiniScheduleAppDelegate *)shared {
	if(shared) return [[shared retain] autorelease];
	return [[self alloc] init];
}

- (id)init {
	self = [super init];
	if(!shared) shared = self;
	return self;
}
- (void)dealloc {
	[window release];
	[dateWindow release];
	[settingsWindow release];
	[statusMenu release];
	[status release];
	[hiddenCalendars release];
	[customDate release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	const EventTypeSpec	hotKeyEvents[] = { { kEventClassKeyboard, kEventHotKeyPressed }, { kEventClassKeyboard, kEventHotKeyReleased }};
	InstallApplicationEventHandler(NewEventHandlerUPP(HotKeyEventHandlerProc), GetEventTypeCount(hotKeyEvents), hotKeyEvents, 0, NULL);
	EventHotKeyID theId = {'MSch','SWnd'};
	RegisterEventHotKey(1,controlKey,theId,GetApplicationEventTarget(),0,(EventHotKeyRef*)&hotKey);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
						  [[NSDate date] dateWithTimeIntervalIntoDay:0],@"CustomDate",
						  [NSNumber numberWithInt:Next12Hours],@"DateType",
						  [NSArray array],@"HiddenCalendars",
						  nil]];
	// Using instance variables directly to prevent having several change notifications
	[hiddenCalendars release];
	hiddenCalendars = [[defaults objectForKey:@"HiddenCalendars"] mutableCopy];
	[customDate release];
	customDate = [defaults objectForKey:@"CustomDate"];
	// But this accessor has important side effects, so just run it last
	self.dateType = [defaults integerForKey:@"DateType"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarsChanged:) name:CalCalendarsChangedExternallyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsChanged:) name:CalEventsChangedExternallyNotification object:nil];
	status = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[status setImage:[NSImage imageNamed:@"MiniSchedule24x22"]];
	[status setMenu:self.statusMenu];
	[status setHighlightMode:YES];
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:self.customDate forKey:@"CustomDate"];
	[defaults setInteger:self.dateType forKey:@"DateType"];
	[defaults setObject:self.hiddenCalendars forKey:@"HiddenCalendars"];
	[defaults synchronize];
	UnregisterEventHotKey(hotKey);
}

- (void)setDateType:(DateType)newType {
	[[dateTypeMenu itemWithTag:dateType] setState:0];
	[[dateTypeMenu itemWithTag:newType] setState:1];
	dateType = newType;
}
- (DateType)dateType {
	return dateType;
}
- (IBAction)takeDateTypeFrom:(NSMenuItem *)sender {
	self.dateType = [sender tag];
	if(self.dateType == Custom) {
		[self.dateWindow makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}
}

- (IBAction)openWindow:(id)sender {
	[self.window makeKeyAndOrderFront:sender];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)windowClosed:(id)sender {
	self.window = nil;
}
- (void)setWindow:(NSWindow *)newWindow {
	if(window != newWindow) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:window];
		[window release];
		window = [newWindow retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowClosed:) name:NSWindowWillCloseNotification object:window];
	}
}
- (NSWindow *)window {
	if(!window) {
		[NSBundle loadNibNamed:@"ScheduleWindow" owner:self];
	}
	return [[window retain] autorelease];
}

- (void)setDateWindow:(NSWindow *)w {
	if(dateWindow != w) {
		[dateWindow release];
		dateWindow = [w retain];
	}
}
- (NSWindow *)dateWindow {
	if(!dateWindow) {
		[NSBundle loadNibNamed:@"DateChooser" owner:self];
	}
	NSWindow *tmp = dateWindow;
	dateWindow = nil;
	return [tmp autorelease];
}

- (void)setSettingsWindow:(NSWindow *)w {
	if(settingsWindow != w) {
		[settingsWindow release];
		settingsWindow = [w retain];
	}
}
- (NSWindow *)settingsWindow {
	if(!settingsWindow) {
		[NSBundle loadNibNamed:@"Settings" owner:self];
	}
	NSWindow *tmp = settingsWindow;
	settingsWindow = nil;
	return [tmp autorelease];
}

- (IBAction)showSettings:(id)sender {
	[self.settingsWindow makeKeyAndOrderFront:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

- (NSArray *)calendars {
	return [[CalCalendarStore defaultCalendarStore] calendars];
}
- (void)calendarsChanged:(id)sender {
	[self willChangeValueForKey:@"calendars"];
	[self didChangeValueForKey:@"calendars"];
}
- (NSArray *)events {
	NSDate *start = [NSDate date], *end;
	DateType dt = self.dateType;
	NSTimeInterval endOffset = DAY_SECONDS;
	if(dt == Next12Hours) endOffset = DAY_SECONDS/2;
	else switch(dt) {
		case Today:
			start = [start dateWithTimeIntervalIntoDay:0];
			break;
		case Tomorrow:
			start = [start dateWithTimeIntervalIntoDay:DAY_SECONDS];
			break;
		case Custom:
			start = self.customDate;
			break;
		default: break;
	}
	end = [start dateByAddingTimeInterval:endOffset];
	CalCalendarStore *store = [CalCalendarStore defaultCalendarStore];
	NSMutableArray *cals = [[NSMutableArray alloc] init];
	for(CalCalendar *cal in self.calendars) {
		if(![self.hiddenCalendars containsObject:cal.title])
			[cals addObject:cal];
	}
	NSPredicate *eventPredicate = [CalCalendarStore eventPredicateWithStartDate:start endDate:end calendars:cals];
	[cals release];
	return [store eventsWithPredicate:eventPredicate];
}
- (void)eventsChanged:(id)sender {
	[self willChangeValueForKey:@"events"];
	[self didChangeValueForKey:@"events"];
}

- (NSUInteger)numberOfRowsInTableView:(NSTableView *)table {
	return [self.calendars count];
}
- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	if([[column identifier] intValue] == 0) {
		return [NSNumber numberWithBool:![self.hiddenCalendars containsObject:((CalCalendar*)[self.calendars objectAtIndex:row]).title]];
	} else return ((CalCalendar*)[self.calendars objectAtIndex:row]).title;
}
- (void)tableView:(NSTableView *)table setObjectValue:(id)val forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	if([[column identifier] intValue] == 0) {
		if([val boolValue]) [self.hiddenCalendars removeObject:((CalCalendar*)[self.calendars objectAtIndex:row]).title];
		else [self.hiddenCalendars addObject:((CalCalendar*)[self.calendars objectAtIndex:row]).title];
		[self eventsChanged:nil];
	}
}

@end

@implementation NSDate (DayStartAddition)

- (NSDate *)dateWithTimeIntervalIntoDay:(NSTimeInterval)interval {
	NSInteger tzOffset = [[NSTimeZone systemTimeZone] secondsFromGMT];
	UInt64 date = (UInt64)[self timeIntervalSince1970];
	date -= (date + tzOffset) % DAY_SECONDS;
	return [NSDate dateWithTimeIntervalSince1970:date + interval];
}

@end
