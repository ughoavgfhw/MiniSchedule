@interface NSDate (DayTimeAdditions)

- (NSDate *)dateWithTimeIntervalIntoDay:(NSTimeInterval)interval;
- (NSDate *)dateWithTimeIntoDayFromDate:(NSDate *)time;
- (NSTimeInterval)timeIntervalIntoDay;

@end
