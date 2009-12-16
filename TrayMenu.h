//
//  TrayMenu.h
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Adam McNeeney. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WaveStatusRetriever.h"

@interface TrayMenu : NSObject {
@private
  NSStatusItem* _statusItem;
  NSMenu* menu;
  NSMenuItem* statusMenuItem;
  NSUserDefaults* preferences;
  NSWindowController* preferencesController;
  NSWindowController* aboutController;
  WaveStatusRetriever* statusRetriever;
}
- (NSMenu*) createMenu;

@end
