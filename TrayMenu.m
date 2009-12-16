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

@implementation TrayMenu
- (TrayMenu*) init
{
  [super init];
  
  preferences = [[NSUserDefaults standardUserDefaults] retain];
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:300], @"refreshInterval",
                         @"", @"username",
                         nil
                       ];
  [preferences registerDefaults:dict];
  
  menu = [self createMenu];
  [menu retain];
  [menu setDelegate:self];
  
  _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:32];
  [_statusItem setMenu:menu];
  [_statusItem setHighlightMode:YES];
  [_statusItem setToolTip:@"Google Wave"];
  [_statusItem setImage:[NSImage imageNamed:@"WaveGrey"]];
  [_statusItem retain];
  
  // Start status retriever.
  WaveStatusRetriever* wsr = [[WaveStatusRetriever alloc] initWithDelegate:self];
  [wsr startRunLoopWithInterval:[preferences integerForKey:@"refreshInterval"]];
  
  return self;
}

- (NSMenu*) createMenu
{
  NSZone* menuZone = [NSMenu menuZone];
  NSMenu* newMenu = [[NSMenu allocWithZone:menuZone] init];

  NSMenuItem *menuItem;
  
  statusMenuItem = [[newMenu addItemWithTitle:@"Wave Status" action:nil keyEquivalent:@""] retain];
  [newMenu addItem:[NSMenuItem separatorItem]];
  
  menuItem = [newMenu addItemWithTitle:@"Open Google Wave..." action:@selector(openGoogleWave:) keyEquivalent:@""];
  [menuItem setTarget:self];
  
  [newMenu addItem:[NSMenuItem separatorItem]];

  menuItem = [newMenu addItemWithTitle:@"About WaveMenu..." action:@selector(openAboutWaveMenu:) keyEquivalent:@""];
  [menuItem setTarget:self];  
  menuItem = [newMenu addItemWithTitle:@"Preferences..." action:@selector(openPreferences:) keyEquivalent:@""];
  [menuItem setTarget:self];

  [newMenu addItem:[NSMenuItem separatorItem]];

  menuItem = [newMenu addItemWithTitle:@"Quit WaveMenu..." action:@selector(quitWaveMenu:) keyEquivalent:@"q"];
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
    aboutController = [[NSWindowController alloc] initWithWindowNibName:@"About"];
  }
  [aboutController showWindow:self];
  [[aboutController window] makeKeyAndOrderFront:self];
}

- (void)openPreferences:(id)sender
{
  if (preferencesController == nil)
  {
    preferencesController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];
  }
  [preferencesController showWindow:self];
  [[preferencesController window] makeKeyAndOrderFront:self];
}

#pragma mark Wave Retrieval Delegate Methods

- (void)waveDataRetrievalStarted
{
  [statusMenuItem setTitle:@"Retrieving data..."];
}

- (void)waveDataRetrievalError:(NSError*)error
{
  [_statusItem setImage:[NSImage imageNamed:@"WaveRed"]];
  [statusMenuItem setTitle:[error localizedDescription]];  
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
  
  if (0 == unreadMessages)
  {
    [statusMenuItem setTitle:@"No unread waves"];
    [_statusItem setImage:[NSImage imageNamed:@"WaveGrey"]];
  }
  else
  {
    [statusMenuItem setTitle:
     	[NSString stringWithFormat:@"%d unread blip%@ in %d wave%@",
                                 unreadBlips,
                                 unreadBlips == 1 ? @"" : @"s",
                                 unreadMessages,
                                 unreadMessages == 1 ? @"" : @"s"
    	]
    ];
    [_statusItem setImage:[NSImage imageNamed:@"WaveColored"]];
  }
}
@end
