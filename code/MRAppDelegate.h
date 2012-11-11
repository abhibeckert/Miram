//
//  MRAppDelegate.h
//  Miram
//
//  Created by Abhi Beckert on 2012-11-3.
//  This is free and unencumbered software released into the public domain.
//

#import <Cocoa/Cocoa.h>
#import "MRRamDisk.h"

@interface MRAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, retain) MRRamDisk *ramDisk;

@end
