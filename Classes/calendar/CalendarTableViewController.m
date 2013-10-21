//
//  CalendarTableViewController.m
//  Calendar
//
//  Created by Michael Anteboth on 20.01.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "CalendarTableViewController.h"
#import "CalItemView.h"
#import "CalendarTableView.h"
#import "TaskTrackerAppDelegate.h"
#import "TimeUtils.h"

@implementation CalendarTableViewController

@synthesize titleTxt;

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void) viewDidAppear:(BOOL)animated
{
    [self refreshData];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
	CalendarTableView* tv = (CalendarTableView*)self.tableView;
	[[tv calendarDelegate] clearCachedData];
	
	self.titleTxt = [self getTitleText];

    //create segmnet control with << and >> buttons
    NSArray *items = [NSArray arrayWithObjects: @"<<", @">>", nil];
    UISegmentedControl* segment = [[UISegmentedControl alloc] initWithItems:items];
    segment.frame = CGRectMake(0, 0, 60, 25);
    segment.segmentedControlStyle = UISegmentedControlStylePlain;
    segment.momentary = TRUE;
    [segment addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
    
    //create customt left button with segment (<< >>) control
    UIBarButtonItem* leftItem = [[UIBarButtonItem alloc] initWithCustomView:segment];
    self.navigationItem.leftBarButtonItem = leftItem;
    [segment release];
    
    //create Done button
    UIBarButtonItem *exitButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self action:@selector(closeCalendarView:)];
    self.navigationItem.rightBarButtonItem = exitButton;

    //set title
    self.navigationItem.title = self.titleTxt;
    
}

//Action method executes when user touches the button
-(void) segmentSelected:(id)sender{
    //goto next/prev day
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    int idx = [segmentedControl selectedSegmentIndex];
    if (idx == 0) {
        [self loadPrev:sender];
    }
    else {
        [self loadNext:sender];
    }
    //update title text
    self.navigationItem.title = [self getTitleText];
}

-(void) loadPrev:(id)sender {
	//load previous day
	[self switchToDaysFromNow:-1];
}

-(void) loadNext:(id)sender {
	//load next day
	[self switchToDaysFromNow:1];
}

//closing the calendar view requested
-(void) closeCalendarView:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

//show the day +/- n Days from current date in calendar view
-(void) switchToDaysFromNow:(int) days {
	CalendarTableView* tv = (CalendarTableView*)self.tableView;
	NSDate* d = [[[tv calendarDelegate] getDisplayedDay] retain];
	int dayInSecs = 3600 * 24 * days;
	NSDate* newDate = [d initWithTimeInterval:dayInSecs sinceDate:d];
	//set current date to previous day
	[tv.calendarDelegate setDisplayedDay:newDate];
	//reload view
	[self refreshData];
	
}

-(void) refreshData {
	//reload the data
	[self.tableView reloadData];

	self.titleTxt = [self getTitleText];
	//set navigation item title
	titleLbl.text = self.titleTxt;
}


//create the Footer toolbar with close button
/*
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	UIView* footer = [[[UIView alloc] initWithFrame:CGRectMake(0, 450, 320, 30)] autorelease];
	footer.alpha = 1.0;
	//create footer button bar
	UIToolbar* toolbar = [[UIToolbar alloc] init];
	toolbar.barStyle = UIBarStyleDefault;
	//Set the toolbar to fit the width of the app.
	[toolbar sizeToFit];
	//Caclulate the height of the toolbar
	CGFloat toolbarHeight = [toolbar frame].size.height;
	//Get the bounds of the parent view
	CGRect rootViewBounds = footer.bounds;
	//Get the height of the parent view.
	CGFloat rootViewHeight = CGRectGetHeight(rootViewBounds);
	//Get the width of the parent view,
	CGFloat rootViewWidth = CGRectGetWidth(rootViewBounds);
	//Create a rectangle for the toolbar
	CGRect rectArea = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
	//Reposition and resize the receiver
	[toolbar setFrame:rectArea];
	
	//create the close button
    UIBarButtonItem *exitButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                 action:@selector(closeCalendarView:)];
	
	//space between buttons
	UIBarButtonItem* flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace  target:nil action:nil];
	
	//Add buttons to toolbar
	[toolbar setItems:[NSArray arrayWithObjects:flexButton, exitButton, nil]];
	
	//Add the toolbar as a subview to the navigation controller.
	[footer addSubview:toolbar];
	
	//release ressources
	[exitButton release];
	[flexButton release];
	[toolbar release];
    
	return footer;
}
 */

 
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 30.0f;
}

//get the title string for the current configuration
-(NSString*) getTitleText {
	CalendarTableView* tv = (CalendarTableView*)self.tableView;	
	NSDate* d = [[tv calendarDelegate] getDisplayedDay];
	NSString* txt = [TimeUtils formatDate:d withFormatType:2];
	
	long totalDuration = [[tv calendarDelegate] getDurationOfAllEntriesForCurrentDay];
	NSString* durString = [TimeUtils formatSeconds:totalDuration];
	
	return [NSString stringWithFormat:@"%@ (%@)", txt, durString];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 27;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];        
    }
	
    UIFont* f = [cell.textLabel.font fontWithSize:12];
	cell.textLabel.font = f;

	cell.textLabel.textColor = [UIColor grayColor];

	int hr = indexPath.row;
	if (hr < 24) {
		NSString* rowdelim = @"  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -";
		NSString* timeString = [TimeUtils getTimeString:hr min:0];
		cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", timeString, rowdelim ];
	} else {
		cell.textLabel.text = @"        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -";
	}
    
	//no selection visualization
	cell.selectionStyle = UITableViewCellSelectionStyleNone;

	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	[self.tableView deselectRowAtIndexPath:indexPath animated:false]; 
}


- (void)dealloc {
	[titleLbl release];
	[titleLabel release];
	[titleTxt release];
	[dateFormatter release];
    [super dealloc];
}


@end

