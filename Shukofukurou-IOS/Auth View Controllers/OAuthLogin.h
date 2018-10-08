//
//  OAuthLogin.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/8/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthViewControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAuthLogin : NSObject
@property (nonatomic, weak) id <AuthViewControllerDelegate> delegate;
- (void)startAniListOAuthSession;
@end

NS_ASSUME_NONNULL_END
