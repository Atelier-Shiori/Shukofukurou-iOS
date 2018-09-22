//
//  AutoRefreshTimer.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/22/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class ViewControllerManager;

@interface AutoRefreshTimer : NSObject
@property (weak, nonatomic) ViewControllerManager *vcm;
- (void)resumeTimer;
- (void)pauseTimer;
@end

NS_ASSUME_NONNULL_END
