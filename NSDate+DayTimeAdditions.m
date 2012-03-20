#import "NSDate+DayTimeAdditions.h"

#define DAY_SECONDS (24*60*60)

@implementation NSDate (DayTimeAdditions)

- (NSDate *)dateWithTimeIntervalIntoDay:(NSTimeInterval)interval {
	NSInteger tzOffset = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:self];
	UInt64 date = (UInt64)[self timeIntervalSince1970];
	date -= (date + tzOffset) % DAY_SECONDS;
	return [NSDate dateWithTimeIntervalSince1970:date + interval];
}

- (NSDate *)dateWithTimeIntoDayFromDate:(NSDate *)time {
	return [self dateWithTimeIntervalIntoDay:[time timeIntervalIntoDay]];
}

- (NSTimeInterval)timeIntervalIntoDay {
	NSInteger tzOffset = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:self];
	UInt64 time = (UInt64)[self timeIntervalSince1970];
	return (time + tzOffset) % DAY_SECONDS;
}

@end
