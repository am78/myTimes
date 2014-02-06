//
//  ProjectDetailsViewController.m
//  TaskTracker
//
//  Created by Michael Anteboth on 10.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "ProjectDetailsViewController.h"
#import "WorkUnitsListViewController.h"
#import "ProjectTask.h"
#import "TaskCell.h"
#import "TableRowSelectionDelegate.h"
#import "TaskEditViewController2.h"
#import "NSArray+Filter.h"

#define ROW_HEIGHT 60

@implementation ProjectDetailsViewController

@synthesize project;
@synthesize addButtonItem;
@synthesize selectedRow;
@synthesize data;

//editing a project task either in edit mode or in creation mode
- (void) editTask:(ProjectTask*)pt editMode:(BOOL)editMode {
	//check if IO7 is running
    BOOL io7 = IOS7_CHECK;
    
	if (!editMode) { //create new task
		//create TaskEditView
        NSString* nibName = io7 ? @"TaskEditView" : @"TaskEditView_ios6";
		TaskEditViewController* ctl = [[TaskEditViewController alloc] initWithNibName:nibName bundle:nil];
		//set task in controller
		ctl.task = pt;
		ctl.editMode = editMode;
		ctl.parentTable = self.tableView;
		//show details controller as modal controller
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ctl];
        nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:nc animated:YES];
        [nc release];
        
        [ctl release];
        
	} 
	//edit selected task
	else {
		TaskEditViewController2* ctl = [[TaskEditViewController2 alloc] initWithNibName:@"TaskEditViewController2" bundle:nil];
		ctl.task = pt;
        
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ctl];
        nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:nc animated:YES];
        [nc release];
        
        [ctl release];
	}
}

//edit the selected project task (if one is selected)
- (void) editSelectedItem {
	if (selectedRow > -1) {
		int row = selectedRow;
		ProjectTask* pt = [project.tasks objectAtIndex:row];
		
		//check if the task is editable
		if (pt.userChangeable) {
			[self editTask:pt editMode:TRUE];
		}
	}
}

//Neues Task Element anlegen
- (void) addItem {
	//create new project object
	ProjectTask* pt = [[ProjectTask alloc] init];
	[self editTask:pt editMode:FALSE];
}

- (void)viewDidLoad {
    [super viewDidLoad];

	TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];

    self.data = self.project.tasks;
    
	//setting row height of each row to 60
	UITableView* table = self.tableView;
	table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	table.rowHeight = ROW_HEIGHT;
	
	NSLog(@"editing project: %@", [self.project name]);
	
	appDelegate.editingProject = self.project;
	appDelegate.addItemController = self;

	//setting the views title
	self.title = [self.project name];
	
	//self.navigationItem.rightBarButtonItem = self.addButtonItem;
    
	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.tableView.allowsSelectionDuringEditing = TRUE;
}



- (void)viewWillAppear:(BOOL)animated {
    
	selectedRow = -1;
    [super viewWillAppear:animated];
	//set current table view in appDelegate to be able to edit all the tables on the views with a unique mechanism
	TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.currentTableView = self.tableView;
	appDelegate.addItemController = self;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
	if (appDelegate.taskToLoadAtStartup != nil) {
		ProjectTask* pt = appDelegate.taskToLoadAtStartup;
		int row = [self.project.tasks indexOfObject:pt];
		//load a task a startup
		NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:0];
		//scroll down to active task
		[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:false];
		UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:path];
		//select the row
		[cell setSelected:TRUE];
		//open the active task an show its task list
		[self tableView:self.tableView didSelectRowAtIndexPath:path];		
		//reset task to load to nil
		appDelegate.taskToLoadAtStartup = nil;
	}
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.navigationItem setHidesBackButton:editing animated:animated];
	TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
	//globale buttons de-/aktivieren
	[appDelegate.rootViewController enabledGlobalButtons:!editing sender:self];
 }


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark TableRowSelectionDelegate methods
-(BOOL) isRowSelected:(int)row {
	return row == selectedRow;
}

-(void) setRowSelected:(int)row selected:(BOOL) selected {
	if (selected) selectedRow = row;
	else selectedRow = -1;
}

-(void) release {
	[super release];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//return number of tasks for the current project
    return [self.data count];
	
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"TaskCellView";	
	TaskCell* taskCell = (TaskCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (taskCell == nil) {
   		taskCell = [[[TaskCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	
	//set the project task element in the cell view
	ProjectTask* pt = [self.data objectAtIndex:[indexPath row]];
	if (pt != nil) {
		taskCell.task = pt;
		[taskCell setRow:[indexPath row]];
		[taskCell setCtl:self];
	}
    taskCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return taskCell;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if (selectedRow == -1) {
		//select a row
		selectedRow = [indexPath row];
	} else if (selectedRow == [indexPath row]){
		//deselect row
		selectedRow = -1;
	} else {
		//select another row		 
		selectedRow = [indexPath row];
	}
	
//	[self.tableView reloadData];
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.tableView.editing) {
		//Teilprojekt selektiert, Details zum Teilprojekt anzeigen (Zeiten)
		//the selected task
		ProjectTask* t = [self.data objectAtIndex:[indexPath row]];
		NSLog(@"start editing task: %@", t.name);
		//ProjectDetailsView erzeugen und anzeigen
		WorkUnitsListViewController* workUnitsViewCtl = [[WorkUnitsListViewController alloc] initWithNibName:@"WorkUnitsListView" bundle:nil];
		//set task in workunitlistview
		workUnitsViewCtl.task = t;
		workUnitsViewCtl.parentProject = self.project;
		workUnitsViewCtl.parentTable = self.tableView;
		[self.navigationController pushViewController:workUnitsViewCtl animated:YES];
	} else {
		TaskTrackerAppDelegate* appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
		//Im EditModus selektiert, also teilprojekt editieren
		[appDelegate.addItemController editSelectedItem];
	}
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//check if the task is editable
	if (indexPath.row < [self.data count]) {
		ProjectTask* task = [[self.project tasks] objectAtIndex:indexPath.row];
		if (task.userChangeable) {
			return YES;
		}
	}
    
    return NO;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		ProjectTask* t = [self.data objectAtIndex:[indexPath row]];
		[[self.project tasks] removeObject:t];
		//delete the row from table view
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		//is this nessecary? reload data
		[self.tableView reloadData];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NSMutableArray* array = self.data;
	NSUInteger fromRow = [fromIndexPath row];
	NSUInteger toRow = [toIndexPath row];
	id object = [[array objectAtIndex:fromRow] retain];
	[array removeObjectAtIndex:fromRow];
	[array insertObject:object atIndex:toRow];
	[object release];
}




// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}



- (void)dealloc {
	[addButtonItem release];
	[project release];
    [super dealloc];
}


@end

