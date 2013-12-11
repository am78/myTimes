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
#import "NSArray+Filter.h"
#import <dropbox/dropbox.h>

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
@synthesize filterType;

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

- (void) handleDropboxUrl:(NSURL*) url
{
    //open dropbox callback url?
    //and get linked account
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
        NSLog(@"App linked successfully!");
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
/*
    [self handleDropboxUrl:url];
    return YES;
}

//open an URL at startup, until now only import of XML data by opening mytimes with a specific url is supported
//url format: mytimes//?importdata=<base64 encoded xml data>
//or mytimes://?importsource=<URL to XML file>
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
*/
    if (!url) {  return NO; }
    
    [self handleDropboxUrl:url];
    
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
	
    NSString *strData = [[NSString alloc]initWithData:xmlData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", strData);
    
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


- (void)importFromMtbFile:(BOOL)addProjects myData:(NSData *)myData {
    //add the projects as new ones, don't keep the old ones
    if (!addProjects) {
        [self.data removeAllObjects];
    }
    
    NSArray* importedProjects = [NSKeyedUnarchiver unarchiveObjectWithData:myData];
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
            else {
                if (myData) {
                    //import data from MTB data
                    if ([[self.importFile pathExtension] isEqualToString:@"mtb"]) {
                        [self importFromMtbFile:addProjects myData:myData];
                    }
                    else {
                        //import from XML data
                        [self importFromXMLData:myData addAsNewProjects:addProjects];
                    }
                }
            }
            
            //set filename to nil
            self.importFile = nil;
            
        }
	} 
}

#pragma mark - get data filtered


- (NSMutableArray*) getDataFiltered:(DataFilterType) aFilterType
{
    if (aFilterType == FilterType_Unfiltered) return self.data;
    
    NSArray * filteredArray = [self.data filteredArrayUsingBlock:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        Project* p = obj;
        return [p matchFilter:aFilterType];
    }];
    
    return (NSMutableArray*) filteredArray;
}

#pragma mark - Application Life Cycle

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

    //dropbox initialization
    DBAccountManager* accountMgr = [[DBAccountManager alloc] initWithAppKey:@"h1a0x2byko52new" secret:@"r7dou6ojz872207"];
    [DBAccountManager setSharedManager:accountMgr];
    DBAccount *account = accountMgr.linkedAccount;
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
    }
    
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
    //	NSData* dataToSave = [NSKeyedArchiver archivedDataWithRootObject:self.data];

    //get XML data
    NSString* xml = [XMLHelper getAllXmlData:self.data];
    NSData* dataToSave = [xml dataUsingEncoding:NSUTF8StringEncoding];
    
    // Path to save the data
	NSString  *filePath = [self getDataFilePath];
	NSString  *tmpFilePath = [[self getDataFilePath] stringByAppendingString:@".TMP"];

    //write the data
    [dataToSave writeToFile:tmpFilePath atomically:YES];
	
	//compare file
    //only store to backup file if data is changed
    BOOL changed = ![[NSFileManager defaultManager] contentsEqualAtPath:filePath andPath:tmpFilePath];
    if (changed)
    {
        NSLog(@"%d bytes will be written to file.", [dataToSave length]);
        [dataToSave writeToFile:filePath atomically:YES];
        
        //sync changed to dropbox
        [self.rootViewController syncChanges:dataToSave];
    }
		// Read data back from file
		//NSData* dataFromFile = [NSData dataWithContentsOfFile:filePath];		
		//NSLog(@"%d bytes of data read from file.", [dataFromFile length]);
		
}

- (NSString*) getDataFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		// Path to save the data
		//TODO implement an option to backup rolling files (e.g. the last 5 backups or so, or per day)
		NSString  *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"mytimes.xml"];
        return filePath;
    }
    return nil;
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
