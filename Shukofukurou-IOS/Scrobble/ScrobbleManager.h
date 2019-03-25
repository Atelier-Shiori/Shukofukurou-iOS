//
//  ScrobbleManager.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/19/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScrobbleManager : NSObject
+ (instancetype)sharedInstance;
- (void)checkScrobble;
- (void)clearScrobbleCache;
@end

NS_ASSUME_NONNULL_END
