#import "MiniScheduleAppDelegate.h"
#import <CalendarStore/CalendarStore.h>
#import <Carbon/Carbon.h>

#define DAY_SECONDS (24*60*60)
#define KEY_EQUIVALENT_KEY @"NSUserKeyEquivalents"
#define KEY_EQUIVALENT_IDENTIFIER @"Open Schedule Window"
#define SHOW_WINDOW_MENU_TAG 1000

// Map for unicode characters from f700-f8ff (only through f747 are defined)
// See NSEvent.h for a list of these codes (the first is NSUpArrowFunctionKey)
const UInt8 unicodeF7XXMap[] = {kVK_UpArrow,kVK_DownArrow,kVK_LeftArrow,
	kVK_RightArrow,kVK_F1,kVK_F2,kVK_F3,kVK_F4,kVK_F5,kVK_F6,kVK_F7,
	kVK_F8,kVK_F9,kVK_F10,kVK_F11,kVK_F12,kVK_F13,kVK_F14,kVK_F15,
	kVK_F16,kVK_F17,kVK_F18,kVK_F19,kVK_F20,/*F21*/0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff/*F35*/,
	0xff/*insert*/,kVK_ForwardDelete,kVK_Home,0xff/*begin*/,kVK_End,
	kVK_PageUp,kVK_PageDown,0xff/*print screen*/,0xff/*scroll lock*/,
	0xff/*pause*/,0xff/*sysreq*/,0xff/*break*/,0xff/*reset*/,0xff/*stop*/,
	0xff/*menu*/,0xff/*user*/,0xff/*system*/,0xff/*print*/,0xff/*clear line*/,
	0xff/*clear display*/,0xff/*insert line*/,0xff/*delete line*/,
	0xff/*insert char*/,0xff/*delete char*/,0xff/*prev*/,0xff/*next*/,
	0xff/*select*/,0xff/*execute*/,0xff/*undo*/,0xff/*redo*/,0xff/*find*/,
	kVK_Help,0xff/*mode switch*/};

struct CharMap_Table {
	char start; // inclusive
	char end; // inclusive
	UInt8 mapOffset;
} __attribute__((__packed__));
struct CharMap {
	UInt8 letters[26];
	UInt8 numbers[10];
	// Currently no keypad support
	UInt8 tableCount;
	UInt8 mapCount;
	struct CharMap_Table table[0];
	UInt8 map[0];
} __attribute__((__packed__));

static MiniScheduleAppDelegate *shared;

@interface MiniScheduleAppDelegate ()

@property (nonatomic, retain) NSWindow *window, *dateWindow, *settingsWindow;
@property (nonatomic, retain) NSMenu *statusMenu;
@property (nonatomic) DateType dateType;
@property (nonatomic, retain) NSMutableArray *hiddenCalendars;

+ (BOOL)rebuildCharmap;
+ (UInt8)keycodeForCharacter:(unichar)character;
- (void)reloadHotkey;

@end

OSStatus HotKeyEventHandlerProc(EventHandlerCallRef inCallRef, EventRef ev, void* inUserData) {
	if(GetEventKind(ev) != kEventHotKeyPressed) return eventNotHandledErr;
	if([shared.window isVisible]) [shared.window performClose:nil]; else
		[shared openWindow:nil];
	return noErr;
}

void InputSourceChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[(id)observer rebuildCharmap];
	[shared reloadHotkey];
}

@interface NSDate (DayStartAddition)
- (NSDate *)dateWithTimeIntervalIntoDay:(NSTimeInterval)interval;
@end

@implementation MiniScheduleAppDelegate

+ (void)initialize {
	static BOOL done = NO;
	if(!done) {
		done = YES;
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), self, InputSourceChanged, kTISNotifySelectedKeyboardInputSourceChanged, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}

+ (BOOL)_handleCharmapCommand:(SEL)command withArgument:(void *)arg returnPtr:(void *)returnPtr {
	static struct CharMap *_charMap = NULL;
	static struct CharMap_Table *_table = NULL;
	static UInt8 *_map = NULL;
	struct CharMap *charMap;
	struct CharMap_Table *table;
	UInt8 *map;
	@synchronized(self) {
		if(!_charMap || command == @selector(rebuildCharmap)) {
			if(_charMap) {
				free(_charMap);
				_charMap = NULL;
			}
			TISInputSourceRef inputSource = TISCopyCurrentKeyboardLayoutInputSource();
			NSString *sourceID = (NSString*)TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID);
			CFRelease(inputSource);
			NSString *path = [[NSBundle mainBundle] pathForResource:sourceID ofType:@"charmap"];
			NSData *data = [NSData dataWithContentsOfFile:path];
			NSUInteger len = [data length];
			if(len < sizeof(struct CharMap)) return NO;
			_charMap = malloc([data length]);
			if(!_charMap) return NO;
			[data getBytes:_charMap length:len];
			if(len != (sizeof(struct CharMap) + sizeof(struct CharMap_Table)*_charMap->tableCount + sizeof(UInt8)*_charMap->mapCount)) {
				free(_charMap);
				_charMap = NULL;
				return NO;
			}
			_table = (struct CharMap_Table*)&_charMap->table;
			_map = (UInt8*)&_table[_charMap->tableCount];
		}
		charMap = _charMap;
		table = _table;
		map = _map;
	}
	
	if(command == @selector(rebuildCharmap)) return YES;
	if(command == @selector(keycodeForCharacter:)) {
		unichar charcode = *(unichar*)arg;
		if(!(charcode >> 8)) {
			if(charcode >= 'a' && charcode <= 'z') {
				*(UInt8*)returnPtr = charMap->letters[charcode - 'a'];
				return YES;
			} else if(charcode >= '0' && charcode <= '9') {
				*(UInt8*)returnPtr = charMap->numbers[charcode - '0'];
			} else {
				for(UInt8 i = 0; i < charMap->tableCount; ++i) {
					if(charcode >= table[i].start && charcode <= table[i].end && (charcode - table[i].start + table[i].mapOffset) < charMap->mapCount) {
						*(UInt8*)returnPtr = map[charcode - table[i].start + table[i].mapOffset];
						return YES;
					}
				}
			}
		} else if((charcode >> 8) == 0xf7) {
			charcode &= 0xff;
			if(charcode < sizeof(unicodeF7XXMap)/sizeof(*unicodeF7XXMap)) {
				*(UInt8*)returnPtr = unicodeF7XXMap[charcode];
				return YES;
			}
		}
		BOOL retval = YES;
		*(UInt8*)returnPtr = ({UInt8 __tmp; switch(charcode) {
			case 0x21a9:
			case 0x23ce:
			case   '\n': __tmp = kVK_Return; break;
			case 0x21e5:
			case   '\t': __tmp = kVK_Tab; break;
			case    ' ': __tmp = kVK_Space; break;
			case   0x7f:
			case 0x232b:
			case   '\b': __tmp = kVK_Delete; break;
			case 0x238b:
			case   '\e': __tmp = kVK_Escape; break;
			case 0x2423: __tmp = kVK_Space; break;
			case 0x2326: __tmp = kVK_ForwardDelete; break;
			case 0x20dd: __tmp = kVK_Help; break;
			case 0x2196:
			case 0x21b8:
			case 0x21f1: __tmp = kVK_Home; break;
			case 0x2198:
			case 0x21f2: __tmp = kVK_End; break;
			case 0x21de: __tmp = kVK_PageUp; break;
			case 0x21df: __tmp = kVK_PageDown; break;
			case 0x2191:
			case 0x21e1: __tmp = kVK_UpArrow; break;
			case 0x2193:
			case 0x21e3: __tmp = kVK_DownArrow; break;
			case 0x2190:
			case 0x21e0: __tmp = kVK_LeftArrow; break;
			case 0x2192:
			case 0x21e2: __tmp = kVK_RightArrow; break;
			// These shouldn't be here, but the charmap format only uses 8-bit characters.
			case 0x2324:
			case 0x21b5: __tmp = kVK_ANSI_KeypadEnter; break;
			case 0x2327: __tmp = kVK_ANSI_KeypadClear; break;
			default: __tmp = 0xff; retval = NO;
		} __tmp; });
		return retval;
	}
	
	return NO;
}

+ (BOOL)rebuildCharmap {
	return [self _handleCharmapCommand:_cmd withArgument:NULL returnPtr:NULL];
}

+ (UInt8)keycodeForCharacter:(unichar)character {
	UInt8 result;
	if(![self _handleCharmapCommand:_cmd withArgument:&character returnPtr:&result])
		result = 0xff;
	return result;
}

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

- (BOOL)registerHotkeyWithString:(NSString *)str {
	if(hotKey) {
		UnregisterEventHotKey(hotKey);
		hotKey = nil;
		[[statusMenu itemWithTag:SHOW_WINDOW_MENU_TAG] setKeyEquivalent:@""];
	}
	NSUInteger len = [str length];
	if(!len) return YES;
	UInt32 flags = 0;
	NSUInteger nsFlags = 0;
	unichar charCode = 0;
	for(NSUInteger i = 0; i < len; ++i) {
		unichar c = [str characterAtIndex:i];
		switch(c) {
			case '^':
				nsFlags |= NSControlKeyMask;
				flags |= controlKey;
				break;
			case '@':
				nsFlags |= NSCommandKeyMask;
				flags |= cmdKey;
				break;
			case '~':
				nsFlags |= NSAlternateKeyMask;
				flags |= optionKey;
				break;
			case '$':
				nsFlags |= NSShiftKeyMask;
				flags |= shiftKey;
				break;
			default:
				if(charCode != 0) {
					charCode = 0;
					break;
				}
				charCode = c;
		}
	}
	if(charCode) {
		EventHotKeyID theId = {'MSch','SWnd'};
		UInt32 keyCode = [MiniScheduleAppDelegate keycodeForCharacter:charCode];
		if(keyCode == 0xff) {
			NSLog(@"could not map character '%C' (0x%x) to a keycode",charCode,charCode);
		} else {
			RegisterEventHotKey(keyCode, flags, theId, GetApplicationEventTarget(), 0, (EventHotKeyRef*)&hotKey);
			if(hotKey != NULL) {
				// Attempt to change the menu's equivalent, even though it will be overridden by the system if this came from the preferences
				NSMenuItem *menuItem = [statusMenu itemWithTag:SHOW_WINDOW_MENU_TAG];
				[menuItem setKeyEquivalent:[NSString stringWithCharacters:&charCode length:1]];
				[menuItem setKeyEquivalentModifierMask:nsFlags];
				return YES;
			}
		}
	}
	return NO;
}

- (void)reloadHotkey {
	NSDictionary *keyEquivs = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_EQUIVALENT_KEY];
	BOOL hotkeyOK = NO;
	if([keyEquivs objectForKey:KEY_EQUIVALENT_IDENTIFIER])
		hotkeyOK = [self registerHotkeyWithString:[keyEquivs objectForKey:KEY_EQUIVALENT_IDENTIFIER]];
	if(!hotkeyOK) [self registerHotkeyWithString:@"^s"];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	const EventTypeSpec	hotKeyEvents[] = { { kEventClassKeyboard, kEventHotKeyPressed }, { kEventClassKeyboard, kEventHotKeyReleased }};
	InstallApplicationEventHandler(NewEventHandlerUPP(HotKeyEventHandlerProc), GetEventTypeCount(hotKeyEvents), hotKeyEvents, 0, NULL);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
						  [[NSDate date] dateWithTimeIntervalIntoDay:0],@"CustomDate",
						  [NSNumber numberWithInt:Next12Hours],@"DateType",
						  [NSArray array],@"HiddenCalendars",
						  nil]];
	[self reloadHotkey];
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
