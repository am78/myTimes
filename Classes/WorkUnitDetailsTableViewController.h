//
//  WorkUnitDetailsTableViewController.h
//  TaskTracker
//
//  Created by Michael Anteboth on 14.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimeWorkUnit.h"
#import "ProjectTask.h"
#import "Project.h"

@interface WorkUnitDetailsTableViewController : UITableViewController <UIActionSheetDelegate> {
	IBOutlet UIView* playPauseDeleteView;
	IBOutlet UIView* projectSubprojectView;
	IBOutlet UIView* startStopView;
	IBOutlet UIView* pauseView;
	IBOutlet UIView* remarkView;	
	
	IBOutlet UILabel* lblProjectName;
	IBOutlet UILabel* lblTaskName;
	IBOutlet UILabel* lblBegin;
	IBOutlet UILabel* lblEnd;
	IBOutlet UILabel* lblDuration;
	IBOutlet UILabel* lblPause;
	IBOutlet UITextView* txtRemark;
	IBOutlet UIButton* startStopButton;
	IBOutlet UIActivityIndicatorView* actIndicator;
	IBOutlet UIButton* deleteButton;	
	
	TimeWorkUnit* workUnit;
	TimeWorkUnit* wuCopy;
	BOOL workUnitAddMode;
	ProjectTask* parentTask;
	ProjectTask* parentTaskOrg;	
	Project* parentProject;	
	UITableView* parentTable;
	id parentController;
	
	BOOL taskChanged;
	int actionViewMode;
	BOOL dirty;
	NSString* pauseString;
	NSString* startString;	
	NSString* endString;
	NSString* durationString;
    BOOL processed;
}

@property BOOL taskChanged; 
@property (retain) IBOutlet UIView* playPauseDeleteView;
@property (retain) IBOutlet UIView* projectSubprojectView;
@property (retain) IBOutlet UIView* startStopView;
@property (retain) IBOutlet UIView* pauseView;
@property (retain) IBOutlet UIView* remarkView;

@property (retain) IBOutlet UILabel* lblProjectName;
@property (retain) IBOutlet UILabel* lblTaskName;
@property (retain) IBOutlet UILabel* lblBegin;
@property (retain) IBOutlet UILabel* lblEnd;
@property (retain) IBOutlet UILabel* lblDuration;
@property (retain) IBOutlet UILabel* lblPause;
@property (retain) IBOutlet UITextView* txtRemark;
@property (retain) IBOutlet UIButton* startStopButton;
@property (retain) IBOutlet UIActivityIndicatorView* actIndicator;
@property (retain) IBOutlet UIButton* deleteButton;	

@property  BOOL workUnitAddMode;
@property (retain) Project* parentProject;	
@property (retain) ProjectTask* parentTask;
@property (retain) TimeWorkUnit* workUnit;
@property (retain) UITableView* parentTable;
@property BOOL dirty;
@property (retain) NSString* pauseString;
@property (retain) NSString* startString;	
@property (retain) NSString* endString;
@property (retain) NSString* durationString;
@property (retain) id parentController;
@property (retain, nonatomic) UISwitch* processedSwitch;

-(void) updateDataFields;

-(void) deleteBtnPressed:(id) sender;
//-(void) saveBtnPressed:(id) sender;
-(void) startBtnPressed:(id) sender;
-(void) closeViewController;

@end
