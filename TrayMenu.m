//
//  TrayMenu.m
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Adam McNeeney. All rights reserved.
//

#import "TrayMenu.h"
#import "WaveStatusRetriever.h"
#import "Wave.h"
#import "PreferencesController.h"

@implementation TrayMenu
@synthesize messageMenuItems;

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
  [statusRetriever startRunLoopWithInterval:[[preferencesController refreshInterval] integerValue]];
  
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
}

#pragma mark Preference update delegate methods

- (void)waveUsernameUpdated:(NSString*)user
{
  NSLog(@"Got username update");
  [statusRetriever setUsername:user];
  [statusRetriever clearCookiesIfAppropriate];
}
- (void)wavePasswordUpdated:(NSString*)password
{
  NSLog(@"Got password update");
  [statusRetriever setPassword:password];
  [statusRetriever clearCookiesIfAppropriate];
}
- (void)waveRefreshIntervalUpdated:(NSNumber*)interval
{
  NSLog(@"Got refresh interval update");
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
@end
