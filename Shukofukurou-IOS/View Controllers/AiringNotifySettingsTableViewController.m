//
//  AiringNotifySettingsTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/13/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AiringNotifySettingsTableViewController.h"

@import UserNotifications;

@interface AiringNotifySettingsTableViewController ()

@end

@implementation AiringNotifySettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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

#pragma mark - Table view data source

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
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

@end
