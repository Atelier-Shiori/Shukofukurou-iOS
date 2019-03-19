//
//  TitleSearch.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/18/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface TitleSearch : NSObject
- (void)processScrobble:(void (^)(int titleid, int episode, bool success)) completionHandler;
@end

NS_ASSUME_NONNULL_END
