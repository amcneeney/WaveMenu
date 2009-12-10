//
//  TrayMenu.m
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Transitive Ltd.. All rights reserved.
//

#import "TrayMenu.h"


@implementation TrayMenu
- (TrayMenu*) init
{
  [super init];
  
  menu = [self createMenu];
  [menu retain];
  [menu setDelegate:self];
  
  _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:32];
  [_statusItem setMenu:menu];
  [_statusItem setHighlightMode:YES];
  [_statusItem setToolTip:@"Google Wave"];
  [_statusItem setImage:[NSImage imageNamed:@"WaveGrey"]];
  //[_statusItem setTitle:@"W"];
  [_statusItem retain];
  
  return self;
}

- (NSMenu*) createMenu
{
  NSZone* menuZone = [NSMenu menuZone];
  NSMenu* newMenu = [[NSMenu allocWithZone:menuZone] init];

  NSMenuItem *menuItem;
  
  menuItem = [newMenu addItemWithTitle:@"Open Google Wave..." action:@selector(openGoogleWave:) keyEquivalent:@""];
  [menuItem setTarget:self];
  
  [newMenu addItem:[NSMenuItem separatorItem]];

  menuItem = [newMenu addItemWithTitle:@"Preferences..." action:@selector(openPreferences:) keyEquivalent:@""];
  [menuItem setTarget:self];

  [newMenu addItem:[NSMenuItem separatorItem]];

  menuItem = [newMenu addItemWithTitle:@"Quit WaveMenu..." action:@selector(quitWaveMenu:) keyEquivalent:@""];
  [menuItem setTarget:self];
  
  return newMenu;
}
- (BOOL) validateMenuItem:(NSMenuItem *)inItem 
{
  NSLog(@"Validating menu item.");
  return TRUE;
}
@end
