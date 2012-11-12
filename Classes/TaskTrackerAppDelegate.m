//
//  TaskTrackerAppDelegate.m
//  TaskTracker
//
//  Created by Michael Anteboth on 10.01.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TaskTrackerAppDelegate.h"
#import "TimeWorkUnit.h"
#import "ProjectTask.h"
#import "Project.h"
#import "XmlParser.h"
#import "NSDataAddition.h"

@implementation TaskTrackerAppDelegate

@synthesize editingProject;
@synthesize window;
@synthesize navigationController;
@synthesize data;
@synthesize dataEntryDefinitions;
@synthesize rootViewController;
@synthesize tabBarController;
@synthesize currentTableView;
@synthesize addItemController;
@synthesize dateFormatter;
@synthesize timeFormatter;
@synthesize allowMultipleTasks;
@synthesize projectToLoadAtStartup;
@synthesize taskToLoadAtStartup;
@synthesize workUnitToLoadAtStartup;
@synthesize minuteInterval;
@synthesize useDefaultTimes;
@synthesize defaultEndTime;
@synthesize defaultStartTime;
@synthesize defaultPauseValue;
@synthesize promptForCommentWhenStoppingTime;
@synthesize dataToRestore;
@synthesize restoreFilePath;
@synthesize importFile;

/* format seconds to  e.g. 2:19 h for 2 hours and 19 minutes */
-(NSString*) formatSeconds:(float)timeInSecs {	
	const int secsPerMin = 60;
	const int secsPerHour = secsPerMin * 60;
	const char *timeSep = ":"; //@TODO localise...
	const char *hrsName = "h";
	
	float time = timeInSecs;
	int hrs = time/secsPerHour;
	
	time -= hrs*secsPerHour;
	int mins = time/secsPerMin;
	//time -= mins*secsPerMin;
	
	return [NSString stringWithFormat:@"%d%s%02d %s", hrs, timeSep, mins, hrsName];
}

//turn table editing on or off
- (void) toogleTableEditMode:(BOOL)editing {
	if (editing) {
		[navigationController setEditing:FALSE animated:TRUE];
		//in edit mode,  so finish edit mode
		[self.currentTableView endEditing:TRUE];
		[self.currentTableView setEditing:FALSE animated:TRUE];
	} else {
		//not in edit mode, so switch to edit mode
		[self.currentTableView setEditing:TRUE animated:TRUE];
	}
}


//Add a new project to the data an refresh the project view
- (void) addProject:(Project*)aProject {
	//add project to data array
	[self.data addObject:aProject];
	//refresh project table
	[[self.rootViewController tableView] reloadData];
}

//add a new task to the currently editing project
- (void) addTask:(ProjectTask*) aTask {
	NSMutableArray* tasks = [self.editingProject tasks];
	[tasks addObject:aTask];
	//[projectDetailsViewCtl.tableView reloadData];
}


//open an URL at startup, until now only import of XML data by opening mytimes with a specific url is supported
//url format: mytimes//?importdata=<base64 encoded xml data>
//or mytimes://?importsource=<URL to XML file>
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if (!url) {  return NO; }
    
    self.importFile = nil;
	
	NSString *URLString = [url absoluteString];
	NSLog(@"open url: %@", URLString);
	
	NSRange range = [URLString rangeOfString:@"importdata="];
	if (range.length > 0) {
		//import data from base64 encoded XML which is coded in the url content
		NSString* base64data = [URLString substringFromIndex:range.location+range.length];
		//decode base64 string to xml data and import the xml data
		NSData* xmlData = [NSData dataWithBase64EncodedString: base64data];
		
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"xml.importAtStart.importSourceDialogTitle2", @"")
														message:nil
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"xml.import.importSourceDialog.cancel", @"") 
											  otherButtonTitles:NSLocalizedString(@"xml.import.importSourceDialog.ok", @""), NSLocalizedString(@"xml.import.importSourceDialog.ok2", @""), nil];
		[alert show];
		[alert release];	
		
		//Import URL zwischenspeichern, damit zu einenm späteren Zeitpunkt (wenn Anwendung geladen wurde) darauf zugegriffen werden kann
		[[NSUserDefaults standardUserDefaults] setObject:xmlData forKey:@"importdata"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"importsource"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"importsourceUrl"];        
		[[NSUserDefaults standardUserDefaults] synchronize];		
		
		return YES;
	} else {
		//import projects from external URL
		range = [URLString rangeOfString:@"importsource="];
		if (range.length > 0) {
			NSString* tmp = [URLString substringFromIndex:range.location+range.length];
			NSString* xmlUrl = [tmp stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
		
	
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"xml.importAtStart.importSourceDialogTitle", @"")
													message:xmlUrl
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"xml.import.importSourceDialog.cancel", @"") 
										  otherButtonTitles:NSLocalizedString(@"xml.import.importSourceDialog.ok", @""), NSLocalizedString(@"xml.import.importSourceDialog.ok2", @""), nil];
			[alert show];
			[alert release];	
	
			//Import URL zwischenspeichern, damit zu einenm späteren Zeitpunkt (wenn Anwendung geladen wurde) darauf zugegriffen werden kann
			[[NSUserDefaults standardUserDefaults] setObject:xmlUrl forKey:@"importsource"];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"importdata"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"importsourceUrl"];
			[[NSUserDefaults standardUserDefaults] synchronize];
	
			return YES;
		} 
        else {
            //import from file in documents/inbox directory (when opening mail attachment)
            
            if ([url isFileURL]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"importdata"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"importsource"];                
                [[NSUserDefaults standardUserDefaults] synchronize];
                self.importFile = nil;                
                

                NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *theFileName = [URLString lastPathComponent];
                NSString *path = [NSString stringWithFormat:@"%@/Inbox/%@", documentsDirectory, theFileName];
                self.importFile = path;                                
                
                //Import data from file
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"xml.importAtStart.importSourceDialogTitle2", @"")
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"xml.import.importSourceDialog.cancel", @"") 
                                                      otherButtonTitles:NSLocalizedString(@"xml.import.importSourceDialog.ok", @""), NSLocalizedString(@"xml.import.importSourceDialog.ok2", @""), nil];
                [alert show];
                [alert release];		

                return YES;
            }
            
        }
	}
	return FALSE;
}

//import project from XML data
-(void) importFromXMLData:(NSData*)xmlData addAsNewProjects:(BOOL)addProjects {
	if (xmlData == nil) return;
	
	//create parser and start parsing
	XmlParser* parser = [[XmlParser alloc]init];
	NSMutableArray* importedProjects = [parser parseFromXmlData:xmlData];
	[parser release];
	
	if (importedProjects != nil && [importedProjects count] > 0 && !addProjects) {
		//there is at least one project to import and the user requsested to delete the old projects
		//so remove all projects
		[self.data removeAllObjects];
	}
	
	//Add the imported projects to the project list
	for (Project* p in importedProjects) {
		[self.data addObject:p];
	}
	
	int count = [importedProjects count];
	NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"xml.import.n_projectsImported.message", @""), count];
	//TODO print message about how many projects were imported
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"xml.import.projectsImportetTitle", @"")
													message:msg
												   delegate:nil 
										  cancelButtonTitle:nil
										  otherButtonTitles:NSLocalizedString(@"xml.import.importFinished.ok", @""), nil];
	[alert show];
	[alert release];
	
	//refresh table
	[self.currentTableView reloadData];
}

//import projects from url e.g.: http://iphone.anteboth.com/mytimes/xml/mytimes-export.xml
-(void) importFromUrl:(NSString*)urlString addAsNewProjects:(BOOL)addProjects {
	if (urlString == nil) return;

	NSLog(@"import data: %@", urlString);
	
	//create parser and start parsing
	XmlParser* parser = [[XmlParser alloc]init];
	NSMutableArray* importedProjects = [parser parseFromURL:urlString];
	[parser release];
	
	if (importedProjects != nil && [importedProjects count] > 0 && !addProjects) {
		//there is at least one project to import and the user requsested to delete the old projects
		//so remove all projects
		[self.data removeAllObjects];
	}
	
	//Add the imported projects to the project list
	for (Project* p in importedProjects) {
		[self.data addObject:p];
	}
	
	int count = [importedProjects count];
	NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"xml.import.n_projectsImported.message", @""), count];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"xml.import.projectsImportetTitle", @"")
													message:msg
												   delegate:nil 
										  cancelButtonTitle:nil
										  otherButtonTitles:NSLocalizedString(@"xml.import.importFinished.ok", @""), nil];
	[alert show];
	[alert release];
	
	//refresh table
	[self.currentTableView reloadData];
}


//import projects from url e.g.: http://iphone.anteboth.com/mytimes/xml/mytimes-export.xml
-(void) importFromString:(NSString*)sData addAsNewProjects:(BOOL)addProjects {
	if (sData == nil) return;
    
    
	NSLog(@"import data: %@", sData);
	
    NSData* xmldata = [sData dataUsingEncoding:NSUTF8StringEncoding];
    
	//create parser and start parsing
	XmlParser* parser = [[XmlParser alloc]init];
	NSMutableArray* importedProjects = [parser parseFromXmlData:xmldata];
	[parser release];
	
	if (importedProjects != nil && [importedProjects count] > 0 && !addProjects) {
		//there is at least one project to import and the user requsested to delete the old projects
		//so remove all projects
		[self.data removeAllObjects];
	}
	
	//Add the imported projects to the project list
	for (Project* p in importedProjects) {
		[self.data addObject:p];
	}
	
	int count = [importedProjects count];
	NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"xml.import.n_projectsImported.message", @""), count];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"xml.import.projectsImportetTitle", @"")
													message:msg
												   delegate:nil 
										  cancelButtonTitle:nil
										  otherButtonTitles:NSLocalizedString(@"xml.import.importFinished.ok", @""), nil];
	[alert show];
	[alert release];
	
	//refresh table
	[self.currentTableView reloadData];
}


//wenn ok gedrückt wurde den import fortsetzen
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//TODO error handling
	if (buttonIndex == 1 || buttonIndex == 2) {
		BOOL addProjects = buttonIndex == 1;
		
		NSData* xmlData = [[NSUserDefaults standardUserDefaults] valueForKey:@"importdata"];
		if (xmlData != nil) {
			[self importFromXMLData:xmlData addAsNewProjects:addProjects];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"importdata"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		
		//OK pressed, so start the import
		NSString* xmlUrl = [[NSUserDefaults standardUserDefaults] valueForKey:@"importsource"];
		if (xmlUrl != nil) {
			[self importFromUrl:xmlUrl addAsNewProjects:addProjects];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"importsource"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
                
   		
        if (self.importFile != nil)
        {
            //if import file name set
            //load data from file
            
            NSError* error = nil;
            NSData* myData = [[NSData dataWithContentsOfFile:self.importFile options:NSDataReadingMapped error:&error] retain];
            
            if (error) {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
            else{
                if (myData) {  
                    //and start the import
                    [self importFromXMLData:myData addAsNewProjects:addProjects];
                }
            }
            
            //set filename to nil
            self.importFile = nil;
            
        }
	} 
}

#pragma mark -
#pragma mark Application Life Cycle

//save the data and update the application badge
- (void) storeDataAndUpdateAppBadge {
	//save data
	[self saveData];
	//set application badge
	int activeProjects = 0;
	//find active projects
	for (Project* p in self.data) {
		if ([p hasRunningWorkUnits]) activeProjects++;
	}
	
	//show badge number
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:activeProjects];
}

//called when the app became inactive
- (void) applicationDidEnterBackground:(UIApplication *)application {
	//save the data and update the application badge
	[self storeDataAndUpdateAppBadge];	
}

//called when the app will be terminated
- (void)applicationWillTerminate:(UIApplication *)application {
	
	//save the data and update the application badge
	[self storeDataAndUpdateAppBadge];	

	
	//remeber the current element project and project task showing
	//TODO
}

//called when the app comes active again
- (void) applicationDidBecomeActive:(UIApplication *)application {
	NSLog(@"become active");
	
	//check if there a a backup to restore on the file system
	
	// Get path to documents directory
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		// Path to save the data
		NSString  *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"restore.mtb"];
		self.restoreFilePath = filePath;
		
		// Read data back from file
		NSData* dataFromFile = [NSData dataWithContentsOfFile:filePath];		
		[self importProjectFromData:dataFromFile];

	}
}

//imports projects from the obtained NSData
- (void) importProjectFromData:(NSData*) importData {
	
	//proceed only if data can be read (it's NIL if the file could not be read e.g. because it's not present)
	if (importData != nil) {
		NSLog(@"%d bytes of data read from file.", [importData length]);
		
		//unpack the data
		NSMutableArray* restoreData = [NSKeyedUnarchiver unarchiveObjectWithData:importData];
		
		if (restoreData == nil) {
			//there is nothing to import, so break here
			return;
		}
		
		NSLog(@"%d project can be restored from the restore file.", [restoreData count]);
		
		//remember the data which should be imported to be used in the action sheet callback method
		self.dataToRestore = restoreData;
		
		//ask the user if he wants to restore the data 
		//the former data will be overridden
		NSString* sMsg = [NSString stringWithFormat:
						  @"Möchten Sie die Daten wiederherstellen?\nDabei werden %d Projekte importiert.\nMöchten Sie Ihre jetzigen Daten überschreiben oder die importierten Daten als neue Projekte anfügen.", [dataToRestore count] ];
		
		UIActionSheet* action = [[UIActionSheet alloc] initWithTitle:sMsg
															delegate:self
												   cancelButtonTitle:@"Abbrechen"
											  destructiveButtonTitle:@"Überschreiben"
												   otherButtonTitles:@"Anfügen", nil];
		UIView* view = self.navigationController.view;
		[action showInView:view];			
	}
}

//the action sheet callback method is invoked after an action sheet button was pressed
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (self.dataToRestore == nil) {
		//return if there is nothing to import
		return;
	}
	
	BOOL restore = false;
	BOOL overwrite = false;
	if (buttonIndex == 0) {
		//overwrite data
		restore = true;
		overwrite = true;
	} else if (buttonIndex == 1) {
		//append data
		restore = true;
		overwrite = false;	
	} else {
		restore = false;
		overwrite = false;
	}
	
	if (restore) {
		if (overwrite) {
			//set the restored data as new application data
			self.data = self.dataToRestore;
		} else {
			//append the restored data
			[self.data addObjectsFromArray:self.dataToRestore];
		}
		
		//updating the change data in the rootViewController is needed at this point
		self.rootViewController.data = self.data;
		
		NSLog(@"Remove restore file.");
		//and remove the restore file
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:self.restoreFilePath error:NULL];
		NSLog(@"Restore file removed.");
		
		//set the restore data to nil
		//[self.dataToRestore release];
		self.dataToRestore = nil;
		
		//[self.restoreFilePath release];
		self.restoreFilePath = nil;
		
		//reload the table view
		[self.rootViewController.tableView reloadData];
	}
	
}

//called when the app has been launched
-(BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	[NSURLProtocol registerClass: [NSURL URLWithString:@"mytimes://"]]; 

	NSLog(@"Load data...");
	//Init data store
	//read archived data
	@try {
		self.data = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults]objectForKey:@"taskTrackerData"]];
		NSLog(@"Data loaded!");
	}
	@catch (NSException* ex) {
		NSLog(@"Error Loading data: %@",ex);
	}
	
	if (self.data == nil) {
		//if no data can be read use an empty project array
		self.data = [[NSMutableArray alloc] init];
	}
	
	
	//Init dataEntry definitions
	//read archived data
	self.dataEntryDefinitions = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults]objectForKey:@"taskTrackerDataEntryDefinitions"]];
	
/*	if (self.dataEntryDefinitions == nil) {
		//if no data can be read use an empty array
		self.dataEntryDefinitions = [[NSMutableDictionary alloc] init];
		
	
		DataEntry* stringEntry = [[DataEntry alloc] init];
		stringEntry.name = @"stringValue01";
		stringEntry.displayText = @"String Value 01";
		stringEntry.type = kString;
		stringEntry.sortIndex = 0;
		stringEntry.value = @"test";
		[self.dataEntryDefinitions setObject:stringEntry forKey:stringEntry.name];

		stringEntry = [[DataEntry alloc] init];
		stringEntry.name = @"BooleanValue";
		stringEntry.displayText = @"Boolean Flag";
		stringEntry.type = kBool;
		stringEntry.sortIndex = 1;
		stringEntry.value = @"true";
		[self.dataEntryDefinitions setObject:stringEntry forKey:stringEntry.name];
	}*/
	
	
	
	//init the dateformatter
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateStyle:NSDateFormatterMediumStyle];
	[df setTimeStyle:NSDateFormatterNoStyle];
	dateFormatter = df;
	
	//init the time formatter
	NSDateFormatter *tf = [[NSDateFormatter alloc] init];
	[tf setDateStyle:NSDateFormatterNoStyle];
	[tf setTimeStyle:NSDateFormatterShortStyle];
	timeFormatter = tf;
	
	//I18N stuff
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
	NSString *currentLanguage = [languages objectAtIndex:0]; //users prefered lang ist the first one
	
	NSLog(@"Current Locale: %@", [[NSLocale currentLocale] localeIdentifier]);
	NSLog(@"Current language: %@", currentLanguage);
	NSLog(@"Welcome Text: %@", NSLocalizedString(@"welcomekey", @"welcome"));
	
	window.rootViewController = rootViewController;
	
	// Configure and show the window
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
	
	NSString* s_allowMultipleTasks = [[NSUserDefaults standardUserDefaults] stringForKey:@"allowMultipleTasks"];
	
	//get the minute interval from user settings
	minuteInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"minutesInterval"];
	if (minuteInterval == 0) {
		minuteInterval = 5; //if Interval can't read, use the default value
	}
	
	//set the member variable
	allowMultipleTasks = [s_allowMultipleTasks boolValue];
	NSLog(@"allow multiple tasks: %i", allowMultipleTasks);
	
	//on first lauch select the active project if the auto load on startup flag is set
	NSString* s_loadActiveItemOnStartup = [[NSUserDefaults standardUserDefaults] stringForKey:@"loadActiveItemOnStartup"];
	BOOL loadActiveItemOnStartup = [s_loadActiveItemOnStartup boolValue];
	NSLog(@"loadactive item at startup: %i", loadActiveItemOnStartup);
	if (loadActiveItemOnStartup) [self reselectActiveEntries];
	
	//get the default start/end/pause times if there are values defined in the application settings
	
	//get the enabled flag
	NSString* s_useDefaultTimes = [[NSUserDefaults standardUserDefaults] stringForKey:@"useDefaultStartStopPauseValues"];
	//get the time values (they are store in hh:mm format)
	NSString* s_defaultStartValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultStartTime"];
	NSString* s_defaultEndValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultEndTime"];
	NSString* s_defaultPauseValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultPauseTime"];
	useDefaultTimes = [s_useDefaultTimes boolValue];
	NSLog(@"use default times: %i start: %@ end: %@ pause: %@", useDefaultTimes, s_defaultStartValue, s_defaultEndValue, s_defaultPauseValue);
	
	if (useDefaultTimes) {
		//get the current day as string
		NSDateFormatter *dfToday = [[NSDateFormatter alloc] init];
		[dfToday setDateFormat:@"yyyy-MM-dd"];
		NSDate* today = [NSDate date];
		NSString* s_today = [dfToday stringFromDate:today];
		
		//parse default time values
		// Convert string to date object and use today as date
		NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm"];
		//start datetime
		defaultStartTime = [[dateFormat dateFromString:[NSString stringWithFormat:@"%@ %@", s_today, s_defaultStartValue]] retain];
		//end datetime
		defaultEndTime = [[dateFormat dateFromString:[NSString stringWithFormat:@"%@ %@", s_today, s_defaultEndValue]] retain]; 
		//parse pause time in minutes
		defaultPauseValue = [s_defaultPauseValue intValue];
	}
	
	
	//get the prompt for comment when stopping time entry flag
	self.promptForCommentWhenStoppingTime = TRUE;
	NSString* s_promptForComment = [[NSUserDefaults standardUserDefaults] stringForKey:@"promptForCommentWhenStoppingEntry"];
	if (s_promptForComment != nil) {
		self.promptForCommentWhenStoppingTime = [s_promptForComment boolValue];
	}
	
	
	NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
	NSLog(@"URL: %@", url);
	if ([url isFileURL]) {
		// Handle file being passed in
		//get data from URL
		NSData* d = [NSData dataWithContentsOfURL:url];
		//invoke the import logic
		[self importProjectFromData:d];
	}
	else {
		// Handle custom URL scheme
		//Done in the application:handleUrl method?
	}
	
	
	return TRUE;
		
	
	//TODO Testcode wieder entfernen
//	NSURL* url = [NSURL URLWithString:@"mytimes://mytimes?importsource=http%3A%2F%2Fiphone.anteboth.com%2Fmytimes%2Fxml%2Fmytimes-export.xml"];	
//	NSString* surl = @"mytimes://importdata=PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPERhdGEgeG1sbnM9Im15dGltZXMiCXhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhzaTpzY2hlbWFMb2NhdGlvbj0ibXl0aW1lcyBodHRwOi8vaXBob25lLmFudGVib3RoLmNvbS9teXRpbWVzL3htbC9teXRpbWVzLW1vZGVsLnhzZCI+CjxQcm9qZWN0IG5hbWU9ImZ0NDIiIGRlc2NyaXB0aW9uPSIiPgo8VGFzayBuYW1lPSJGdW5jdGlvbiA0MiIgZGVzY3JpcHRpb249IiI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMTVUMTM6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjcwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJCZXNwcmVjaHVuZyBtaXQgRGFubnkgdW5kIFRob3JzdGVuIGJ6Z2wgUkUgUGVyZm9tYW5jZSBNZXNzdW5nIGluIFdPQiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA2LTA5VDE0OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iRWRpdG9yIEZlaGxlciBNZWV0aW5nIi8+CjwvVGFzaz4KPFRhc2sgbmFtZT0iTWVldGluZyIgZGVzY3JpcHRpb249IiI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDUtMDRUMTU6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iOTAwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPC9UYXNrPgo8VGFzayBuYW1lPSJUZWFtbWVldGluZyIgZGVzY3JpcHRpb249IiI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMDVUMTA6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNTQwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNS0xOFQxMDozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTA0VDEwOjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjI3MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjwvVGFzaz4KPFRhc2sgbmFtZT0iRWluYXJiZWl0dW5nIiBkZXNjcmlwdGlvbj0iIj4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNS0xMVQwOTozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI1NDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IkVkaXRvciIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTA2VDA4OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI3OTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249ImVkaXRvciIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTA1VDA5OjAwOjAwIiBwYXVzZT0iMjcwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTA0VDEwOjQ1OjAwIiBwYXVzZT0iMjcwMCIgZHVyYXRpb249IjEyNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTA0VDA4OjE1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjYzMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjwvVGFzaz4KPFRhc2sgbmFtZT0idGVzdDQydmRzIFNjaG5pdHRzdGVsbGUiIGRlc2NyaXB0aW9uPSIiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA3LTIxVDA5OjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA3LTIxVDA5OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iRmFocnplaXQiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0zMFQwODo0NTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI4MTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249InRlc3QgYXVmIGl0c3QgdW5kIEFucGFzc3VuZyBFeHBvcnRmb3JtYXQiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0wOVQxNDozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IklUU1QgVGVzdGVuLiBkZXIgSW1wb3J0ZnVua3Rpb24gZ2VnZW4gZ2XDpG5kZXJ0ZSBXUyBVUkwiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0wOFQxMDowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI1NDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTI1VDE1OjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE0NDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTI1VDE0OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjI3MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iQmVzcHJlY2h1bmcgbWl0IFRhdGphbmEiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNS0yNVQwOToxMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI0ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IsOcYmVybmFobWUgZGVyIMOEbmRlcnVuZ2VuIGF1cyBXT0IiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNS0yMFQwOTowMDowMCIgcGF1c2U9IjE4MDAiIGR1cmF0aW9uPSIzMjQwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJidWdmaXhpbmciLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNS0xOVQxNzozNTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxNTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlZvcmJlcmVpdHVuZyBmw7xyIEVpbnNhdHogaW4gV29iIi8+CjwvVGFzaz4KPFRhc2sgbmFtZT0iRWRpdG9yIEFQSSIgZGVzY3JpcHRpb249IiI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDktMDlUMTE6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMzYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJBdHRyaWJ1dGUgaW0gb2ZmbGluZSBFZGl0b3IgdmVyYmVzc2VydCIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA5LTA5VDA5OjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjU0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iRXh0ZXJuZSBCaWxkZXIgdW5kIE9MRSBPYmpla3RlIGltIEVkaXRvciBLb256ZXB0aW9uIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMTdUMDk6MDA6MDAiIHBhdXNlPSI5MDAiIGR1cmF0aW9uPSIzMDYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0xNlQwODozMDowMCIgcGF1c2U9IjE4MDAiIGR1cmF0aW9uPSIzMDYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJPZmZsaW5lIEFQSSIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA2LTE1VDE2OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjYzMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iUklGIEludGVncmF0aW9uIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMTVUMTM6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNjMwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0xNVQwOTo0NTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI5OTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlJJRiBTY2huaXR0c3RlbGxlIGbDvHIgT2ZmbGluZSBBUEkgYW5iaW5kZW4iLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0xMlQwODo0NTowMCIgcGF1c2U9IjkwMCIgZHVyYXRpb249IjI1MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlJpZiBTY2huaXR0c3RlbGxlIGbDvHIgT2ZmbGluZUVkaXRvciBhbmJpbmRlbiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA2LTExVDEyOjMwOjAwIiBwYXVzZT0iMjcwMCIgZHVyYXRpb249IjE3MTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249Ik9mZmxpbmUgRWRpdG9yIFJpZiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA2LTExVDA5OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjM2MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMTBUMTA6MzA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjM0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMTBUMDk6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMzYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJNZWV0aW5nIG1pdCBULkhvZmZtYW5uIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMTBUMDg6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMzYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0wOVQxNjowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249Ik5hY2hiZXJlaXR1bmcgRWRpdG9yIFJJRiBNZWV0aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMDlUMTE6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTA4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iRWRpdG9yIFJJRiBNZWV0aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMDlUMTA6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJWb3JiZXJlaXR1bmcgRWRpdG9yIFJJRiBNZWV0aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMDlUMDg6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNzIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0wOFQxMTozMDowMCIgcGF1c2U9IjE4MDAiIGR1cmF0aW9uPSIyNTIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0wNVQxMjo0NTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIyMDcwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0wNVQwOTozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA2LTA0VDEwOjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI3MDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA2LTA0VDA5OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMDNUMTE6MDA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjM0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMDJUMTE6MzA6MDAiIHBhdXNlPSI5MDAiIGR1cmF0aW9uPSIxODkwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJvZmZsaW5lIEFQSSIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA2LTAyVDA5OjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjcyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iUkFEIElERSByZXBhcmllcmVuIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDUtMjZUMDc6MDA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMzQyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDUtMjVUMTA6MzA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMTM1MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDUtMTlUMDg6MzA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMzI0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDUtMThUMTE6MzA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMTk4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iU2VydmVyIEFQSSwgU3RhbmRhbG9uZSBjbGllbnQgUHJvdG90eXAiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNS0xOFQwOTozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlNlcnZlciBBUEksIENsaWVudCBQcm90b3R5cCIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTE1VDA4OjMwOjAwIiBwYXVzZT0iMjcwMCIgZHVyYXRpb249IjI3MDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249Im5ldWVzIEVKQiBQcm9qZWt0IGbDvHIgRWRpdG9yIEFQSSBlaW5yaWNodGVuIHVuZCBUZXN0cHJvamVrdCBhbmxlZ2VuIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDUtMTRUMTk6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNTQwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJXU0FEIGluc3RhbGxpZXJlbiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTE0VDA5OjAwOjAwIiBwYXVzZT0iOTAwIiBkdXJhdGlvbj0iMjQzMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iV1NBRCBpbnN0YWxsaWVyZW4gdXN3LiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTEzVDEzOjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE2MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTEzVDExOjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjU0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iTWVldGluZyIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA1LTEzVDA5OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjcyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDUtMTJUMDg6MzA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjk3MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDUtMTFUMTE6NDU6MDAiIHBhdXNlPSI5MDAiIGR1cmF0aW9uPSIyMTYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNS0wOFQxMDowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIyNDMwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPC9UYXNrPgo8VGFzayBuYW1lPSJSb2xsZW5kZXIgRWRpdG9yIiBkZXNjcmlwdGlvbj0iIj4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0wM1QwOTowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI3MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IsOEbmRlcnVuZ3NhbnplaWdlIHZlcmJlc3NlcnQiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNS0xMVQxMTowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIyNzAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IkJlc3ByZWNodW5nOiBBdWZnYWJlbnZlcnRlaWx1bmciLz4KPC9UYXNrPgo8VGFzayBuYW1lPSJVbXN0ZWxsdW5nIEFQRiIgZGVzY3JpcHRpb249IiI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDktMDdUMDk6MzA6MDAiIHBhdXNlPSI5MDAiIGR1cmF0aW9uPSIyODgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJUYWJsZSB1bmQgRmlsdGVyIEtvbnplcHQgYW4gQVBGL3N5czQyIGFucGFzc2VuIi8+CjwvVGFzaz4KPFRhc2sgbmFtZT0iU2lnbmFsZSAmYW1wOyBQYXJhbWV0ZXIiIGRlc2NyaXB0aW9uPSIiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA5LTA5VDEyOjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4OTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IkVpbmFyYmVpdHVuZyIvPgo8L1Rhc2s+CjwvUHJvamVjdD4KPFByb2plY3QgbmFtZT0iS1BNIiBkZXNjcmlwdGlvbj0iKG51bGwpIj4KPFRhc2sgbmFtZT0iUmVsZWFzZSA0YSIgZGVzY3JpcHRpb249IiI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMzBUMDk6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjE2MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMjlUMDk6MTU6MDAiIHBhdXNlPSI5MDAiIGR1cmF0aW9uPSIyNzkwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJidWdmaXhpbmciLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNC0yOFQwODo0NTowMCIgcGF1c2U9IjkwMCIgZHVyYXRpb249IjMwNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249ImJ1Z2ZpeGluZyIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA0LTI3VDA5OjMwOjAwIiBwYXVzZT0iOTAwIiBkdXJhdGlvbj0iMjc5MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMjRUMDg6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjc5MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMjNUMDk6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMzA2MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMjJUMDg6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMzE1MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMjFUMDk6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjg4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMjBUMDk6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjg4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMTdUMDk6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjQzMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMTZUMDk6MTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjc5MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMTVUMDk6MzA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjc5MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMTRUMTA6MDA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjk3MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMDlUMDg6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjI1MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMDhUMDk6MDA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjg4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iQnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMDdUMDk6MTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjc5MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMDZUMDk6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjM0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMDNUMDk6MDA6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjM0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMDJUMDg6NDU6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjg3NDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iYnVnZml4aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDQtMDFUMDg6NDU6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjYxMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDMtMzFUMTI6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTQ0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDMtMzFUMDg6MTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTQ0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDMtMzBUMDk6MzA6MDAiIHBhdXNlPSI5MDAiIGR1cmF0aW9uPSIzMjQwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJidWdmaXhpbmcsICBUZWlsZWFuc2ljaCBpbiBQLCAgVm9yIFp1csO8Y2sgRmVhdHVyZSIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTI3VDA4OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjI2OTQwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IkJ1Z2ZpeGluZywgQWxhIFBsdWdpbiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTI2VDA5OjE1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjI3OTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249ImJ1Z2ZpeGluZyIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTI1VDA5OjMwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTI0VDA5OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI3ODQwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlRlaWxlIGluIHAgIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDMtMThUMDk6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjUyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iUHJvYmxlbcO8YmVyZ2FiZWF1ZnRyYWcgUCAtJmd0OyBIYWxsZSBBbnBhc3N1bmcgVGVpbGUgaW4gUCIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTE3VDA5OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI3OTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlRlaWxlIGluIFAgw7xiZXJhcmJlaXRldCIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTE2VDA5OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI3OTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlRlaWxlIGluIFAgw7xiZXJhcmJlaXRldCIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTEzVDA4OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4NzQwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlRlaWwgaW4gUCBIb3N0bWFza2UiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMy0xMlQwODo0NTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIyNTIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJUZWlsIGluIFAgSG9zdDJSaWNoQ2xpZW50IE1hc2tlbiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTExVDA5OjE1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI5NzAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlRlaWxlbWFza2UgaW4gUCIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTEwVDA4OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjMxNTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTA5VDA5OjMwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjMwNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTA2VDA5OjE1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI5NzAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTA1VDA5OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI5NzAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTA0VDA4OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjI3OTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IsOcYmVyZ2FiZWF6ZnRyYWcgUC1IYWxsZSIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAzLTAzVDA5OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlByb2JsZW3DvGJlcm5haG1lIEhhbGxlLVAiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMy0wMlQxMDowMDowMCIgcGF1c2U9IjE4MDAiIGR1cmF0aW9uPSIyNzAwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0yN1QwOToxNTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIyNTE0MCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0yNlQwOTowMDowMCIgcGF1c2U9IjE4MDAiIGR1cmF0aW9uPSIzMTUwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0yNVQwOTozMDowMCIgcGF1c2U9IjE4MDAiIGR1cmF0aW9uPSIzMDYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPC9UYXNrPgo8VGFzayBuYW1lPSJGYWhydGVuIiBkZXNjcmlwdGlvbj0iKG51bGwpIj4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0xOFQwODozOTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxNTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTEyVDE4OjA1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMTJUMDg6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0xMVQxODoxNTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTExVDA4OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMTBUMTY6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0xMFQwODo0NTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTA5VDE2OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMDlUMDk6MTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0wN1QxNjowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTA3VDA5OjQwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjEyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMDZUMTg6MTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0wNlQwODo0NTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTA1VDA4OjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMDRUMDg6NDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0wM1QxOToxNTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTAzVDA4OjM1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE1MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMDJUMTA6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0zMFQxNjozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTMwVDA4OjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMjlUMTk6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yOVQwOToxNTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTI4VDE4OjE1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMjhUMDk6MTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yN1QxODowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTI3VDA4OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMjZUMTg6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yNlQwOTowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTIzVDE2OjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjI3MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMjNUMDc6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTUwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yMlQxNzo1MDowMCIgcGF1c2U9IjYwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yMlQwOTowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxMjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTIxVDE3OjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMjFUMDk6MDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTUwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yMFQxNzo0NTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTIwVDA5OjIwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE1MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMTlUMTc6MTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTUwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0xOVQwOToyMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxMjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8L1Rhc2s+CjxUYXNrIG5hbWU9IkJ1Z2ZpeGluZyIgZGVzY3JpcHRpb249IihudWxsKSI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMjRUMDk6NDU6MDAiIHBhdXNlPSIxODAwIiBkdXJhdGlvbj0iMjY5NDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMjNUMDk6MDA6MDAiIHBhdXNlPSI2MCIgZHVyYXRpb249IjIzMjgwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTIwVDA4OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE4MDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTE4VDA4OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI3MDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTE3VDA5OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI5NzAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTEzVDA5OjE1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI1MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTEyVDA5OjE1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI5NzAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTExVDA5OjE1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjMwNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTEwVDA5OjE1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI1MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTA5VDA5OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjIzNDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTA3VDEwOjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjE5ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTA2VDA5OjE1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjMwNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTA1VDA5OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI5NzAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTA0VDA5OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjMyNDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTAzVDA5OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjM1MTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTAyVDEwOjMwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTMwVDA5OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI1MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTI5VDA5OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjMxNTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTI4VDA5OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTI3VDA5OjE1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTI2VDA5OjMwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTIzVDA4OjEwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTIyVDA5OjIwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTIxVDA5OjMwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI3MDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTIwVDEwOjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTE5VDA5OjQ1OjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI1MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8L1Rhc2s+CjxUYXNrIG5hbWU9IkFQRiBNaWdyYXRpb24iIGRlc2NyaXB0aW9uPSIiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTIwVDEzOjMwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249Ijk5MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjwvVGFzaz4KPFRhc2sgbmFtZT0iQ2l0cml4IFNlcnZlciBDb25maWciIGRlc2NyaXB0aW9uPSIiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTE5VDA5OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjI4ODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8L1Rhc2s+CjwvUHJvamVjdD4KPFByb2plY3QgbmFtZT0ibXlUaW1lcyBQcm9qZWt0IiBkZXNjcmlwdGlvbj0iKG51bGwpIj4KPFRhc2sgbmFtZT0iRW50d2lja2x1bmciIGRlc2NyaXB0aW9uPSIobnVsbCkiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA5LTI3VDE0OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjcyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDktMjZUMTU6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTI2MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDktMDZUMTE6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNzIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wOC0yOFQxNDowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI5MDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA4LTI4VDEwOjAwOjAwIiBwYXVzZT0iOTAwIiBkdXJhdGlvbj0iOTkwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJFeHBvcnQgV29ya3VuaXQtTWFza2UiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0xNFQxNDozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxNDQwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0xM1QyMjozMDowMCIgcGF1c2U9IjMxMjAiIGR1cmF0aW9uPSI4MzQwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAyLTEzVDE5OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjM2MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMjRUMTY6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNTEwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yM1QyMTowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxMjYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJDU1YgTWFpbCBFeHBvcnQgdW1nZXNldHp0Ii8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMjJUMjA6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNzIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yMVQxOTowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI5MDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTIwVDE5OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjU0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDEtMThUMTM6MDA6MDAiIHBhdXNlPSIzNjAwIiBkdXJhdGlvbj0iMzI0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjwvVGFzaz4KPFRhc2sgbmFtZT0iS29uemVwdGlvbiIgZGVzY3JpcHRpb249IihudWxsKSI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDktMjZUMTI6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNzIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yMFQyMTowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI1NDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTE3VDE0OjE1OjAwIiBwYXVzZT0iMzYwMCIgZHVyYXRpb249IjE0NDAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8L1Rhc2s+CjxUYXNrIG5hbWU9IkhvbWVwYWdlIiBkZXNjcmlwdGlvbj0iIj4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yM1QxMDowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IkhvbWVwYWdlIEtvbnplcHRpb24gdW5kIEluZnJhc3RydWt0dXIiLz4KPC9UYXNrPgo8VGFzayBuYW1lPSJLYWxlbmRlciBLb21wb25lbnRlIiBkZXNjcmlwdGlvbj0iIj4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0wOVQyMDowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxMDgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMi0wOFQxMzowMDowMCIgcGF1c2U9IjM2MDAiIGR1cmF0aW9uPSIxODAwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0zMVQxMzowMDowMCIgcGF1c2U9IjE4MDAiIGR1cmF0aW9uPSIxMDgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yMVQyMTozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8L1Rhc2s+CjxUYXNrIG5hbWU9IkJ1Z2ZpeGluZyIgZGVzY3JpcHRpb249IihudWxsKSI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDMtMDFUMTQ6MTA6MDAiIHBhdXNlPSI3MjAwIiBkdXJhdGlvbj0iMTc0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDItMTlUMTk6MTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNzIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wMS0yNFQxODowMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI3MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTE5VDE4OjAwOjAwIiBwYXVzZT0iMTgwMCIgZHVyYXRpb249IjU0MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjwvVGFzaz4KPFRhc2sgbmFtZT0iSWNvbnMiIGRlc2NyaXB0aW9uPSIiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTE4VDExOjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjM2MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjwvVGFzaz4KPC9Qcm9qZWN0Pgo8UHJvamVjdCBuYW1lPSJTb25zdGlnZXMiIGRlc2NyaXB0aW9uPSIiPgo8VGFzayBuYW1lPSJTb3BoaWVzIExhYm9yYXVmZ2FiZW4iIGRlc2NyaXB0aW9uPSIiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTAxLTI0VDEzOjAwOjAwIiBwYXVzZT0iMjcwMCIgZHVyYXRpb249IjE1MzAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8L1Rhc2s+CjxUYXNrIG5hbWU9IlRlc3QiIGRlc2NyaXB0aW9uPSIiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA5LTA2VDEyOjU4OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjcyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDktMDVUMTA6NTU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMzYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wOS0wMlQxODo0NjowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI3MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA5LTAxVDAwOjI3OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjE1MTUwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wOC0yN1QxNToxMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI5MzYwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wOC0xOVQxODozNjowMCIgcGF1c2U9IjcyMCIgZHVyYXRpb249IjAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDgtMTlUMTg6MzY6MDAiIHBhdXNlPSI1NDAiIGR1cmF0aW9uPSI2MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDgtMTlUMDc6NTA6MDAiIHBhdXNlPSIzNDIwMCIgZHVyYXRpb249IjQyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDgtMTVUMTg6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNzIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wOC0wNVQxODo0NTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSI3MjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA3LTIzVDE4OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjcyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMTNUMTQ6NDA6MDAiIHBhdXNlPSI1ODAyMTgwIiBkdXJhdGlvbj0iNDIwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA4LTEyLTIxVDE4OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjcyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDgtMDgtMjRUMTg6NDU6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNzIwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPC9UYXNrPgo8L1Byb2plY3Q+CjxQcm9qZWN0IG5hbWU9IkRBVklEIiBkZXNjcmlwdGlvbj0iIj4KPFRhc2sgbmFtZT0iQWxsZ2VtZWluIiBkZXNjcmlwdGlvbj0iIj4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0wNi0xNVQxNTozMDowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIxODAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IlNRTCBCaW5kaW5ncyBNZWV0aW5nIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMDYtMDRUMDk6MzA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMTgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSJYc2x0IEJlc3ByZWNodW5nIG1pdCBPbGl2ZXIiLz4KPC9UYXNrPgo8L1Byb2plY3Q+CjxQcm9qZWN0IG5hbWU9Im1vZGVsaXNhciIgZGVzY3JpcHRpb249IiI+CjxUYXNrIG5hbWU9Ik1lZXRpbmciIGRlc2NyaXB0aW9uPSIiPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTA2LTExVDEwOjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjkwMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjwvVGFzaz4KPC9Qcm9qZWN0Pgo8UHJvamVjdCBuYW1lPSJ0ZXN0IiBkZXNjcmlwdGlvbj0iIj4KPFRhc2sgbmFtZT0idGVzdCIgZGVzY3JpcHRpb249IiI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMTEtMDVUMTQ6MzU6MDAiIHBhdXNlPSI2MCIgZHVyYXRpb249IjMxOTgwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTEwLTAyVDE5OjAwOjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjcyMDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjwvVGFzaz4KPC9Qcm9qZWN0Pgo8UHJvamVjdCBuYW1lPSJNYXUgTWF1IiBkZXNjcmlwdGlvbj0iIj4KPFRhc2sgbmFtZT0iRW50d2lja2x1bmcgLSBQcm90b3R5cCIgZGVzY3JpcHRpb249IiI+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMTAtMTZUMjA6MDA6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iMjcwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0xMC0xNVQxOTowMDowMCIgcGF1c2U9IjE4MDAiIGR1cmF0aW9uPSIxMDgwMCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0xMC0xM1QxOToxNTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzNjAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8V29ya1VuaXQgc3RhcnRUaW1lPSIyMDA5LTEwLTExVDE3OjQ1OjAwIiBwYXVzZT0iMCIgZHVyYXRpb249IjQ1MDAiIHJ1bm5pbmc9ImZhbHNlIiBjaGFyZ2VhYmxlPSJ0cnVlIiBkZXNjcmlwdGlvbj0iIi8+CjxXb3JrVW5pdCBzdGFydFRpbWU9IjIwMDktMTAtMTFUMTU6NDM6MDAiIHBhdXNlPSIwIiBkdXJhdGlvbj0iNjM2MCIgcnVubmluZz0iZmFsc2UiIGNoYXJnZWFibGU9InRydWUiIGRlc2NyaXB0aW9uPSIiLz4KPFdvcmtVbml0IHN0YXJ0VGltZT0iMjAwOS0xMC0xMVQxMzoxNTowMCIgcGF1c2U9IjAiIGR1cmF0aW9uPSIzOTAwIiBydW5uaW5nPSJmYWxzZSIgY2hhcmdlYWJsZT0idHJ1ZSIgZGVzY3JpcHRpb249IiIvPgo8L1Rhc2s+CjwvUHJvamVjdD4KPC9EYXRhPg==";
//	NSURL* url = [NSURL URLWithString:surl];
//	[self application:(UIApplication*)self handleOpenURL:url];		
}

#pragma mark -


-(void) reselectActiveEntries {
	//TODO reload the last seen element (project and project task)
	//find the active element
	for (Project* p in self.data) {
		for (ProjectTask* pt in p.tasks) {
			for (TimeWorkUnit* wu in pt.workUnits) {
				if (wu.running) {
					projectToLoadAtStartup = p;
					taskToLoadAtStartup = pt;
					workUnitToLoadAtStartup = wu;
				}
			}
		}
	}
	
}


//stop all running work units excep the given one
-(void) stopAllOtherWorkUnitsExcept:(TimeWorkUnit*)workUnit {
	for (Project* p in self.data) {
		for (ProjectTask* pt in p.tasks) {
			for (TimeWorkUnit* wu in pt.workUnits) {
				if (wu.running && wu != workUnit) {
					[wu stopTimeTracking];
				}
			}
		}
	}
	[self.currentTableView reloadData];
}

-(void) saveData {
	NSLog(@"Save data...");
	// Save data to user defaults
	[[NSUserDefaults standardUserDefaults] 
		setObject:[NSKeyedArchiver archivedDataWithRootObject:self.data]
		forKey:@"taskTrackerData"];
	[[NSUserDefaults standardUserDefaults] 
		setObject:[NSKeyedArchiver archivedDataWithRootObject:self.dataEntryDefinitions]
		forKey:@"taskTrackerDataEntryDefinitions"];

	//sync data is needed here
	[[NSUserDefaults standardUserDefaults] synchronize];
		
	NSLog(@"Data saved!");
	
	/* SAVE THE BACKUP FILE */
	NSLog(@"Store data in file");

	//create a NSData object from the internal data model
	NSData* dataToSave = [NSKeyedArchiver archivedDataWithRootObject:self.data];
	
	// Get path to documents directory
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		// Path to save the data
		//TODO implement an option to backup rolling files (e.g. the last 5 backups or so, or per day)
		NSString  *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"mytimes-backup.mtb"];
		NSLog(@"%d bytes will be written to file.", [dataToSave length]);
		//write the data
		[dataToSave writeToFile:filePath atomically:YES];
		
		// Read data back from file
		//NSData* dataFromFile = [NSData dataWithContentsOfFile:filePath];		
		//NSLog(@"%d bytes of data read from file.", [dataFromFile length]);
	}
	
}


- (void)dealloc {
	[projectToLoadAtStartup release];
	[taskToLoadAtStartup release];
	[workUnitToLoadAtStartup release];
	[currentTableView release];
	[rootViewController release];
	[editingProject release];
	[navigationController release];
	[window release];
	[data release];
	[tabBarController release];
	[addItemController release];
	[dateFormatter release];
	[timeFormatter release];
	[defaultStartTime release];
	[defaultEndTime release];
	[dataEntryDefinitions release];
	[dataToRestore release];
	[restoreFilePath release];
    [self.importFile release];
	[super dealloc];
}

@end
