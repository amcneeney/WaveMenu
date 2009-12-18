/*
 Copyright (C) 2009 Adam McNeeney. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PreferencesController.h"
#import <Security/Security.h>

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
                        [NSNumber numberWithInt:0], @"unreadInMenu",
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
  NSString* serviceName = @"WaveMenu";
  void* password;
  UInt32 passwordLength = 0;
  
  OSStatus stat = SecKeychainFindGenericPassword(NULL, // default keychain
                                                [serviceName length], [serviceName UTF8String],
                                                0, NULL, // no username
                                                &passwordLength, &password,
                                                NULL // don't need item ref
                                               );
  if (0 == stat)
  {
    NSString* ret = [[NSString alloc] initWithBytes:password length:passwordLength encoding:NSUTF8StringEncoding];
    
    // TODO Free data.
    
    return ret;
	}
  else if (errSecItemNotFound == stat)
  {
    // Can't find password; that's okay.
    return @"";
  }
  else
  {
    NSLog(@"Could not retrieve password; errno = %d", stat);
    return @"";
  }
}
- (void)setPassword:(NSString*)password
{
  // Delete current password.
  NSString* serviceName = @"WaveMenu";
  SecKeychainItemRef itemRef;
  OSStatus stat = SecKeychainFindGenericPassword(NULL, // default keychain
                                                 [serviceName length], [serviceName UTF8String],
                                                 0, NULL, // no username
                                                 0, NULL, // don't need password
                                                 &itemRef
                                                 );
  if (0 == stat)
  {
    SecKeychainItemDelete(itemRef);
  }
  
  stat = SecKeychainAddGenericPassword(NULL, // default keychain
                                       [serviceName length], [serviceName UTF8String],
                                       0, NULL, // no username
                                       [password length],
                                       [password UTF8String],
                                       NULL
                                      );
  if (0 != stat)
  {
    NSLog(@"Warning: failed to update password; errno = %d", stat);
  }
  
  if (delegate && [delegate respondsToSelector:@selector(wavePasswordUpdated:)])
  {
    [delegate performSelector:@selector(wavePasswordUpdated:) withObject:password];
  }  
}
- (BOOL)unreadInMenu
{
  return [userPreferences boolForKey:@"unreadInMenu"];
}
- (void)setUnreadInMenu:(BOOL)newVal
{
  [userPreferences setBool:newVal forKey:@"unreadInMenu"];
}
@end
