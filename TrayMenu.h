//
//  TrayMenu.h
//  WaveMenu
//
//  Created by Adam McNeeney on 10/12/2009.
//  Copyright 2009 Transitive Ltd.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TrayMenu : NSObject {
@private
  NSStatusItem* _statusItem;
  NSMenu* menu;
}
- (NSMenu*) createMenu;

@end
