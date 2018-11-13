//
//  AiringNotifySettingsTableViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/13/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AiringNotifySettingsTableViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UISwitch *airnotifyswitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *viewnotifyingtitlescell;
@property (strong, nonatomic) IBOutlet UITableViewCell *selectlistservicecell;

@end

NS_ASSUME_NONNULL_END
