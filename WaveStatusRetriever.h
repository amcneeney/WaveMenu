//
//  WaveStatusRetriever.h
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Transitive Ltd.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JSON/JSON.h>

@interface WaveStatusRetriever : NSObject {
@private
  id delegate;
  
  NSTimer* timer;
  
  NSURLConnection* waveDownloader;
  NSMutableData* waveData;
  
  SBJSON *jsonParser;
}
@property (retain) id delegate;
- (WaveStatusRetriever*)initWithDelegate:(id)newDelegate;
- (void)refreshWaveData:(id)sender;
- (void)startRunLoop;
@end
