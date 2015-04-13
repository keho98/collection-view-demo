//
//  WeekCalendarLayout.m
//  CollectMe
//
//  Created by Kevin Ho on 4/8/15.
//  Copyright (c) 2015 Keiho. All rights reserved.
//  Basically a copy of objc.io collection view article
//

#import "WeekCalendarLayout.h"

static const NSUInteger DaysPerWeek = 7;
static const NSUInteger HoursPerDay = 24;
static const CGFloat HorizontalSpacing = 10;
static const CGFloat HeightPerHour = 50;
static const CGFloat DayHeaderHeight = 40;
static const CGFloat HourHeaderWidth = 100;

@implementation WeekCalendarLayout

#pragma mark - UICollectionViewLayout Implementation

// Start by specifiying the content size for the collection view
- (CGSize)collectionViewContentSize
{
    
    // Disable horizontal scroll for now
    CGFloat contentWidth = self.collectionView.bounds.size.width;
    
    // Allow vertical scroll to show full day
    CGFloat contentHeight = DayHeaderHeight + (HoursPerDay * HeightPerHour);
    
    CGSize contentSize = CGSizeMake(contentWidth, contentHeight);
    return contentSize;
}

/* Collection view calls this method as passes in a rectangle in its own
  coordinate system, typically the visible rectangle in the view (its bounds).
  Expects an array of UICollectionViewLayoutAttributes, one for each cell or other view
  visible. Properties include frame,center,size,transform3D, alpha, and hidden; others
  require a subclass of UICollectionViewLayoutAttributes. Each object corresponds
  to a cell or other view through an indexPath. Collection view will instantiate the 
  view given the respective attributes.
*/
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *layoutAttributes = [NSMutableArray array];
    
    // Cells
    // We call a custom helper method -indexPathsOfItemsInRect: here
    // which computes the index paths of the cells that should be included
    // in rect.
    NSArray *visibleIndexPaths = [self indexPathsOfItemsInRect:rect];
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        UICollectionViewLayoutAttributes *attributes =
        [self layoutAttributesForItemAtIndexPath:indexPath];
        [layoutAttributes addObject:attributes];
    }
    
    // Supplementary views
    NSArray *dayHeaderViewIndexPaths =
    [self indexPathsOfDayHeaderViewsInRect:rect];
    for (NSIndexPath *indexPath in dayHeaderViewIndexPaths) {
        UICollectionViewLayoutAttributes *attributes =
        [self layoutAttributesForSupplementaryViewOfKind:@"DayHeaderView"
                                             atIndexPath:indexPath];
        [layoutAttributes addObject:attributes];
    }

    NSArray *hourHeaderViewIndexPaths =
    [self indexPathsOfHourHeaderViewsInRect:rect];
    for (NSIndexPath *indexPath in hourHeaderViewIndexPaths) {
        UICollectionViewLayoutAttributes *attributes =
        [self layoutAttributesForSupplementaryViewOfKind:@"HourHeaderView"
                                             atIndexPath:indexPath];
        [layoutAttributes addObject:attributes];
    }
    
    return layoutAttributes;
}

#pragma mark - Helpers

- (NSArray *)indexPathsOfItemsInRect:(CGRect)rect
{
    NSInteger minVisibleDay = [self dayIndexFromXCoordinate:CGRectGetMinX(rect)];
    NSInteger maxVisibleDay = [self dayIndexFromXCoordinate:CGRectGetMaxX(rect)];
    NSInteger minVisibleHour = [self hourIndexFromYCoordinate:CGRectGetMinY(rect)];
    NSInteger maxVisibleHour = [self hourIndexFromYCoordinate:CGRectGetMaxY(rect)];
    
    //    NSLog(@"rect: %@, days: %d-%d, hours: %d-%d", NSStringFromCGRect(rect), minVisibleDay, maxVisibleDay, minVisibleHour, maxVisibleHour);
    
    CalendarDataSource *dataSource = self.collectionView.dataSource;
    NSArray *indexPaths = [dataSource indexPathsOfEventsBetweenMinDayIndex:minVisibleDay maxDayIndex:maxVisibleDay minStartHour:minVisibleHour maxStartHour:maxVisibleHour];
    return indexPaths;
}

- (NSInteger)dayIndexFromXCoordinate:(CGFloat)xPosition
{
    CGFloat contentWidth = [self collectionViewContentSize].width - HourHeaderWidth;
    CGFloat widthPerDay = contentWidth / DaysPerWeek;
    NSInteger dayIndex = MAX((NSInteger)0, (NSInteger)((xPosition - HourHeaderWidth) / widthPerDay));
    return dayIndex;
}

- (NSInteger)hourIndexFromYCoordinate:(CGFloat)yPosition
{
    NSInteger hourIndex = MAX((NSInteger)0, (NSInteger)((yPosition - DayHeaderHeight) / HeightPerHour));
    return hourIndex;
}

- (NSArray *)indexPathsOfDayHeaderViewsInRect:(CGRect)rect
{
    if (CGRectGetMinY(rect) > DayHeaderHeight) {
        return [NSArray array];
    }
    
    NSInteger minDayIndex = [self dayIndexFromXCoordinate:CGRectGetMinX(rect)];
    NSInteger maxDayIndex = [self dayIndexFromXCoordinate:CGRectGetMaxX(rect)];
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger idx = minDayIndex; idx <= maxDayIndex; idx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

- (NSArray *)indexPathsOfHourHeaderViewsInRect:(CGRect)rect
{
    if (CGRectGetMinX(rect) > HourHeaderWidth) {
        return [NSArray array];
    }
    
    NSInteger minHourIndex = [self hourIndexFromYCoordinate:CGRectGetMinY(rect)];
    NSInteger maxHourIndex = [self hourIndexFromYCoordinate:CGRectGetMaxY(rect)];
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger idx = minHourIndex; idx <= maxHourIndex; idx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

- (CGRect)frameForEvent:(id<CalendarEvent>)event
{
    CGFloat totalWidth = [self collectionViewContentSize].width - HourHeaderWidth;
    CGFloat widthPerDay = totalWidth / DaysPerWeek;
    
    CGRect frame = CGRectZero;
    frame.origin.x = HourHeaderWidth + widthPerDay * event.day;
    frame.origin.y = DayHeaderHeight + HeightPerHour * event.startHour;
    frame.size.width = widthPerDay;
    frame.size.height = event.durationInHours * HeightPerHour;
    
    frame = CGRectInset(frame, HorizontalSpacing/2.0, 0);
    return frame;
}

@end
