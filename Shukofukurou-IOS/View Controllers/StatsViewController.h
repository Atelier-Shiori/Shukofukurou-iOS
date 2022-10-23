//
//  StatsViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 2/4/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface StatsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, GKBarGraphDataSource>
@property (strong, nonatomic) IBOutlet UISegmentedControl *statsselector;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *graphView;
- (void)populateValues;
- (void)performLoadStats;
@end

NS_ASSUME_NONNULL_END
