//
//  TextEditViewController.m
//  TaskTracker
//
//  Created by Michael Anteboth on 18.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TextEditViewController.h"


@implementation TextEditViewController

@synthesize textView;
@synthesize parent;
@synthesize workUnit;



-(void) save:(id)sender {
	//ommit entered text
	workUnit.description = self.textView.text;
	if (parent != nil) {
		//refresh parent view
		[parent updateDataFields];	
		//mark the workUnit entry as changed in the parent controller
		parent.dirty = TRUE;
	}
	//close view
	[self dismissModalViewControllerAnimated:YES];
}


-(void) cancel:(id)sender {
	//close the view
	[self dismissModalViewControllerAnimated:YES];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[textView becomeFirstResponder];
	//show the workunits text
	textView.text = workUnit.description;
    
    //create the save button
	UIBarButtonItem *saveButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																				 target:self action:@selector(save:)] autorelease];
	//and add it to the navigation bar
	self.navigationItem.rightBarButtonItem = saveButton;
	
	//create the cancel button
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self action:@selector(cancel:)] autorelease];
	//and add it to the navigation bar
	self.navigationItem.leftBarButtonItem = cancelButton;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[workUnit release];
	[parent release];
	[textView release];
    [super dealloc];
}


@end
