//
//  WaveStatusRetriever.m
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Transitive Ltd.. All rights reserved.
//

#import "WaveStatusRetriever.h"


@implementation WaveStatusRetriever
- (void)runLoop:(id)sender
{
  NSLog(@"Starting run loop...");
  
  pool = [[NSAutoreleasePool alloc] init];

  [self refreshWaveData:self];
  [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(refreshWaveData:) userInfo:nil repeats:YES];

  double resolution = 300.0;
  BOOL isRunning;
  do {
    // Run the loop for 'resolution' seconds.
    NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
    isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate]; 
  } while(isRunning==YES);
    
  [pool release];
}

- (void)refreshWaveData:(id)sender
{
  // Grab contents of Wave site.
  NSLog(@"Grabbing wave site data...");
  NSURL* waveURL = [NSURL URLWithString:@"http://wave.google.com/"];
  NSData* urlContents = [waveURL resourceDataUsingCache:NO];
  
  // Display data.
  NSLog(@"Got data from wave.google.com: %@", [[NSString alloc] initWithData:urlContents encoding:NSASCIIStringEncoding]);

  // Clear pool.
  [pool release];
  pool = [[NSAutoreleasePool alloc] init];
}

- (void) startRunLoop
{
  runLoopThread = [[[NSThread alloc] initWithTarget:self selector:@selector(runLoop:) object:nil] retain];
  [runLoopThread start];
}
@end
