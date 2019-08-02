//
//  HistoryViewController.h
//  Shukofukurou-IOS
//
//  Created by 天々座理世 on 2019/08/01.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HistoryViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;
@property (strong, nonatomic) IBOutlet UISegmentedControl *historytypeselector;

@end

@interface HistoryRootViewController : UINavigationController
@property (strong) HistoryViewController *historyvc;
@end

NS_ASSUME_NONNULL_END
