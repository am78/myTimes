//
//  TaskNameEditController.m
//  TaskTracker
//
//  Created by Michael Anteboth on 14.05.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TextEditController.h"


@implementation TextEditController

@synthesize textView;
@synthesize delegate;
@synthesize string;


-(void) save:(id)sender {
	//save entered text
	[self.delegate takeNewString:textView.text];
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
	textView.text = string;
    
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
	[string release];
//	[delegate release];
	[textView release];
    [super dealloc];
}


@end

