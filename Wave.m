//
//  Wave.m
//  WaveMenu
//
//  Created by Adam McNeeney on 16/12/2009.
//  Copyright 2009 IBM. All rights reserved.
//

#import "Wave.h"


@implementation Wave
- (Wave*)initWithTitle:(NSString*)myTitle unreadCount:(NSInteger)urc totalCount:(NSInteger)tc
{
  [super init];
  
  title = myTitle;
  unreadCount = urc;
  totalCount = tc;
  
  return self;
}
- (NSString*) title
{
  return title;
}
- (NSInteger) unreadCount
{
  return unreadCount;
}
- (NSInteger) totalCount
{
  return totalCount;
}
@end