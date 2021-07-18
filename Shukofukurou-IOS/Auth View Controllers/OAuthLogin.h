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
@interface OAuthLogin : NSObject <ASWebAuthenticationPresentationContextProviding>
@property (nonatomic, weak) id <AuthViewControllerDelegate> delegate;
@property bool reauthorizing;
- (void)startOAuthSession;
@end

NS_ASSUME_NONNULL_END
