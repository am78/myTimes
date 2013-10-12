//
//  Model.h
//  TaskTracker
//
//  Created by Michael Anteboth on 09.03.13.
//
//

#import <Foundation/Foundation.h>


@interface Model : NSObject

typedef NS_ENUM(NSInteger, DataFilterType) {
    FilterType_Processed = 0,
    FilterType_NotProcessed = 1,
    FilterType_Unfiltered = 2
};

@end
