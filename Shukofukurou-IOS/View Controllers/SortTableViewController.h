//
//  SortTableViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/8/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SortTableViewController : UITableViewController
@property (nonatomic, copy) void (^listSortChanged)(NSString *sortby, bool accending, int type);
- (void)loadSort:(NSString *)sortby withAccending:(bool)accending withType:(int)type;
@end

NS_ASSUME_NONNULL_END
