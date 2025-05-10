//
//  ListSelectorViewController.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/11/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
#if TARGET_OS_VISION
@interface ListSelectorViewController <UITableViewDelegate> : UITableViewController
#else
@interface ListSelectorViewController : UITableViewController
#endif
@property (nonatomic, copy) void (^listChanged)(NSString *listname, NSString *listtype);
@property (strong) NSString *selectedlist;
- (void)generateLists:(NSArray *)list withListType:(int)listtype;
@end

NS_ASSUME_NONNULL_END
