//
//  Project.h
//  Test2
//
//  Created by Michael Anteboth on 08.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Model.h"

@interface Project : NSObject <NSCoding>
{
	//the project name
	NSString* name;
	
	//the tasks(sub projects) of this project 
	NSMutableArray* tasks;
	
	//the project descroption
	NSString* description;
	
	//is the project marked for export
	BOOL markedForExport;
	
	//is the value changeable by the user
	BOOL userChangeable;
}

- (void) dealloc;

-(Project*) init;
-(NSNumber*) totalAmmount;
-(NSNumber*) totalAmmountMarkedForExport;
-(NSString*) summary;
-(NSString*) formatSeconds:(float)timeInSecs;
-(BOOL) hasRunningWorkUnits;
-(BOOL) matchFilter:(DataFilterType)filter;

@property (retain) NSString* name;
@property (retain) NSMutableArray* tasks;
@property (retain) NSString* description;
@property 	BOOL markedForExport;
@property BOOL userChangeable;

@end
