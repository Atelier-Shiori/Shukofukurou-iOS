//
//  AiringDayTableViewController.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AiringDayTableViewController : UITableViewController
@property (nonatomic, copy) void (^listChanged)(NSString *day);
@property (strong) NSString *selectedday;
@end

NS_ASSUME_NONNULL_END
