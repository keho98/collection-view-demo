//
//  WeekCalendarLayout.m
//  CollectMe
//
//  Created by Kevin Ho on 4/8/15.
//  Copyright (c) 2015 Keiho. All rights reserved.
//  Basically a copy of objc.io collection view article
//

#import "CalendarDataSource.h"
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

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
    
    CGFloat totalWidth = [self collectionViewContentSize].width;
    if ([kind isEqualToString:@"DayHeaderView"]) {
        CGFloat availableWidth = totalWidth - HourHeaderWidth;
        CGFloat widthPerDay = availableWidth / DaysPerWeek;
        attributes.frame = CGRectMake(HourHeaderWidth + (widthPerDay * indexPath.item), 0, widthPerDay, DayHeaderHeight);
        attributes.zIndex = -10;
    } else if ([kind isEqualToString:@"HourHeaderView"]) {
        attributes.frame = CGRectMake(0, DayHeaderHeight + HeightPerHour * indexPath.item, totalWidth, HeightPerHour);
        attributes.zIndex = -10;
    }
    return attributes;
}

/* 
 *   Only invalidate layout if bounds change, important as
 *   bounds could change many times per second, such as when
 *   scrolling.
 */

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGRect oldBounds = self.collectionView.bounds;
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    return NO;
}

/* 
 * Provides layout attributes for a single index path, should at least
 * change the frame attribute to ensure cells don't stack. Note that
 * frame must be changed, auto layout will not work for cells, even
 * if auto layout was used for the collection view.
 */

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:
(NSIndexPath *)indexPath
{
    CalendarDataSource *dataSource = self.collectionView.dataSource;
    id<CalendarEvent> event = [dataSource eventAtIndexPath:indexPath];
    UICollectionViewLayoutAttributes *attributes =
    [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.frame = [self frameForEvent:event];
    attributes.alpha = 0.8;
    
    return attributes;
}

/* Animation
 * Use initialLayout... methods for inserting animation and 
 * finalLayout... methods for deletion.
 */

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:itemIndexPath];
    
    attributes.alpha = 0.0;
    
    return attributes;
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
