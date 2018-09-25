//
//  AdvEditTableViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/25/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdvEditTableViewController : UITableViewController
@property (nonatomic, copy) void (^entryUpdated)(int listtype);
- (void)populateTableViewWithID:(int)titleid withEntryDictionary:(nullable NSDictionary *)uentry withType:(int)type;
@end

NS_ASSUME_NONNULL_END
