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

#import <Cocoa/Cocoa.h>

#define DEBUG(x) \
  do \
  { \
    if ([preferencesController debug]) \
    { \
      NSLog x; \
    } \
  } \
  while (false)

typedef enum GrowlNotification {
  GROWL_STICKY = 0,
  GROWL_MOMENTARY = 1,
  GROWL_NONE = 2
} GrowlNotification;

@interface PreferencesController : NSWindowController {
	NSDictionary* retrievalIntervalData;
  NSUserDefaults* userPreferences;
  
  IBOutlet NSPopUpButton* retrievalIntervalControl;
  IBOutlet NSTextField* passwordBox;
  IBOutlet NSTextField* usernameBox;
  
  id delegate;
}

- (IBAction)passwordUpdated:(id)sender;
- (IBAction)retrievalIntervalUpdated:(id)sender;

- (NSNumber*)refreshInterval;
- (void)setRefreshInterval:(NSNumber*)newInterval;
- (NSString*)username;
- (void)setUsername:(NSString*)newUser;
- (NSString*)password;
- (void)setPassword:(NSString*)password;
- (BOOL)unreadInMenu;
- (void)setUnreadInMenu:(BOOL)newVal;
- (GrowlNotification)growlNotifications;
- (BOOL)debug;

@property (nonatomic,retain) id delegate;

@end