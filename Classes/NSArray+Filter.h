//
//  NSArray+Filter.h
//  TaskTracker
//
//  Created by Michael Anteboth on 09.03.13.
//
//

#import <Foundation/Foundation.h>

@interface NSArray (Filter)

- (NSArray *)filteredArrayUsingBlock:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

@end
