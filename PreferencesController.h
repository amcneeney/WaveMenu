//
//  PreferencesController.h
//  WaveMenu
//
//  Created by Adam McNeeney on 17/12/2009.
//  Copyright 2009 IBM. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController {
	NSDictionary* retrievalIntervalData;
  NSUserDefaults* userPreferences;
  
  IBOutlet NSPopUpButton* retrievalIntervalControl;
  IBOutlet NSTextField* passwordBox;
  IBOutlet NSTextField* usernameBox;
}

- (IBAction)passwordUpdated:(id)sender;
- (IBAction)retrievalIntervalUpdated:(id)sender;
- (NSNumber*)refreshInterval;
- (void)setRefreshInterval:(NSNumber*)newInterval;
- (NSString*)username;
- (void)setUsername:(NSString*)newUser;
- (NSString*)password;
- (void)setPassword:(NSString*)password;

@end