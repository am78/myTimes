//
//  RootViewController.h
//  TaskTracker
//
//  Created by Michael Anteboth on 10.01.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>
#import "IAddItem.h"
#import "Project.h"
#import "TableRowSelectionDelegate.h"
#import "CalendarTableView.h"
#import "XMLHelper.h"
#import "CsvExportHelper.h"
#import "ExportSettingsViewController.h"
#import "SyncManager.h"
#import <InAppSettingsKit/IASKAppSettingsViewController.h>

@class TaskTrackerAppDelegate;

@interface RootViewController : UITableViewController <IAddItem, UIActionSheetDelegate, TableRowSelectionDelegate, CalendarTableViewDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, IASKSettingsDelegate>
{
	NSMutableArray* data;
	UIToolbar *toolbar;
	TaskTrackerAppDelegate* appDelegate;
	IBOutlet UIBarButtonItem* addButtonItem;
	IBOutlet UIBarButtonItem* editElementButtonItem;
	IBOutlet UIBarButtonItem* emailButtonItem;
	IBOutlet UIBarButtonItem* importButtonItem;	
	IBOutlet UIBarButtonItem* calButtonItem;
	IBOutlet UIBarButtonItem* helpButtonItem;	
	IBOutlet UIBarButtonItem* newWorkUnitButton;		
	int selectedRow;
	NSDate* calViewDay;
	BOOL firstViewLoad;
	NSArray* calEntriesForViewDay;
	UITextField* txtUrl;
	UINavigationController* navController;
}

@property (nonatomic,retain) IBOutlet UIBarButtonItem* importButtonItem;
@property (nonatomic,retain) IBOutlet UIBarButtonItem* editElementButtonItem;
@property (nonatomic,retain) IBOutlet UIBarButtonItem* addButtonItem;
@property (nonatomic,retain) IBOutlet UIBarButtonItem* emailButtonItem;
@property (nonatomic,retain) IBOutlet UIBarButtonItem* calButtonItem;
@property (nonatomic,retain) IBOutlet UIBarButtonItem* helpButtonItem;
@property (nonatomic,retain) IBOutlet UIBarButtonItem* nWorkUnitButton;
@property (nonatomic,retain) NSMutableArray *data;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *filterButton;
@property (retain, nonatomic) SyncManager* syncManager;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *settingsButtonItem;

- (void) initToolbar;
- (void) loadTimeEntryView;

- (IBAction)addItem:(id)sender;
- (IBAction)editItem:(id)sender;
- (IBAction)openCalendarView:(id)sender;
- (IBAction)emailButonPressed:(id)sender;
- (IBAction)importButtonPressed:(id)sender;
- (IBAction)filterButtonPressed:(id)sender;
- (IBAction)syncButtonPressed:(id)sender;
- (IBAction)settingsButtonPressed:(id)sender;
- (void) showErrorMessage:(NSString*)msg;

- (void) addNewWorkUnit:(id)sender;
- (void) addItem;
- (void) editSelectedItem;
- (void) editProject:(Project*)p editMode:(BOOL)editMode;
- (void) sendExportMail:(ExportSettingsViewController*) navCtl;

- (void) enabledGlobalButtons:(BOOL)enabled sender:(id) sender;

-(BOOL) isRowSelected:(int)row;
-(void) release;
-(void) showHelpView:(id)sender;

-(BOOL) isSameDay:(NSDate*) day0 anotherDate:(NSDate*)day1;

-(void) syncChanges:(NSData*) data;

-(NSDate*) getFirstDateInProjects:(NSArray*)projects;
-(NSArray*) markDataForExport:(NSArray*)data startDate:(NSDate*)start endDate:(NSDate*)end projectsToExport:(NSMutableArray*)projects;


@end
