//
//  ProjectEditViewController.m
//  TaskTracker
//
//  Created by Michael Anteboth on 11.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ProjectEditViewController.h"


@implementation ProjectEditViewController

@synthesize project;
@synthesize txtName;
@synthesize isInEditMode;
@synthesize nameLabel;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	//show keypad	
	[txtName becomeFirstResponder];
	//Projektname im editor setzen
	if (isInEditMode) {
		txtName.text = project.name;	
	} else {
		txtName.placeholder = NSLocalizedString(@"name.plcaeholder", @"");
	}
    
    self.nameLabel.text = NSLocalizedString(@"name.label", @"");
    
    //create the save button
	UIBarButtonItem *saveButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																				 target:self action:@selector(saveProject:)] autorelease];
	//and add it to the navigation bar
	self.navigationItem.rightBarButtonItem = saveButton;
	
	//create the cancel button
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self action:@selector(cancelEditing:)] autorelease];
	//and add it to the navigation bar
	self.navigationItem.leftBarButtonItem = cancelButton;

}

//Save project
- (IBAction) saveProject:(id)sender {
	NSLog(@"Save project");
	Project* p = self.project;
	//Daten speichern 
	p.name = [self.txtName text];

	TaskTrackerAppDelegate *appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
	if (isInEditMode == FALSE) {
		//Wenn nicht im EditMode (dann im create mode) neues Projekt zur Projekt liste adden, nur dann
		[appDelegate addProject:p];
	}
	
	//und Edit View wieder verlassen
	[self dismissModalViewControllerAnimated:YES];
	
	[appDelegate saveData];
}

- (IBAction) cancelEditing:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[project release];
	[txtName release];
    [nameLabel release];
	[super dealloc];
}


- (void)viewDidUnload {
    [nameLabel release];
    nameLabel = nil;
    [super viewDidUnload];
}
@end
