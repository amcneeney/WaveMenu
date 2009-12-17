//
//  PreferencesController.m
//  WaveMenu
//
//  Created by Adam McNeeney on 17/12/2009.
//  Copyright 2009 IBM. All rights reserved.
//

#import "PreferencesController.h"


@implementation PreferencesController
@synthesize delegate;

- (PreferencesController*)initWithWindowNibName:(NSString*)name
{
  [super initWithWindowNibName:name];
  
  retrievalIntervalData = [[NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithInt:300], @"Every 5 minutes",
              [NSNumber numberWithInt:900], @"Every 15 minutes",
              [NSNumber numberWithInt:1800], @"Every 30 minutes",
              [NSNumber numberWithInt:3600], @"Every hour",
              [NSNumber numberWithInt:0], @"Manually",
              nil
              ] retain];
  
  userPreferences = [[NSUserDefaults standardUserDefaults] retain];
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithInt:300], @"refreshInterval",
                        @"", @"username",
                        nil
                        ];
  [userPreferences registerDefaults:dict];
  
  return self;
}
- (void)awakeFromNib
{
  // Load username from prefs.
  [usernameBox setStringValue:[userPreferences stringForKey:@"username"]];
  
  // Load retrieval interval from prefs.
  NSNumber* currInterval = [NSNumber numberWithInteger:[userPreferences integerForKey:@"refreshInterval"]];
  NSString* key;
  for (key in [retrievalIntervalData allKeys])
  {
    if ([currInterval isEqualToNumber:[retrievalIntervalData objectForKey:key]])
    {
      [retrievalIntervalControl selectItemWithTitle:key];
      break;
    }
  }
  // TODO not a menu item for the given pref.
  
  [passwordBox setStringValue:[self password]];
}

- (IBAction)usernameUpdated:(id)sender
{
  [self setUsername:[usernameBox stringValue]];
}

- (IBAction)passwordUpdated:(id)sender
{
  [self setPassword:[passwordBox stringValue]];
}

- (IBAction)retrievalIntervalUpdated:(id)sender
{
	[self setRefreshInterval:[retrievalIntervalData objectForKey:[retrievalIntervalControl titleOfSelectedItem]]];
}

- (NSNumber*)refreshInterval
{
  return [NSNumber numberWithInteger:[userPreferences integerForKey:@"refreshInterval"]];
}
- (void)setRefreshInterval:(NSNumber*)newInterval
{
  [userPreferences setObject:newInterval forKey:@"refreshInterval"];
  [userPreferences synchronize];

  if (delegate && [delegate respondsToSelector:@selector(waveRefreshIntervalUpdated:)])
  {
    [delegate performSelector:@selector(waveRefreshIntervalUpdated:) withObject:newInterval];
  }  
}
- (NSString*)username
{
  return [userPreferences stringForKey:@"username"];
}
- (void)setUsername:(NSString*)newUser
{
  [userPreferences setObject:newUser forKey:@"username"];
  [userPreferences synchronize];
  
  if (delegate && [delegate respondsToSelector:@selector(waveUsernameUpdated:)])
  {
    [delegate performSelector:@selector(waveUsernameUpdated:) withObject:newUser];
  }
}
- (NSString*)password
{
  // TODO retrieve password.
  return @"";
}
- (void)setPassword:(NSString*)password
{
  // TODO update password.
  if (delegate && [delegate respondsToSelector:@selector(wavePasswordUpdated:)])
  {
    [delegate performSelector:@selector(wavePasswordUpdated:) withObject:password];
  }  
}
@end
