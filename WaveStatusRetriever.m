//
//  WaveStatusRetriever.m
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Transitive Ltd.. All rights reserved.
//

#import "WaveStatusRetriever.h"
#import "Wave.h"

@implementation WaveStatusRetriever
@synthesize delegate;

- (WaveStatusRetriever*)init
{
  [super init];
  
  delegate = 0;
  waveDownloader = 0;
  
  jsonParser = [[[SBJSON alloc] init] retain];
  
  return self;
}
- (WaveStatusRetriever*)initWithDelegate:(id)newDelegate
{
  [self init];
  delegate = newDelegate;
  
  return self;
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
  
  if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalStarted)])
  {
    [delegate performSelector:@selector(waveDataRetrievalStarted)];
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

- (void) startRunLoopWithInterval:(NSInteger)interval
{
  [self refreshWaveData:self];
  timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshWaveData:) userInfo:nil repeats:YES];
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
  
  if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
  {
    [delegate performSelector:@selector(waveDataRetrievalError:) withObject:error];
  }
  
	// Log the error.
  NSLog(@"Wave update connection failed! Error - %@ %@",
        [error localizedDescription],
        [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  //NSLog(@"Succeeded! Received %d bytes of data",[waveData length]);
  
  // release the connection, and the data object
  waveDownloader = 0;
  [connection release];
  
  // Convert to NSString.
  NSString* waveString = [[NSString alloc] initWithData:waveData encoding:NSASCIIStringEncoding];
  
  NSMutableArray* allMessages = [[NSMutableArray alloc] init];
  
  NSRange rangeToCheck = { 0, [waveString length] };
  while (true)
  {
    // Find next JSON prefix.
    NSRange jsonPrefix = [waveString rangeOfString:@"var json = " options:0 range:rangeToCheck];
    if (jsonPrefix.location == NSNotFound)
    {
      break;
    }
    
    // Find end of line following JSON.
    NSRange endOfLine = [waveString rangeOfString:@";\n" options:0 range:(NSRange){ jsonPrefix.location, [waveString length] - jsonPrefix.location }];
    if (endOfLine.location == NSNotFound)
    {
      NSLog(@"Warning: could not find end of JSON string.");
      break;
    }
    
    // Get JSON string.
    NSRange jsonRange = { jsonPrefix.location + 11, endOfLine.location - jsonPrefix.location - 11 };
    NSString* jsonString = [waveString substringWithRange:jsonRange];
    
		// Parse string.
    NSDictionary* jsonObj = [jsonParser objectWithString:jsonString];
    if (0 == jsonObj)
    {
      NSLog(@"Could not parse JSON: $@", jsonObj);
      continue;
    }

    id pObj, messages;
    if ((pObj = [jsonObj objectForKey:@"p"]) && [pObj isKindOfClass:[NSDictionary class]])
    {
      if ((messages = [pObj objectForKey:@"1"]) && [messages isKindOfClass:[NSArray class]])
      {
        id mess;
        for (mess in (NSArray*)messages)
        {
          //NSLog(@"Got message: %@", mess);
          id totalCountNum = [mess objectForKey:@"6"];
          id unreadCountNum = [mess objectForKey:@"7"];
          id metaData = [mess objectForKey:@"9"];
          if (metaData && [metaData isKindOfClass:[NSDictionary class]] &&
              totalCountNum && [totalCountNum isKindOfClass:[NSDecimalNumber class]] &&
              unreadCountNum && [unreadCountNum isKindOfClass:[NSDecimalNumber class]])
          {
            NSString* title = [metaData objectForKey:@"1"];
            if (title && [title isKindOfClass:[NSString class]])
            {
              NSInteger totalCount = [totalCountNum integerValue];
              NSInteger unreadCount = [unreadCountNum integerValue];
              if (totalCount >= unreadCount && totalCount > 0 && unreadCount >= 0)
              {
                //NSLog(@"Got message %d/%d: %@", unreadCount, totalCount, title);
                [allMessages addObject:[[Wave alloc] initWithTitle:title unreadCount:unreadCount totalCount:totalCount]];
              }
              else
              {
                NSLog(@"Message: %@; unread/total count out of range: %@/%@", unreadCountNum, totalCountNum);
              }
            }
            else
            {
              NSLog(@"Could not find title.");
            }
          }
          else
          {
            NSLog(@"Could not find meta data.");
          }
        }
      }
    }
    //NSLog(@"Got JSON: %@", jsonObj);
    
    // Update range.
    rangeToCheck.location = endOfLine.location + 2;
    rangeToCheck.length = [waveString length] - rangeToCheck.location;
  }
  
  if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalComplete:)])
  {
    [delegate performSelector:@selector(waveDataRetrievalComplete:) withObject:allMessages];
  }  

  // Display data.
  NSLog(@"Done parsing wave data.");
  [waveData release];
}
@end