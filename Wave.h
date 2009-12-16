//
//  Wave.h
//  WaveMenu
//
//  Created by Adam McNeeney on 16/12/2009.
//  Copyright 2009 IBM. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Wave : NSObject {
	NSString* title;
  NSInteger unreadCount;
  NSInteger totalCount;
}
- (Wave*)initWithTitle:(NSString*)myTitle unreadCount:(NSInteger)urc totalCount:(NSInteger)tc;
- (NSString*) title;
- (NSInteger) unreadCount;
- (NSInteger) totalCount;
@end
