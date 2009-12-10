//
//  main.m
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright Transitive Ltd. 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ApplicationDelegate.h"

int main(int argc, char *argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [NSApplication sharedApplication];
  
  // Create application delegate.
  ApplicationDelegate* delegate = [[ApplicationDelegate alloc] init];
  [NSApp setDelegate:delegate];

  // Run application.
  [NSApp run];

  [pool drain];
  return EXIT_SUCCESS;
}
