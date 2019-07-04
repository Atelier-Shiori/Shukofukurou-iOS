//
//  OAuthLogin.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/8/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthViewControllerDelegate.h"
#import <AuthenticationServices/AuthenticationServices.h>

NS_ASSUME_NONNULL_BEGIN
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
@interface OAuthLogin : NSObject <ASWebAuthenticationPresentationContextProviding>
#else
@interface OAuthLogin : NSObject
#endif
@property (nonatomic, weak) id <AuthViewControllerDelegate> delegate;
- (void)startAniListOAuthSession;
@end

NS_ASSUME_NONNULL_END
