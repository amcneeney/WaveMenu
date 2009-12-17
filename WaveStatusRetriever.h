//
//  WaveStatusRetriever.h
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Transitive Ltd.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSON.h"

@interface WaveStatusRetriever : NSObject {
@private
  id delegate;
  
  NSTimer* timer;
  
  NSURLConnection* waveDownloader;
  NSMutableData* waveData;
  NSURL* currentURL;
  
  SBJSON *jsonParser;
  
  NSString* username;
  NSString* password;
  
  BOOL loggingIn;
}
@property (retain) id delegate;
@property (retain) NSString* username;
@property (retain) NSString* password;
@property (retain) NSURL* currentURL;

- (WaveStatusRetriever*)initWithDelegate:(id)newDelegate;
- (void)refreshWaveData:(id)sender;
- (void)startRunLoopWithInterval:(NSInteger)interval;

- (void)processWaveData:(NSString*)waveString;
- (void)processLogin:(NSString*)waveString;
- (void)processLoginError:(NSString*)waveString;
- (void)processCookieCheck:(NSString*)waveString;

@end
