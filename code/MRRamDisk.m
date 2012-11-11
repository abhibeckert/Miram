//
//  MRRamDisk.m
//  Miram
//
//  Created by Abhi Beckert on 2012-11-4.
//  This is free and unencumbered software released into the public domain.
//

#import "MRRamDisk.h"
#import "MRLogViewController.h"

@interface MRRamDisk ()

@property (retain) NSString *localPath;
@property (retain) NSString *device;
@property (retain) NSString *mountPath;
@property (retain) NSString *volumeName;

@end

@implementation MRRamDisk

- (id)init
{
  @throw [NSException exceptionWithName:@"cannot use init method. use designated initializer instead" reason:nil userInfo:nil];
}

- (id)initWithLocalPath:(NSString *)localPath
{
  if (!(self = [super init]))
    return nil;
  
  self.device = nil;
  self.volumeName = [localPath lastPathComponent];
  self.localPath = [[localPath stringByStandardizingPath] stringByResolvingSymlinksInPath];
  
  return self;
}

- (void)create
{
  // create device, format it, and mount it
  self.device = [self run:@"/usr/bin/hdiutil" args:[NSArray arrayWithObjects:@"attach", @"-nomount", @"ram://2000000", nil] logOutput:YES];
  [self run:@"/usr/sbin/diskutil" args:[NSArray arrayWithObjects:@"quiet", @"erasevolume", @"HFS+", self.volumeName, self.device, nil] logOutput:YES];
  
  // find mount point
  NSString *disksPlistString = [self run:@"/usr/sbin/diskutil" args:[NSArray arrayWithObjects:@"list", @"-plist", nil] logOutput:NO];
  NSDictionary *disks = [NSPropertyListSerialization propertyListWithData:[disksPlistString dataUsingEncoding:NSUTF8StringEncoding] options:NSPropertyListImmutable format:NULL error:NULL];
  for (NSDictionary *disk in [disks valueForKey:@"AllDisksAndPartitions"]) {
    if (![[disk valueForKey:@"DeviceIdentifier"] isEqualToString:self.device.lastPathComponent])
      continue;
    
    self.mountPath = [disk valueForKey:@"MountPoint"];
  }
}

- (void)destroy
{
  [self run:@"/usr/bin/hdiutil" args:[NSArray arrayWithObjects:@"detach", @"-force", self.device, nil] logOutput:YES];
}

- (NSString *)run:(NSString *)launchPath args:(NSArray *)args logOutput:(BOOL)logOutput
{
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:launchPath];
  [task setArguments:args];
  NSPipe *outPipe = [[NSPipe alloc] init];
  [task setStandardOutput:outPipe];
  [task launch];
  
  NSMutableString *output = [NSMutableString string];
  
  while (task.isRunning) {
    NSData *data = [[outPipe fileHandleForReading] availableData];
    NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [output appendString:aString];
    
    if (logOutput) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        [MRLogViewController log:aString];
      });
    }
    
    usleep(50 * 1000); // 50 milliseconds
  }
  NSData *data = [[outPipe fileHandleForReading] readDataToEndOfFile];
  NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [output appendString:aString];
  
  if (logOutput) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [MRLogViewController log:aString];
    });
  }
  
  return [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)mirrorFromLocal
{
  [self run:@"/usr/bin/rsync" args:[NSArray arrayWithObjects:@"-vrthp", @"--exclude", @".DS_Store", @"--exclude", @"._*", @"--exclude", @".VolumeIcon.icns", @"--exclude", @".Trashes", @"--exclude", @".fseventsd", @"--exclude", @".DocumentRevisions-V100", @"--exclude", @".TemporaryItems", @"--delete", [self.localPath stringByAppendingString:@"/"], [self.mountPath stringByAppendingString:@"/"], nil] logOutput:YES];
}

- (NSUInteger)mirrorToLocal
{
  NSString *rsyncResult = [self run:@"/usr/bin/rsync" args:[NSArray arrayWithObjects:@"-vrthp", @"--exclude", @".DS_Store", @"--exclude", @"._*", @"--exclude", @".VolumeIcon.icns", @"--exclude", @".Trashes", @"--exclude", @".fseventsd", @"--exclude", @".DocumentRevisions-V100", @"--exclude", @".TemporaryItems", @"--delete", [self.mountPath stringByAppendingString:@"/"], [self.localPath stringByAppendingString:@"/"], nil] logOutput:YES];
  
  // guess number of files synced, and post backup notification
  NSUInteger numberOfLines, index, stringLength = rsyncResult.length;
  for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
    index = NSMaxRange([rsyncResult lineRangeForRange:NSMakeRange(index, 0)]);
  
  NSInteger numberOfFilesSynced = (numberOfLines > 5) ? numberOfLines - 5 : 0; // there will be 4 lines in an empty sync, and at least 5 in a sync with one file changed
  
  return numberOfFilesSynced;
}

@end
