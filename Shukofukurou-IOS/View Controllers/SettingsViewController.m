//
//  SettingsViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SettingsViewController.h"
#import "StreamDataRetriever.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    _refreshlistonstart.on = [defaults boolForKey:@"refreshlistonstart"];
    _refreshlistautomatically.on = [defaults boolForKey:@"refreshautomatically"];
    _streamregion.selectedSegmentIndex = [defaults integerForKey:@"stream_region"];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)setrefreshonstart:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:_refreshlistonstart.on forKey:@"refreshlistonstart"];
}
- (IBAction)setrefreshautomatically:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:_refreshlistautomatically.on forKey:@"refreshautomatically"];
    [NSNotificationCenter.defaultCenter postNotificationName:@"AutoRefreshStateChanged" object:nil];
}
- (IBAction)setstreamregion:(id)sender {
    [NSUserDefaults.standardUserDefaults setInteger:_streamregion.selectedSegmentIndex forKey:@"stream_region"];
    [StreamDataRetriever removeAllStreamEntries];
    [StreamDataRetriever performrestrieveStreamData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"Online Manual"]) {
        [self openManual];
        [cell setSelected:NO animated:YES];
    }
}

- (void)openManual {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://malupdaterosx.moe/shukofukurou-ios-manual.pdf"] options:@{} completionHandler:^(BOOL success) {}];
}

@end
