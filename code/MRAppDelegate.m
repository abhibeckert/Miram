//
//  MRAppDelegate.m
//  Miram
//
//  Created by Abhi Beckert on 2012-11-3.
//  This is free and unencumbered software released into the public domain.
//

#import "MRAppDelegate.h"
#import "MRLogViewController.h"

@interface MRAppDelegate()

@property (retain) NSOperationQueue *taskQueue;
@property (retain) NSTimer *rsyncBackupTimer;
@property (retain) MRRamDisk *ramDisk;

@end

@implementation MRAppDelegate

- (id)init
{
  if (!(self = [super init]))
    return nil;
  
  self.taskQueue = [[NSOperationQueue alloc] init];
  self.taskQueue.maxConcurrentOperationCount = 1;
  
  self.rsyncBackupTimer = nil;
  
  self.ramDisk = [[MRRamDisk alloc] initWithLocalPath:@"~/co"];
  
  return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  NSDate *createStartDate = [NSDate date];
  
  [self.taskQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
    dispatch_sync(dispatch_get_main_queue(), ^{
      [MRLogViewController log:@"creating ram disk...\n"];
    });
    
    [self.ramDisk create];
    [self.ramDisk mirrorFromLocal];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
      [MRLogViewController log:@"\n\n\nMiram is ready.\n\n\n"];
      
      // post notification
      NSUserNotification *notification = [[NSUserNotification alloc] init];
      notification.title = [NSString stringWithFormat:@"%@ is ready for use", self.ramDisk.volumeName];
      notification.informativeText = [NSString stringWithFormat:@"RAM disk created in %i seconds", abs([createStartDate timeIntervalSinceNow])];
      [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
      
      self.rsyncBackupTimer = [NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(rsyncBackup:) userInfo:nil repeats:YES];
    });
  }]];
}

- (void)rsyncBackup:(id)sender
{
  // only do an rsync backup if we are idle
  if (self.taskQueue.operationCount > 0) {
    return;
  }
  
  [self.taskQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
    dispatch_sync(dispatch_get_main_queue(), ^{
      [MRLogViewController log:@"creating hdd backup...\n"];
    });
    
    // do rsync
    NSUInteger numberOfFilesSynced = [self.ramDisk mirrorToLocal];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
      [MRLogViewController log:[NSString stringWithFormat:@"done hdd backup (%@)\n\n\n", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]]];
      
      if (numberOfFilesSynced > 0) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = [NSString stringWithFormat:@"Backed up %@", self.ramDisk.volumeName];
        notification.informativeText = [NSString stringWithFormat:@"%i items were copied to HDD", (int)numberOfFilesSynced];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
      }
    });
  }]];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
  [self.taskQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
    dispatch_sync(dispatch_get_main_queue(), ^{
      [MRLogViewController log:@"stopping Miram...\n"];
      
      NSUserNotification *notification = [[NSUserNotification alloc] init];
      notification.title = [NSString stringWithFormat:@"Creating final backup of %@...", self.ramDisk.volumeName];
      [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    });
    
    [self.ramDisk mirrorToLocal];
    [self.ramDisk destroy];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
      NSUserNotification *notification = [[NSUserNotification alloc] init];
      notification.title = [NSString stringWithFormat:@"%@ has been removed", self.ramDisk.volumeName];
      [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
      
      [NSApp replyToApplicationShouldTerminate:YES];
    });
  }]];
  
  return NSTerminateLater;
}


@end
