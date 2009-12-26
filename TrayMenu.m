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

#import "TrayMenu.h"
#import "WaveStatusRetriever.h"
#import "Wave.h"
#import "PreferencesController.h"

@implementation TrayMenu
@synthesize messageMenuItems, currentMessages;

- (TrayMenu*) init
{
  [super init];
  
  preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
  [preferencesController setDelegate:self];
  
  menu = [self createMenu];
  [menu retain];
  [menu setDelegate:self];
  
  _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:32];
  [_statusItem setMenu:menu];
  [_statusItem setHighlightMode:YES];
  [_statusItem setToolTip:@"WaveMenu"];
  [_statusItem setImage:[NSImage imageNamed:@"WaveGrey"]];
  [_statusItem retain];
  
  // Start status retriever.
  statusRetriever = [[[WaveStatusRetriever alloc] initWithDelegate:self] retain];
  [statusRetriever setPassword:[preferencesController password]];
  [statusRetriever setUsername:[preferencesController username]];
  [statusRetriever setPreferencesController:preferencesController];
  [statusRetriever startRunLoopWithInterval:[[preferencesController refreshInterval] integerValue]];
  
  currentMessages = 0;
  messageMenuItems = 0;
  
  // Start Growl link.
  [GrowlApplicationBridge setGrowlDelegate:self];
  
  DEBUG((@"Done initialising."));
  
  return self;
}

- (NSMenu*) createMenu
{
  NSZone* menuZone = [NSMenu menuZone];
  NSMenu* newMenu = [[NSMenu allocWithZone:menuZone] init];

  NSMenuItem *menuItem;
  
  statusMenuItem = [[newMenu addItemWithTitle:@"Wave Status" action:nil keyEquivalent:@""] retain];
  [newMenu addItem:[NSMenuItem separatorItem]];
  
  menuItem = [newMenu addItemWithTitle:@"Open Google Wave" action:@selector(openGoogleWave:) keyEquivalent:@""];
  [menuItem setTarget:self];
  
  [newMenu addItem:[NSMenuItem separatorItem]];

  menuItem = [newMenu addItemWithTitle:@"About WaveMenu" action:@selector(openAboutWaveMenu:) keyEquivalent:@""];
  [menuItem setTarget:self];  
  menuItem = [newMenu addItemWithTitle:@"Preferences..." action:@selector(openPreferences:) keyEquivalent:@""];
  [menuItem setTarget:self];
  menuItem = [newMenu addItemWithTitle:@"Refresh Now" action:@selector(refreshWaveData:) keyEquivalent:@""];
  [menuItem setTarget:self];

  [newMenu addItem:[NSMenuItem separatorItem]];

  menuItem = [newMenu addItemWithTitle:@"Quit WaveMenu" action:@selector(quitWaveMenu:) keyEquivalent:@"q"];
  [menuItem setTarget:self];
  
  return newMenu;
}
- (BOOL) validateMenuItem:(NSMenuItem *)inItem 
{
  return TRUE;
}

#pragma mark Menu Methods

- (void)openGoogleWave:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wave.google.com/"]];
}

- (void)quitWaveMenu:(id)sender
{
  [NSApp terminate:sender];
}

- (void)openAboutWaveMenu:(id)sender
{
  if (aboutController == nil)
  {
    aboutController = [[AboutController alloc] initWithWindowNibName:@"About"];
  }
  [[aboutController window] makeKeyAndOrderFront:self];
  [NSApp activateIgnoringOtherApps:YES];
}

- (void)openPreferences:(id)sender
{
  [[preferencesController window] makeKeyAndOrderFront:self];
  [NSApp activateIgnoringOtherApps:YES];
}

- (void)refreshWaveData:(id)sender
{
  [statusRetriever refreshWaveData:sender];
}

#pragma mark Wave Retrieval Delegate Methods

- (void)waveDataRetrievalStarted
{
  [self clearMessagesInMenu];
  [self updateStatusMessage:@"Retrieving data..."];
}

- (void)waveDataRetrievalError:(NSError*)error
{
  [self clearMessagesInMenu];
  [self updateStatusMessage:[error localizedDescription] withIcon:[NSImage imageNamed:@"WaveRed"]];
}

- (void)waveDataRetrievalComplete:(NSArray*)messages
{
  Wave* wave;
  NSInteger unreadMessages = 0;
  NSInteger unreadBlips = 0;
  for (wave in messages)
  {
    //NSLog(@"Got message %d/%d: %@", [wave unreadCount], [wave totalCount], [wave title]);
    NSInteger uc = [wave unreadCount];
    if (uc > 0)
    {
      unreadBlips += uc;
      unreadMessages++;

      BOOL requiresNotification = YES;
      
      // Check whether we already have notified for this message.
      if (currentMessages != 0)
      {
        Wave* oldWave;
        for (oldWave in currentMessages)
        {
          if ([oldWave isSameWaveAs:wave])
          {
            // Check whether number of blips have changed.
            if ([oldWave unreadCount] == uc)
            {
              requiresNotification = NO;
            }
            break;
          }
        }
      }
      if (requiresNotification)
      {
        [GrowlApplicationBridge
         notifyWithTitle:[wave title]
         description:[NSString stringWithFormat:@"%d unread blip%@",
                      uc,
                      uc == 1 ? @"" : @"s"
                     ]
         notificationName:@"New blip"
         iconData:nil
         priority:0
         isSticky:NO
         clickContext:[wave link]
        ];
      }
    }
  }
  // This should already by clear, but just to make sure.
  [self clearMessagesInMenu];
  
  if (0 == unreadMessages)
  {
    [self updateStatusMessage:@"No unread waves" withIcon:[NSImage imageNamed:@"WaveGrey"]];
  }
  else
  {
    NSString* statusMessage = [NSString stringWithFormat:@"%d unread blip%@ in %d wave%@",
                               unreadBlips,
                               unreadBlips == 1 ? @"" : @"s",
                               unreadMessages,
                               unreadMessages == 1 ? @"" : @"s"
                              ];
    [self updateStatusMessage:statusMessage withIcon:[NSImage imageNamed:@"WaveColored"]];

    if ([preferencesController unreadInMenu])
    {
    	NSMutableArray* messagesInMenuConstruction = [NSMutableArray arrayWithCapacity:unreadMessages];
    	NSMenuItem *menuItem;
      NSInteger currIndex = 1;
      for (wave in messages)
      {
        NSInteger uc = [wave unreadCount];
        if (uc > 0)
        {
          // Add menu item.
          menuItem = [menu
                      insertItemWithTitle:[NSString stringWithFormat:@"%@ (%d)", [wave title], uc]
                      action:nil
                      keyEquivalent:@""
                      atIndex:currIndex
                      ];
          [messagesInMenuConstruction addObject:menuItem];
          currIndex++;
        }
      }
      // Record list of menu items for later deletion.
      [self setMessageMenuItems:[NSArray arrayWithArray:messagesInMenuConstruction]];
    }
  }
  
  // Set menu items.
  [self setCurrentMessages:messages];
}

#pragma mark Preference update delegate methods

- (void)waveUsernameUpdated:(NSString*)user
{
  DEBUG((@"Got username update"));
  [statusRetriever setUsername:user];
  [statusRetriever clearCookiesIfAppropriate];
}
- (void)wavePasswordUpdated:(NSString*)password
{
  DEBUG((@"Got password update"));
  [statusRetriever setPassword:password];
  [statusRetriever clearCookiesIfAppropriate];
}
- (void)waveRefreshIntervalUpdated:(NSNumber*)interval
{
  DEBUG((@"Got refresh interval update"));
  [statusRetriever startRunLoopWithInterval:[interval integerValue]];
}
      
#pragma mark -
- (void)updateStatusMessage:(NSString*)message
{
  [statusMenuItem setTitle:message];
  [_statusItem setToolTip:[NSString stringWithFormat:@"WaveMenu: %@", message]];
}

- (void)updateStatusMessage:(NSString*)message withIcon:(NSImage*)icon
{
  [self updateStatusMessage:message];
  [_statusItem setImage:icon];
}

- (void)clearMessagesInMenu
{
  NSArray* items = [self messageMenuItems];
  if (items)
  {
    NSMenuItem *menuItem;
    for (menuItem in items)
    {
      [menu removeItem:menuItem];
    }
  }
  [self setMessageMenuItems:0];
}

#pragma mark Growl delegates

- (NSDictionary *) registrationDictionaryForGrowl
{
  NSArray* notificationTypes = [NSArray arrayWithObjects:@"New blip", nil];
  return [NSDictionary dictionaryWithObjectsAndKeys:
          notificationTypes, GROWL_NOTIFICATIONS_ALL,
          notificationTypes, GROWL_NOTIFICATIONS_DEFAULT,
          nil
         ];
}

- (NSString *) applicationNameForGrowl
{
  return @"WaveMenu";
}

- (void) growlNotificationWasClicked:(NSString*)waveURL
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:waveURL]];
}
@end
