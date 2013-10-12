//
//  TaskTrackerAppDelegate.h
//  TaskTracker
//
//  Created by Michael Anteboth on 10.01.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"
#import "Model.h"
#import "Project.h"
#import "ProjectTask.h"
#import "TimeWorkUnit.h"
#import "DataEntry.h"



@interface TaskTrackerAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UIActionSheetDelegate> {
    
	UIWindow *window;
	UINavigationController *navigationController;
	RootViewController* rootViewController;
	NSMutableArray* data;
	Project* editingProject;
	UITabBarController *tabBarController;
	UITableView* currentTableView;
	id addItemController;
	NSDateFormatter* dateFormatter;
	NSDateFormatter* timeFormatter;
	BOOL allowMultipleTasks;
	Project* projectToLoadAtStartup;
	ProjectTask* taskToLoadAtStartup;
	TimeWorkUnit* workUnitToLoadAtStartup;
	int minuteInterval;
	BOOL useDefaultTimes;
	NSDate* defaultStartTime;
	NSDate* defaultEndTime;	
	int defaultPauseValue;
	BOOL promptForCommentWhenStoppingTime;
	NSMutableDictionary* dataEntryDefinitions;
	NSMutableArray* dataToRestore;
	NSString* restoreFilePath;
    NSString* importFile;
}


- (void) toogleTableEditMode:(BOOL)editing;
- (void) addProject:(Project*)aProject;
- (void) addTask:(ProjectTask*)aTask;

-(NSString*) formatSeconds:(float)timeInSecs;
- (void) stopAllOtherWorkUnitsExcept:(TimeWorkUnit*)workUnit;
-(void) reselectActiveEntries;
-(void) importFromUrl:(NSString*)urlString addAsNewProjects:(BOOL)addProjects;
-(void) importFromString:(NSString*)sData   addAsNewProjects:(BOOL)addProjects;
-(void) importFromXMLData:(NSData*)xmlData addAsNewProjects:(BOOL)addProjects;
-(void) saveData;

- (NSString*) getDataFilePath;

- (NSMutableArray*) getDataFiltered:(DataFilterType) filterType;

//imports projects from the obtained NSData
- (void) importProjectFromData:(NSData*) importData;

@property (retain) NSDateFormatter* dateFormatter;
@property (retain) NSDateFormatter* timeFormatter;
@property (retain) Project* editingProject;
@property (retain) IBOutlet RootViewController* rootViewController;
@property (nonatomic, retain) NSMutableArray* data;
@property (nonatomic, retain) NSMutableDictionary* dataEntryDefinitions;
@property (retain) UITableView* currentTableView;
@property (retain) id addItemController;
@property (retain) Project* projectToLoadAtStartup;
@property (retain) ProjectTask* taskToLoadAtStartup;
@property (retain) TimeWorkUnit* workUnitToLoadAtStartup;
@property int minuteInterval;

@property BOOL allowMultipleTasks;
@property BOOL useDefaultTimes;
@property (retain) NSDate* defaultStartTime;
@property (retain) NSDate* defaultEndTime;
@property int defaultPauseValue;

@property BOOL promptForCommentWhenStoppingTime;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (retain) NSMutableArray* dataToRestore;
@property (retain) NSString* restoreFilePath;
@property (nonatomic, retain) NSString* importFile;
@property DataFilterType filterType;

@end

