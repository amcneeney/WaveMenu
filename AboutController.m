//
//  AboutController.m
//  WaveMenu
//
//  Created by Adam McNeeney on 18/12/2009.
//  Copyright 2009 IBM. All rights reserved.
//

#import "AboutController.h"


@implementation AboutController
- (NSString*)bundleVersionNumber
{
  return [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
}
@end
