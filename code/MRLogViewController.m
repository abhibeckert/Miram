//
//  MRLogViewController.m
//  Miram
//
//  Created by Abhi Beckert on 2012-11-4.
//  This is free and unencumbered software released into the public domain.
//

#import "MRLogViewController.h"

MRLogViewController *_sharedInstance;

@interface MRLogViewController ()

+ (MRLogViewController *)sharedInstance;

@end

@implementation MRLogViewController

+ (MRLogViewController *)sharedInstance
{
  return _sharedInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    return nil;
  
  _sharedInstance = self;
  
  return self;
}

+ (void)log:(NSString *)logStr
{
  NSTextView *logView = (NSTextView *)[[self class] sharedInstance].view;
  
  if (logView.textStorage.length > 2000000) {
    [logView.textStorage replaceCharactersInRange:NSMakeRange(0, 1000000) withString:@"--- LOG TRUNCATED ---\n\n"];
  }
  
  [logView.textStorage replaceCharactersInRange:NSMakeRange(logView.textStorage.length, 0) withString:logStr];
  
  [logView scrollToEndOfDocument:self];
}

@end
