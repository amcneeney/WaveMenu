//
//  ApplicationDelegate.m
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Adam McNeeney. All rights reserved.
//

#import "ApplicationDelegate.h"


@implementation ApplicationDelegate
- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
  // Create tray menu.
  NSLog(@"Creating tray menu...");
  trayMenu = [[TrayMenu alloc] init];
  
  NSLog(@"Done initialising.");
}
@end
