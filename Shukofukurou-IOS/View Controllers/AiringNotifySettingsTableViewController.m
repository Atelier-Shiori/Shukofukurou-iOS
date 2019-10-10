//
//  AiringNotifySettingsTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/13/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AiringNotifySettingsTableViewController.h"
#import "NotifyingTitlesTableViewController.h"
#import "ThemeManager.h"

@import UserNotifications;

@interface AiringNotifySettingsTableViewController ()

@end

@implementation AiringNotifySettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [ThemeManager fixTableView:self.tableView];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    _airnotifyswitch.on = [defaults boolForKey:@"airnotificationsenabled"];
    [self setairingcellsenabled:_airnotifyswitch.on];
}

- (void)setairingcellsenabled:(bool)enabled {
    _viewnotifyingtitlescell.userInteractionEnabled = enabled;
    _viewnotifyingtitlescell.textLabel.enabled = enabled;
    _selectlistservicecell.userInteractionEnabled = enabled;
    _selectlistservicecell.textLabel.enabled = enabled;
}


- (IBAction)enablenotifyswitch:(id)sender {
    UNUserNotificationCenter *userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [userNotificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionAlert + UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSUserDefaults.standardUserDefaults setBool:self.airnotifyswitch.on forKey:@"airnotificationsenabled"];
                [NSNotificationCenter.defaultCenter postNotificationName:@"AirNotifyToggled" object:nil];
                [self setairingcellsenabled:self.airnotifyswitch.on];
            });
        }
        else {
            NSLog(@"Can't grant notification permissions: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.airnotifyswitch.on = NO;
            });
        }
    }];
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UITableViewCell *tablecell = (UITableViewCell *)sender;
    if ([tablecell.textLabel.text isEqualToString: @"Notifying Titles"]) {
        NotifyingTitlesTableViewController *notifyingtitlestb = (NotifyingTitlesTableViewController *)segue.destinationViewController;
        [notifyingtitlestb loadNotifications];
    }
}

@end
