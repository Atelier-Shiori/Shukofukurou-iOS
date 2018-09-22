//
//  SettingsViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsViewController : UITableViewController
@property (strong) IBOutlet UISwitch *refreshlistonstart;
@property (strong) IBOutlet UISwitch *refreshlistautomatically;
@property (strong) IBOutlet UISwitch *darkmode;
@property (strong) IBOutlet UISegmentedControl *streamregion;
@end

NS_ASSUME_NONNULL_END
