//
//  AiringSchedule.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AiringSchedule : NSObject
+ (void)retrieveAiringScheduleShouldRefresh:(bool)refresh completionhandler: (void (^)(bool success))completionHandler;
+ (NSArray *)retrieveAiringDataForDay:(NSString *)day;
@end

NS_ASSUME_NONNULL_END
