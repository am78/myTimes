//
//  WorkUnitDetailsTableViewController.m
//  TaskTracker
//
//  Created by Michael Anteboth on 14.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WorkUnitDetailsTableViewController.h"
#import "WorkUnitDetailsCellView.h"
#import "TaskTrackerAppDelegate.h"
#import "PauseEditViewController.h"
#import "BeginEndEditViewController.h"
#import "TextEditViewController.h"
#import "ProjectTaskEditViewController.h"
#import "TimeUtils.h"
#import "WorkUnitsListViewController.h"

@implementation WorkUnitDetailsTableViewController

@synthesize playPauseDeleteView;
@synthesize projectSubprojectView;
@synthesize pauseView;
@synthesize startStopView;
@synthesize remarkView;

@synthesize lblProjectName;
@synthesize lblTaskName;
@synthesize lblBegin;
@synthesize lblEnd;
@synthesize lblDuration;
@synthesize lblPause;
@synthesize txtRemark;
@synthesize startStopButton;
@synthesize actIndicator;
@synthesize deleteButton;

@synthesize workUnit;
@synthesize parentTask;
@synthesize parentProject;
@synthesize parentTable;
@synthesize workUnitAddMode;
@synthesize taskChanged;
@synthesize dirty;
@synthesize pauseString;
@synthesize startString;
@synthesize endString;
@synthesize durationString;
@synthesize parentController;
@synthesize processedSwitch;


#define COLIDX_PROJECT 0
#define COLIDX_START 1
#define COLIDX_PAUSE 2
#define COLIDX_REMARK 3
//#define COLIDX_PROCESSED 4
#define COLIDX_DEL 4
 
/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

#pragma mark WorkUnit specific code

//delete current work unit
-(void) deleteBtnPressed:(id) sender {
	NSLog(@"delete work unit entry");
	//delete the work unit and close the view, refersh paren tables view
	//let the user confirm the delete operation
	
	//remember the actionViewMode for the callback function
	actionViewMode = 2;
	
	//ask the user to export the selected project or all projects
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"workunitDeletion.title", @"")
													  delegate:self
											 cancelButtonTitle:NSLocalizedString(@"workunitDeletion.cancel", @"")
										destructiveButtonTitle:NSLocalizedString(@"workunitDeletion.confirm", @"")
											 otherButtonTitles:nil];	
    [menu showInView:self.view];        
    [menu release];
}

//delete confirm dialog closed
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionViewMode == 1) { //if the user has beend asked if he really wants to discard his changes
		actionViewMode = 0; //reset mode
		if (buttonIndex == 0) {
			//close the view
            [self closeViewController];
		} else {
			return; //do nothing on cancel
		}
	} else if (actionViewMode == 2) { //if delete button was pressed and the user asked if he really wants to delete the entry
		actionViewMode = 0; //reset mode
		//delete was selected
		if (buttonIndex == 0 ) {
			// Delete the row from the data source
			[self.parentTask.workUnits removeObject:workUnit];
			//refresh table
			[self.parentTable reloadData];
			//globale buttons de-/aktivieren

          //leave the view
          [self closeViewController];
            
		} else {
			//cancel choosen, do nothing
			return;
		}
	}
}

//save work unit, close view, refresh parent table
-(void) saveWorkUnit:(id) sender {
	//show error message and break if task and/or project is nil
	if (self.parentProject == nil || self.parentTask == nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error.title", @"") 
														message:NSLocalizedString(@"error.msg.projectAndSubprojectAreNessecary", @"")
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"error.close.button.text", @"") 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	
    //put values from working copy to real work unit element
    workUnit.date = wuCopy.date;
    workUnit.pause = wuCopy.pause;
    workUnit.description = wuCopy.description;
    workUnit.duration = wuCopy.duration;
    workUnit.running = wuCopy.running;
    workUnit.processed = self.processedSwitch.on;
	
	//if parent task changed remove workunit from the old task and add it to the new one
	if (self.taskChanged && !workUnitAddMode) {
		//remove from old task
		[parentTaskOrg.workUnits removeObject:self.workUnit];
		//add to new task
		[[self.parentTask workUnits] addObject:self.workUnit];
	}
	
	//add work unit to task if we are in addMode
	if (workUnitAddMode) {
		[[self.parentTask workUnits] addObject:self.workUnit];
	}
	
	//reload parent table view
	if ([self.parentController isKindOfClass:WorkUnitsListViewController.class]) {
		WorkUnitsListViewController* c = (WorkUnitsListViewController*) self.parentController;
		[c reload];
	}
    else {
        [self.parentTable reloadData];
    }

	
	//leave the vieew
    [self closeViewController];
	
	//enabble the common add button in the lower left after leaving the edit view
	TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[appDelegate saveData];
	
}

//start/Stop work unit
-(void) startBtnPressed:(id) sender {
	NSLog(@"work unit started/stopped");
	if (wuCopy.running) [wuCopy stopTimeTracking];
	else [wuCopy startTimeTracking];
	[self updateDataFields];
	//TODO start workunit or stop it if its running
	
}


//refresh labels
-(void) updateDataFields {
	[self.tableView reloadData];
	
	TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];

	//start time
	//TODO Wochentag (Abkürzung) mit ausgeben
	self.startString = [TimeUtils formatDateAndTime:wuCopy.date withFormatType:2];
	
	//end time
	NSDate* end = [wuCopy getEndDate];

	//TODO: only print date if differtent from start date
	self.endString = [TimeUtils formatDateAndTime:end withFormatType:2];
	
	//duration
	self.durationString = [appDelegate formatSeconds:[wuCopy.duration intValue]];
	
	//Pause
	self.pauseString = [appDelegate formatSeconds:[wuCopy.pause intValue]];
	
	//update start stop button and activity indicator
	if (wuCopy.running) {
		[self.startStopButton setBackgroundImage:[UIImage imageNamed:@"pause-btn.png"] forState:UIControlStateNormal];
		[self.actIndicator startAnimating];
	} else {
		[self.startStopButton setBackgroundImage:[UIImage imageNamed:@"play-btn.png"] forState:UIControlStateNormal];
		[self.actIndicator stopAnimating];
	}
    
    processed = wuCopy.processed;
}

-(void) cancelEditingAndCloseView:(id)sender {
	if (dirty) { //nur bei Änderungen nachfragen
		actionViewMode = 1; //actionView delegate is used severalt times, so set the type of this action view
		//ask the user to proceed and discard changes
		NSString* msg = NSLocalizedString(@"workUnitEditView.confirmCancelEditing.message", @"");
		//ask the user to export the selected project or all projects
		UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:msg
														  delegate:self
												 cancelButtonTitle:NSLocalizedString(@"workUnitEditView.confirmCancelEditing.cancel", @"")
											destructiveButtonTitle:NSLocalizedString(@"workUnitEditView.confirmCancelEditing.proceed", @"")
												 otherButtonTitles:nil];
	
		[menu showInView:self.view];        
		[menu release];
	} else {
        [self closeViewController];
	}
}

- (void) closeViewController
{
//	[self.navigationController popViewControllerAnimated:TRUE];
    [self.navigationController dismissViewControllerAnimated:true completion:nil];
}

#pragma mark UIViewDelegate methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
    
	actionViewMode = 0;
	dirty = FALSE;
	self.taskChanged = FALSE;
	//create the working copy
	wuCopy = [workUnit copy];
	
	//create the save button
	UIBarButtonItem *saveButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																				 target:self action:@selector(saveWorkUnit:)] autorelease];
	//and add it to the navigation bar
	self.navigationItem.rightBarButtonItem = saveButton;
	
	//create the cancel button
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																				 target:self action:@selector(cancelEditingAndCloseView:)] autorelease];
	//and add it to the navigation bar
	self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.navigationController.navigationBarHidden = FALSE;
	
	
	//disable the common add button in the lower left while editing
	TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
	//globale buttons de-/aktivieren
	[appDelegate.rootViewController enabledGlobalButtons:FALSE sender:self];	
	
	self.tableView.sectionFooterHeight = 0;
	self.tableView.sectionHeaderHeight = 5;
	//self.tableView.bounces = false;
	[[NSBundle bundleForClass:[self class]] loadNibNamed:@"PlayPauseDeleteView" owner:self options:nil];

	//set background for delete button
	//int state =  UIControlStateNormal || UIControlStateSelected || UIControlStateDisabled || UIControlStateHighlighted;
//	int state =  UIControlStateNormal;
//	UIImage* img = [[UIImage imageNamed:@"red-button-background.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0];
//	[self.deleteButton setBackgroundImage:img forState:state];
    
	
	parentTaskOrg = self.parentTask;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self updateDataFields];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];	
}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	//disable the common add button in the lower left while editing
	TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
	//globale buttons de-/aktivieren
	[appDelegate.rootViewController enabledGlobalButtons:TRUE sender:self];	
	
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == COLIDX_PROJECT)	return 2; 
	if (section == COLIDX_START)	return 3;
//    if (section == 4) return 1;
	return 1;
}

//customize the row height for each cell
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == COLIDX_PROJECT)        return 38;
	else if (indexPath.section == COLIDX_START)		return 38;
	else if (indexPath.section == COLIDX_REMARK)	return 70;
//	else if (indexPath.section == COLIDX_DEL)		return 70;
	else if (indexPath.section == COLIDX_PAUSE)		return 38;
//	else if (indexPath.section == COLIDX_PROCESSED)	return 38;
	else return 70;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* acell = nil;
//	if (indexPath.section == COLIDX_DEL) {
//		//PlaPauseDelete CellView
//		static NSString *CellIdentifier = @"DeleteCell";		 
//		WorkUnitDetailsCellView *cell = (WorkUnitDetailsCellView*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//		if (cell == nil) {
//            cell = [[[WorkUnitDetailsCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
//			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
//		}
//		[cell addSubview:self.playPauseDeleteView];
//		acell = cell;
//	} else
    if (indexPath.section == COLIDX_PROJECT && indexPath.row == 0) {
		static NSString *CellIdentifier = @"ProjectCell";	
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		NSString* txt = self.parentProject.name;
		if (txt == nil) {
			txt = @"";
		}
		cell.textLabel.text = NSLocalizedString(@"label.project", @"");
		cell.detailTextLabel.text = txt;
		acell = cell;
	} else if (indexPath.section == COLIDX_PROJECT && indexPath.row == 1) {
		static NSString *CellIdentifier = @"SubprojectCell";	
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		
		NSString* txt = self.parentTask.name;
		if (txt == nil) {
			txt = @"";
		}
		cell.textLabel.text =  NSLocalizedString(@"label.subproject", @"");
		cell.detailTextLabel.text = txt;
		acell = cell;
	} else if (indexPath.section == COLIDX_START && indexPath.row == 0) {
		//Start cell
		static NSString *CellIdentifier = @"StartCell";		 
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		
		NSString* txt = self.startString;
		if (txt == nil) {
			txt = @"";
		}
		cell.textLabel.text = NSLocalizedString(@"label.start", @"");
		cell.detailTextLabel.text = txt;
		acell = cell;
	} else if (indexPath.section == COLIDX_START && indexPath.row == 1) {
		//end cell
		static NSString *CellIdentifier = @"EndCell";		 
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		
		NSString* txt = self.endString;
		if (txt == nil) {
			txt = @"";
		}
		cell.textLabel.text = NSLocalizedString(@"label.end", @"");
		cell.detailTextLabel.text = txt;
		acell = cell;
	} else if (indexPath.section == COLIDX_START && indexPath.row == 2) {
		//duration cell
		static NSString *CellIdentifier = @"DurationCell";		 
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		NSString* txt = self.durationString;
		if (txt == nil) {
			txt = @"";
		}
		cell.textLabel.text = NSLocalizedString(@"label.duration", @"");
		cell.detailTextLabel.text = txt;
		acell = cell;
	} else if (indexPath.section == COLIDX_PAUSE) {
		//pause cell
		static NSString *CellIdentifier = @"PauseCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		NSString* txt = pauseString;
		if (txt == nil) {
			txt = @"";
		}
		cell.textLabel.text = NSLocalizedString(@"label.pause", @"");
		cell.detailTextLabel.text = txt;
		acell = cell;
	} else if (indexPath.section == COLIDX_REMARK) {
		//remark cell
		static NSString *CellIdentifier = @"RemarkCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		
		NSString* txt;
		if (wuCopy.description != nil && [wuCopy.description length] > 0) {	
			txt = wuCopy.description;
			cell.textLabel.text = txt;
			cell.textLabel.numberOfLines = 3;
			UIFont* f= [cell.textLabel.font fontWithSize:11];
			cell.textLabel.font = f;
		} else {
			txt = NSLocalizedString(@"notes.placeholder", @"");
			cell.textLabel.text = txt;
			cell.textLabel.textColor = [UIColor grayColor];
			cell.textLabel.numberOfLines = 3;
			UIFont* f= [cell.textLabel.font fontWithSize:11];
			cell.textLabel.font = f;
		}
		acell = cell;
//	} else if (indexPath.section == COLIDX_PROCESSED) {
//        //Processed Cell
//        static NSString *CellIdentifier = @"ProcessedCell";
//		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//		if (cell == nil) {
//			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
//			cell.selectionStyle = UITableViewCellSelectionStyleNone;
//            
//            //add a switch
//            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
//            self.processedSwitch = switchview;
//            cell.accessoryView = switchview;
//            [switchview release];
//		}
//        //set switch value (processed property)
//        self.processedSwitch.on = processed;
//        cell.textLabel.text = @"  ";
//        cell.detailTextLabel.text = NSLocalizedString(@"label.processed", @"");
//        acell = cell;
	} else {
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dummyCell"];
		if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dummyCell"];
		}
		cell.textLabel.text = @"";
		return cell;
	}
    
    int section = indexPath.section;
    if (acell && section == COLIDX_DEL) {
		acell.accessoryType = UITableViewCellAccessoryNone;		
	} else if (section == COLIDX_PROJECT || section == COLIDX_PAUSE || section == COLIDX_REMARK) {
		acell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else if (section == COLIDX_START) {
		if (indexPath.row == 2) {
			acell.accessoryType = UITableViewCellAccessoryNone;
		} else {
			acell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
	} else {
		acell.accessoryType = UITableViewCellAccessoryNone;		
	}
    return acell;
}



- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"row selected");
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath == nil) return;
	if (indexPath.section == COLIDX_PROJECT) {
        //switch to project subproject mask
        ProjectTaskEditViewController* ctl = [[ProjectTaskEditViewController alloc] initWithNibName:@"ProjectTaskEditView" bundle:nil];
        ctl.parent = self;
        ctl.workUnit = wuCopy;
        ctl.project = parentProject;
        ctl.task = parentTask;
        
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ctl];
        nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:nc animated:YES];
        [nc release];
        
		 [ctl release];
	} else if (indexPath.section == COLIDX_START && indexPath.row < 2) {
		//Pause edit mask
		BeginEndEditViewController* ctl = [[BeginEndEditViewController alloc] initWithNibName:@"BeginEndEditView" bundle:nil];
		ctl.parent = self;
		ctl.workUnit = wuCopy;
		ctl.editStartTime = indexPath.row == 0;

        //present the details controller as a modal controller with an own navigation controller (for the nav bar)
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:ctl];
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navController animated:YES];
        [navController release];
        
		[ctl release];
	} else if (indexPath.section == COLIDX_PAUSE) {
		//Switch to pause mask
		PauseEditViewController* ctl = [[PauseEditViewController alloc] initWithNibName:@"PauseEditView" bundle:nil];
		ctl.parent = self;
		ctl.workUnit = wuCopy;
        
        //present the details controller as a modal controller with an own navigation controller (for the nav bar)
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:ctl];
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navController animated:YES];
        [navController release];

		[ctl release];
	} else if (indexPath.section == COLIDX_REMARK) {
		//switch to description mask
		TextEditViewController* ctl = [[TextEditViewController alloc] initWithNibName:@"TextEditView" bundle:nil];
		ctl.workUnit = wuCopy;
		ctl.parent = self;
        
        //present the details controller as a modal controller with an own navigation controller (for the nav bar)
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:ctl];
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navController animated:YES];
        [navController release];

		[ctl release];
	}
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}



- (void)dealloc {
	[playPauseDeleteView release];	
	[projectSubprojectView release];
	[pauseView release];
	[startStopView release];
	[remarkView release];
	
	[lblProjectName release];
	[lblTaskName release];
	[lblBegin release];
	[lblEnd release];
	[lblDuration release];
	[lblPause release];
	[txtRemark release];
	[startStopButton release];
	[actIndicator release];
	[deleteButton release];
	
	[parentTask release];
	[parentProject release];	
	[workUnit release];
	[parentTable release];
	
	[pauseString release];
	[parentController release];
	
    [super dealloc];
}


@end

