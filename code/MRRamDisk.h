//
//  MRRamDisk.h
//  Miram
//
//  Created by Abhi Beckert on 2012-11-4.
//  This is free and unencumbered software released into the public domain.
//

#import <Foundation/Foundation.h>

@interface MRRamDisk : NSObject

@property (retain, readonly) NSString *localPath;
@property (retain, readonly) NSString *device;
@property (retain, readonly) NSString *volumeName;

- (id)initWithLocalPath:(NSString *)localPath;

- (void)create;
- (void)destroy;

- (void)mirrorFromLocal;
- (NSUInteger)mirrorToLocal; // returns an estimate of the number of files synced

@end
