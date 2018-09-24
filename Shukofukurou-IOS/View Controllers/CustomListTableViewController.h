//
//  CustomListTableViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/24/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomListTableViewController : UITableViewController
@property int entryid;
@property int currenttype;
- (void)populateCustomLists:(NSDictionary *)entry withCurrentType:(int)type withSelectedId:(int)selid;
@end

NS_ASSUME_NONNULL_END
