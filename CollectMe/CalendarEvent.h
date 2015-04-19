@import UIKit;

@protocol CalendarEvent <NSObject>

@property (copy, nonatomic) NSString *title;
@property (assign, nonatomic) NSInteger day;
@property (assign, nonatomic) NSInteger startHour;
@property (assign, nonatomic) NSInteger durationInHours;

@end