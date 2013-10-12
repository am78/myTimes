//
//  SyncManager.h
//  TaskTracker
//
//  Created by Michael Anteboth on 06.06.13.
//
//

#import <Foundation/Foundation.h>
#import <Dropbox/Dropbox.h>

@interface SyncManager : NSObject

@property (nonatomic, retain) DBFile* file;

- (void) initSync:(UIViewController*) rootController;
- (void) unlinkAccount;
- (void) startObserver;
- (void) removeObserver;
- (void) syncChanges:(NSData*)data;

@end
