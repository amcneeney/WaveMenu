/*
 Copyright (C) 2009 Adam McNeeney. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WaveStatusRetriever.h"
#import "Wave.h"

@implementation WaveStatusRetriever
@synthesize delegate, username, password, currentURL;

- (WaveStatusRetriever*)init
{
  [super init];
  
  delegate = 0;
  waveDownloader = 0;
  loggedInAutomatically = YES;
  
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
  [self setCurrentURL:waveURL];
  NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:waveURL
                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                        timeoutInterval:60.0];
  [theRequest setValue:@"WaveMenu/0.1" forHTTPHeaderField:@"User-Agent"];
  if (0 != waveDownloader)
  {
    [waveDownloader cancel];
    [waveDownloader release];
  }
  
  if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalStarted)])
  {
    [delegate performSelector:@selector(waveDataRetrievalStarted)];
  }
  
  loggingIn = NO;
  loggedInAutomatically = YES;
  waveDownloader = [[NSURLConnection connectionWithRequest:theRequest delegate:self] retain];
  if (waveDownloader)
  {
    waveData = [[NSMutableData data] retain];
  }
  else
  {
    if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
    {
      NSError* err = [NSError
                      errorWithDomain:@"WaveMenu"
                      code:1
                      userInfo:[NSDictionary
                                dictionaryWithObject:@"Could not start main Wave page download"
                                forKey:NSLocalizedDescriptionKey
                               ]
                      ];
      [delegate performSelector:@selector(waveDataRetrievalError:) withObject:err];
    }
  }
}

- (void) startRunLoopWithInterval:(NSInteger)interval
{
  if (timer)
  {
    [timer invalidate];
    [timer release];
  }
  timer = 0;
  if (interval)
  {
    [self refreshWaveData:self];
    timer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshWaveData:) userInfo:nil repeats:YES] retain];
  }
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
  NSLog(@"Succeeded! Received %d bytes of data for %@",[waveData length], [self currentURL]);
  
  // release the connection, and the data object
  waveDownloader = 0;
  [connection release];
  
  // Convert to NSString.
  NSString* waveString = [[NSString alloc] initWithData:waveData encoding:NSUTF8StringEncoding];
  
  //NSLog(@"Data:\n%@", waveString);
  
  // Work out what kind of data we're dealing with.
  if ([[[self currentURL] absoluteString] rangeOfString:@"ServiceLogin"].location != NSNotFound)
  {
    if (loggingIn)
    {
      [self processLoginError:waveString];
    }
    else
    {
      [self processLogin:waveString];
    }
  }
  else if ([[[self currentURL] absoluteString] rangeOfString:@"CheckCookie"].location != NSNotFound)
  {
    [self processCookieCheck:waveString];
  }
  else
  {
    [self processWaveData:waveString];
  }
}
- (void)processWaveData:(NSString*)waveString
{
  NSMutableArray* allMessages = [[NSMutableArray alloc] init];
  
  BOOL gotSomeJSON = NO;
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
    
    gotSomeJSON = YES;

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
  
  if (gotSomeJSON)
  {
    if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalComplete:)])
    {
      [delegate performSelector:@selector(waveDataRetrievalComplete:) withObject:allMessages];
    }
  }
  else
  {
    if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
    {
      NSError* err = [NSError
                      errorWithDomain:@"WaveMenu"
                      code:2
                      userInfo:[NSDictionary
                                dictionaryWithObject:@"Wave page does not contain JSON"
                                forKey:NSLocalizedDescriptionKey
                                ]
                      ];
      [delegate performSelector:@selector(waveDataRetrievalError:) withObject:err];
    }    
  }

  // Display data.
  NSLog(@"Done parsing wave data.");
  [waveData release];
}

-(void)processLogin:(NSString*)waveString
{
  // Grab GALX parameter from incoming string.
  NSRange galxRange = [waveString rangeOfString:@"name=\"GALX\""];
  if (galxRange.location == NSNotFound)
  {
    if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
    {
      NSError* err = [NSError
                      errorWithDomain:@"WaveMenu"
                      code:3
                      userInfo:[NSDictionary
                                dictionaryWithObject:@"Could not find GALX parameter in login page"
                                forKey:NSLocalizedDescriptionKey
                                ]
                      ];
      [delegate performSelector:@selector(waveDataRetrievalError:) withObject:err];
    }
    return;
  }
  // Find GALX value.
  NSRange galxValueRange = [waveString
                            rangeOfString:@"value=\""
                            options:0
                            range:(NSRange){ galxRange.location, 50 }
                          ];
  if (galxValueRange.location == NSNotFound)
  {
    if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
    {
      NSError* err = [NSError
                      errorWithDomain:@"WaveMenu"
                      code:4
                      userInfo:[NSDictionary
                                dictionaryWithObject:@"Could not find GALX parameter value in login page"
                                forKey:NSLocalizedDescriptionKey
                                ]
                      ];
      [delegate performSelector:@selector(waveDataRetrievalError:) withObject:err];
    }
    return;
  }
  // Find end of GALX value string.
  NSRange galxValueEnd = [waveString
                          rangeOfString:@"\""
                          options:0
                          range:(NSRange){ galxValueRange.location + 7, 50 }
                        ];
  if (galxValueEnd.location == NSNotFound)
  {
    if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
    {
      NSError* err = [NSError
                      errorWithDomain:@"WaveMenu"
                      code:5
                      userInfo:[NSDictionary
                                dictionaryWithObject:@"Could not find GALX parameter value end"
                                forKey:NSLocalizedDescriptionKey
                                ]
                      ];
      [delegate performSelector:@selector(waveDataRetrievalError:) withObject:err];
    }
    return;
  }
  NSString* galxString = [waveString
                          substringWithRange:(NSRange){ galxValueRange.location + 7, galxValueEnd.location - galxValueRange.location - 7}];
  
  NSURL* loginURL = [NSURL URLWithString:@"https://www.google.com/accounts/ServiceLoginAuth?service=wave"];
  [self setCurrentURL:loginURL];
  
  // Prepare post data.
  NSString* stringData = [NSString
                          stringWithFormat:@"Email=%@&Passwd=%@&GALX=%@&service=wave", 
                          [[self username] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                          [[self password] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                          [galxString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]
                         ];
  NSData* postData = [NSData dataWithBytes:[stringData UTF8String] length:[stringData length]];
  
  //NSLog(@"Sending data: %@", stringData);
  
  // Prepare request.
  NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:loginURL
                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                        timeoutInterval:60.0];
  [theRequest setHTTPMethod:@"POST"];  
  [theRequest setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];  
  [theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];  
  [theRequest setValue:@"WaveMenu/0.1" forHTTPHeaderField:@"User-Agent"];  
  [theRequest setHTTPBody:postData];

  // Release current connection.
  [waveDownloader release];
  
  // Start actual login.
  loggingIn = YES;
  loggedInAutomatically = NO;
  waveDownloader = [[NSURLConnection connectionWithRequest:theRequest delegate:self] retain];
  if (waveDownloader)
  {
    waveData = [[NSMutableData data] retain];
  }
  else
  {
    NSLog(@"Could not start login connection.");
  }
}
-(void)processLoginError:(NSString*)waveString
{
  loggedInAutomatically = YES;
  
  NSRange errorMessageRange = [waveString rangeOfString:@"<div class=\"errormsg\""];
  if (errorMessageRange.location != NSNotFound)
  {
    // Find end of div.
    NSRange divEndRange = [waveString
                           rangeOfString:@">"
                           options:0
                           range:(NSRange){ errorMessageRange.location, 50 }];
    if (divEndRange.location != NSNotFound)
    {
      NSUInteger errorMessageStart = divEndRange.location + 1;
      while (errorMessageStart < [waveString length])
      {
        unichar currChar = [waveString characterAtIndex:errorMessageStart];
        if (currChar == '\n' || currChar == ' ')
        {
          errorMessageStart++;
        }
        else
        {
          break;
        }
      }
      if (errorMessageStart != [waveString length])
      {
        // Have start of error message; find end.
        NSRange errorMessageBracketEnd = [waveString
                                          rangeOfString:@"["
                                          options:0
                                          range:(NSRange){ errorMessageStart, 200 }];
        NSRange errorMessageTagEnd = [waveString
                                          rangeOfString:@"<"
                                          options:0
                                          range:(NSRange){ errorMessageStart, 200 }];
        NSUInteger errorMessageEnd = (errorMessageBracketEnd.location < errorMessageTagEnd.location) ?
                                     errorMessageBracketEnd.location :
                                     errorMessageTagEnd.location;
        NSString* errorMessage = [waveString substringWithRange:(NSRange){ errorMessageStart, errorMessageEnd - errorMessageStart }];
        
        if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
        {
          NSError* err = [NSError
                          errorWithDomain:@"WaveMenu"
                          code:7
                          userInfo:[NSDictionary
                                    dictionaryWithObject:errorMessage
                                    forKey:NSLocalizedDescriptionKey
                                    ]
                          ];
          [delegate performSelector:@selector(waveDataRetrievalError:) withObject:err];
        }
        return;
      }
    }
  }
  
  // If we got here, then we haven't found the error.
  NSLog(@"Got login error:\n%@", waveString);
  if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
  {
    NSError* err = [NSError
                    errorWithDomain:@"WaveMenu"
                    code:8
                    userInfo:[NSDictionary
                              dictionaryWithObject:@"Unknown login error"
                              forKey:NSLocalizedDescriptionKey
                              ]
                    ];
    [delegate performSelector:@selector(waveDataRetrievalError:) withObject:err];
  }  
}
-(void)processCookieCheck:(NSString*)waveString
{
  NSURL* redirectURL = [NSURL URLWithString:@"http://wave.google.com"];
  [self setCurrentURL:redirectURL];
  NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:redirectURL
                                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                      timeoutInterval:60.0];
  [theRequest setValue:@"WaveMenu/0.1" forHTTPHeaderField:@"User-Agent"];
  [waveDownloader release];
  waveDownloader = [[NSURLConnection connectionWithRequest:theRequest delegate:self] retain];
  if (waveDownloader)
  {
    waveData = [[NSMutableData data] retain];
  }
  else
  {
    if (delegate && [delegate respondsToSelector:@selector(waveDataRetrievalError:)])
    {
      NSError* err = [NSError
                      errorWithDomain:@"WaveMenu"
                      code:9
                      userInfo:[NSDictionary
                                dictionaryWithObject:@"Could not start redirected download"
                                forKey:NSLocalizedDescriptionKey
                                ]
                      ];
      [delegate performSelector:@selector(waveDataRetrievalError:) withObject:err];
    }    
  }  
}
-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
  //NSLog(@"Got redirect: %@", [[request URL] absoluteString]);
  [self setCurrentURL:[request URL]];
  return request;
}

- (void)clearCookiesIfAppropriate
{
  if (!loggedInAutomatically)
  {
    NSHTTPCookieStorage* sharedCookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSHTTPCookie* cookie;
    for (cookie in [sharedCookies cookiesForURL:[NSURL URLWithString:@"https://wave.google.com/wave/"]])
    {
      [sharedCookies deleteCookie:cookie];
    }
  }
}
@end
