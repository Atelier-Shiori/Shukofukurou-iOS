//
//  ReviewTableViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/1/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReviewTableViewController : UITableViewController
- (void)retrieveReviewsForTitleID:(int)titleid withType:(int)type;
@end

NS_ASSUME_NONNULL_END
