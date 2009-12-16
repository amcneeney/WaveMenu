//
//  WaveStatusRetriever.h
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Transitive Ltd.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WaveStatusRetriever : NSObject {
@private
  id delegate;
  NSAutoreleasePool* pool;
  NSThread* runLoopThread;
  
  NSURLConnection* waveDownloader;
  NSMutableData* waveData;
}
- (void)refreshWaveData:(id)sender;
- (void) startRunLoop;
@end
