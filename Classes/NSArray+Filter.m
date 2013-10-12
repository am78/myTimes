//
//  NSArray+Filter.m
//  TaskTracker
//
//  Created by Michael Anteboth on 09.03.13.
//
//

#import "NSArray+Filter.h"

@implementation NSArray (Filter)

- (NSArray *)filteredArrayUsingBlock:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate {
    NSIndexSet * filteredIndexes = [self indexesOfObjectsPassingTest:predicate];
    return [self objectsAtIndexes:filteredIndexes];
}

@end
