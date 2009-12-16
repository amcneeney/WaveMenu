//
//  WaveStatusRetriever.m
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Transitive Ltd.. All rights reserved.
//

#import "WaveStatusRetriever.h"


@implementation WaveStatusRetriever
- (WaveStatusRetriever*)init
{
  [super init];
  waveDownloader = 0;
  
  return self;
}

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

    // Clear pool.
    NSAutoreleasePool* oldPool = pool;
    pool = [[NSAutoreleasePool alloc] init];
    [oldPool release];
  } while(isRunning==YES);
    
  [pool release];
}

- (void)refreshWaveData:(id)sender
{
  // Grab contents of Wave site.
  NSLog(@"Grabbing wave site data...");
  NSURL* waveURL = [NSURL URLWithString:@"http://wave.google.com/"];
  NSURLRequest *theRequest=[NSURLRequest requestWithURL:waveURL
                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                        timeoutInterval:60.0];
  if (0 != waveDownloader)
  {
    [waveDownloader cancel];
    [waveDownloader release];
  }
  
  waveDownloader = [[NSURLConnection connectionWithRequest:theRequest delegate:self] retain];
  if (waveDownloader)
  {
    waveData = [[NSMutableData data] retain];
  }
  else
  {
    NSLog(@"Could not start download.");
  }

}

- (void) startRunLoop
{
  runLoopThread = [[[NSThread alloc] initWithTarget:self selector:@selector(runLoop:) object:nil] retain];
  [runLoopThread start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [waveData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [waveData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  // release the connection, and the data object
  waveDownloader = 0;
  [connection release];
  
  [waveData release];
  
  // inform the user
  NSLog(@"Wave update connection failed! Error - %@ %@",
        [error localizedDescription],
        [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  NSLog(@"Succeeded! Received %d bytes of data",[waveData length]);
  
  // release the connection, and the data object
  waveDownloader = 0;
  [connection release];

  // Display data.
  NSLog(@"Got data from wave.google.com: %@", [[NSString alloc] initWithData:waveData encoding:NSASCIIStringEncoding]);
  [waveData release];
}
@end