//
//  OAuthViewControllerDelegate.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/09/03.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AuthViewControllerDelegate <NSObject>

@optional
- (void)authSuccessful:(int)service;
- (void)authCanceled;
@end
