//
//  SyncManager.m
//  TaskTracker
//
//  Created by Michael Anteboth on 06.06.13.
//
//

#import "SyncManager.h"
#import "TaskTrackerAppDelegate.h"
#import "XmlParser.h"

@implementation SyncManager


- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) startObserver
{
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    if (account) {   //account already linked, file not yet initialized
        //get file system handle
        DBFilesystem *fs = [DBFilesystem sharedFilesystem];
        //create filePath
        DBPath *filePath = [[DBPath root] childPath:@"mytimes.xml"];
        DBError* error = nil;
        
        //open file, already existing
        self.file = [fs openFile:filePath error:nil];
        //needs to be created cause not yet existing
        if (!self.file) {
            NSLog(@"Create mytimes.xml");
            //create file if not existing
            self.file = [fs createFile:filePath error:&error];
            if (error) { //stop on error
                NSLog(@"Error creating file: %@", [error localizedDescription]);
            }
            else {
                //start initial export
                [self export:self.file];
            }
        }

    } else {
        NSLog(@"Account not linked.");
        return;
    }
    
    if (!self.file) {
        NSLog(@"file is null, maybe dropbox not linked yet.");
    }
    else
    {
        NSLog(@"StartObserver");    
        // Next, register for changes on that file.
        [self.file addObserver:self block:^{
            DBFileStatus* status = self.file.newerStatus;
            
            // If file.NewerStatus is null, the file hasn't changed.
            if (status == nil) {
                return;
            }
            
            if (status.cached)
            {
                DBError* error = nil;
                [self.file update:&error];
                if (error) {
                    NSLog(@"Error updating remove file. Error: %@", [error localizedDescription]);
                }
                else
                {
                    NSLog(@"The updated file has finished downloading");
                    
                    //import changes to local Datastore
                    [self import:self.file];
                }
            }
            else
            {
                NSLog(@"The file is still downloading");
            }

        }];
    }
}


- (void) removeObserver
{
    //remove file observer
    [self.file removeObserver:self];
}

- (void) initSync:(UIViewController*) rootController
{
    NSLog(@"link account");
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    if (!account) {
        //link to account if required
        [[DBAccountManager sharedManager] linkFromController:rootController];
    }
}

- (void) unlinkAccount
{
    NSLog(@"Unlink account");
    [[DBAccountManager sharedManager].linkedAccount unlink];
}

- (void) syncChanges:(NSData *)data
{
    DBError* error = nil;
    if (self.file && data) {
        BOOL ok = [self.file writeData:data error:&error];
        if (!ok) {//there was an error
            NSLog(@"Error writing changes: %@", [error localizedDescription]);
        }
        else { //no error
            NSLog(@"Changes written!");
        }
    }
}

- (void) export:(DBFile*) file
{
    NSLog(@"export");

    //Marshal XML data
    TaskTrackerAppDelegate* appDel = (TaskTrackerAppDelegate*) [UIApplication sharedApplication].delegate;
    NSString* xml = [XMLHelper getAllXmlData:appDel.data];
    NSData* data = [xml dataUsingEncoding:NSUTF8StringEncoding];
    DBError* error = nil;
    
    //write data
    BOOL ok = [file writeData:data error:&error];
    if (!ok) { //there was an error
        if (error) NSLog(@"Error exporting file: %@", [error localizedDescription]);
    }
    else { //no error
        NSLog(@"File exported successfully.");
    }
}

- (void) import:(DBFile*) file
{
    NSLog(@"Import");
    //TODO: ask to Delete local and import remote data
    
    //read data from file
    DBError* error = nil;
    NSData* xmlData = [file readData:&error];
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    if (!xmlData) {
        NSLog(@"no xml data");
    }
    
    //Unmarshal XML data and get objects
    XmlParser* p = [[XmlParser alloc] init];
    NSMutableArray* parsed = [p parseFromXmlData:xmlData];
    
    //set data in app delegate
    TaskTrackerAppDelegate* appDel = (TaskTrackerAppDelegate*) [UIApplication sharedApplication].delegate;
    appDel.data = parsed;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        appDel.rootViewController.data = parsed;
        //Reload main table view
        [appDel.rootViewController.tableView reloadData];
    }];

    
    //persist changes
    [appDel saveData];
}


@end
