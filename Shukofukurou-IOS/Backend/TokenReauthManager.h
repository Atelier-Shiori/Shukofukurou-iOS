//
//  TokenReauthManager.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 5/10/20.
//  Copyright © 2020 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TokenReauthManager : NSObject
+ (void)checkRefreshOrReauth;
+ (void)showReAuthMessage;
@end

NS_ASSUME_NONNULL_END
