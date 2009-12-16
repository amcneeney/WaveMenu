//
//  TrayMenu.h
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Adam McNeeney. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TrayMenu : NSObject {
@private
  NSStatusItem* _statusItem;
  NSMenu* menu;
  NSMenuItem* statusMenuItem;
  NSUserDefaults* preferences;
}
- (NSMenu*) createMenu;

@end
