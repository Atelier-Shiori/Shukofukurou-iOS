//
//  SettingsViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsViewController : UITableViewController <SFSafariViewControllerDelegate>
@property (strong) IBOutlet UISwitch *refreshlistonstart;
@property (strong) IBOutlet UISwitch *refreshlistautomatically;
@property (strong, nonatomic) IBOutlet UISwitch *cachetitleinfo;
@property (strong, nonatomic) IBOutlet UISwitch *darkmodeswitch;

- (void)loadImageCacheSize;
@end

NS_ASSUME_NONNULL_END
