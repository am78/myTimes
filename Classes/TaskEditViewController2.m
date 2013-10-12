//
//  TaskEditViewController2.m
//  TaskTracker
//
//  Created by Michael Anteboth on 14.05.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TaskEditViewController2.h"
#import "TextEditController.h"
#import "BooleanEditController.h"

@implementation TaskEditViewController2

@synthesize task, editingEntry;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
    
	//create the cancel button
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self action:@selector(done:)] autorelease];
	//and add it to the navigation bar
	self.navigationItem.leftBarButtonItem = cancelButton;

}


- (void) done:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (section == 0) {
		//2 rows for name and description
		return 2;
	} else {
		//return the count of additional generic attributes
		return [appDelegate.dataEntryDefinitions count];
	}
}

- (void) actionFlipRowState:(id)sender {
	NSLog(@"switch state");
	//get te current state
	BOOL selected = [self.editingEntry.value boolValue];
	//set the toggled state and refresh the table
	[self takeNewBool:selected];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
	//first section
	if (indexPath.section == 0) {
		//the name cell
		if (indexPath.row == 0) {
			cell.textLabel.text = self.task.name;
			cell.detailTextLabel.text = NSLocalizedString(@"name", @"");
		}
		//the description cell
		else if (indexPath.row == 1) {
			cell.textLabel.text = self.task.description;
			cell.detailTextLabel.text = NSLocalizedString(@"description", @"");
		}
	} 
	//2nd section
	else if (indexPath.section == 1) {
		//return the cell for the generic attribute
		NSArray* keys = [appDelegate.dataEntryDefinitions allKeys];
		id key = [keys objectAtIndex:indexPath.row];
		DataEntry* entry = [appDelegate.dataEntryDefinitions objectForKey:key];
		
		if (entry.type == kString) {
			cell.textLabel.text = (NSString*) entry.value;
			cell.detailTextLabel.text = entry.displayText;
		} 
		else if (entry.type == kBool) {
			cell.detailTextLabel.text = entry.displayText;
			UISwitch* stateSwitch = [[UISwitch alloc] init];
			stateSwitch.on = [entry.value boolValue];			
			cell.accessoryView = stateSwitch;
			[stateSwitch addTarget: self
							action: @selector(actionFlipRowState:)
				  forControlEvents: UIControlEventValueChanged];
			//cell.target = settings;
			
			[stateSwitch release];
		}
	}
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


#pragma mark -
#pragma mark Editing attributes

//starts the editing of the obtained text using the text editing ctl (as model ctl)
- (void) editText:(NSString*)txt {
	TextEditController* ctl = [[TextEditController alloc] initWithNibName:@"TextEditView" bundle:nil];
	ctl.string = txt;
	ctl.delegate = self;
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ctl];
    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:nc animated:YES];
    [nc release];
    
	[ctl release];
}

//callback from text edit controller
- (void)takeNewString:(NSString *)newValue {
	//name changed
	if (textEditMode == 0) {
		self.task.name = newValue;
	}
	//description changed
	else if (textEditMode == 1) {
		self.task.description = newValue;
	}
	//generic text attribute has been changed
	else if (textEditMode == 2) {
		if (editingEntry != nil) {
			editingEntry.value = newValue;
		}
	}
	
	//reload table data
	[self.tableView reloadData];
}

//callbakc method to save the edited boolean value
- (void) takeNewBool:(BOOL) value {
	if (editingEntry != nil) {
		NSString* s = value ? @"Y" : @"N";
		NSLog(@"Changed Bool Value: %@", s);
		editingEntry.value = s;
	}

	//reload table data
	[self.tableView reloadData];

}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		//edit the name
		if (indexPath.row == 0) {
			textEditMode = 0;
			[self editText:self.task.name];
		}
		//edit the description
		else if (indexPath.row == 1) {
			textEditMode = 1;
			[self editText:self.task.description];
		}
	}
	//edit additional attributes
	else {
		//get the entry which should by edited
		NSArray* keys = [appDelegate.dataEntryDefinitions allKeys];
		id key = [keys objectAtIndex:indexPath.row];
		DataEntry* entry = [appDelegate.dataEntryDefinitions objectForKey:key];
		if (entry != nil) {
			self.editingEntry = entry;
			//edit text value
			if (entry.type == kString) {
				textEditMode = 2;
				[self editText:entry.value];
			}
			//edit boolean value
			/*else if (entry.type == kBool) {
				NSLog(@"Edit bool value: %@", entry.displayText);
				BooleanEditController* ctl = [[BooleanEditController alloc] initWithNibName:@"BooleanEditView" bundle:nil];
				ctl.value = [entry.value boolValue];
				ctl.labelTxt = entry.displayText;
				ctl.delegate = self;
				[self presentModalViewController:ctl animated:TRUE];
				[ctl release];			
			}*/
		}
		
	}
}



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[editingEntry release];
	[task release];
	[super dealloc];
}


@end

