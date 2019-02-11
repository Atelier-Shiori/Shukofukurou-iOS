//
//  SettingsViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SettingsViewController.h"
#import "StreamDataRetriever.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "TitleInfoCache.h"
#import "ViewControllerManager.h"
#import "ThemeManager.h"
#import "UIViewThemed.h"

@interface SettingsViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *imagecachesize;
@property (strong, nonatomic) IBOutlet UILabel *versionnum;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;
@end

@implementation SettingsViewController
    
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    _refreshlistonstart.on = [defaults boolForKey:@"refreshlistonstart"];
    _refreshlistautomatically.on = [defaults boolForKey:@"refreshautomatically"];
    _streamregion.selectedSegmentIndex = [defaults integerForKey:@"stream_region"];
    _cachetitleinfo.on = [defaults boolForKey:@"cachetitleinfo"];
    _darkmodeswitch.on = [defaults boolForKey:@"darkmode"];
    _versionnum.text = [NSString stringWithFormat:@"%@ (Build %@)",[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey]];
    [self loadImageCacheSize];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"SettingsViewLoaded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sidebarShowAlwaysNotification:) name:@"sidebarStateDidChange" object:nil];
    [self hidemenubtn];
}

- (void)sidebarShowAlwaysNotification:(NSNotification *)notification {
    [self hidemenubtn];
}

- (void)hidemenubtn {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if ([ViewControllerManager getAppDelegateViewControllerManager].mvc.shouldHideMenuButton) {
            [self.menubtn setEnabled:NO];
            [self.menubtn setTintColor: [UIColor clearColor]];
        }
        else {
            [self.menubtn setEnabled:YES];
            [self.menubtn setTintColor:nil];
        }
    }
}
- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"SettingsViewLoaded"]) {
        [self loadImageCacheSize];
    }
}


- (IBAction)setrefreshonstart:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:_refreshlistonstart.on forKey:@"refreshlistonstart"];
}

- (IBAction)setrefreshautomatically:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:_refreshlistautomatically.on forKey:@"refreshautomatically"];
    if (!_refreshlistautomatically.on) {
        [NSUserDefaults.standardUserDefaults setObject:nil forKey:@"nextlistrefresh"];
    }
}
- (IBAction)setstreamregion:(id)sender {
    [NSUserDefaults.standardUserDefaults setInteger:_streamregion.selectedSegmentIndex forKey:@"stream_region"];
    [StreamDataRetriever removeAllStreamEntries];
    [StreamDataRetriever performrestrieveStreamData];
}

- (IBAction)setTitleCache:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:_cachetitleinfo.on forKey:@"cachetitleinfo"];
    if (!_cachetitleinfo.on) {
        [TitleInfoCache cleanupcacheShouldRemoveAll:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"Online Manual"]) {
        [self openManual];
        [cell setSelected:NO animated:YES];
    }
    else if ([cell.textLabel.text isEqualToString:@"Clear Image Cache"]) {
        [self clearImages];
        [cell setSelected:NO animated:YES];
    }
    else if ([cell.textLabel.text isEqualToString:@"File a Bug Report"]) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://github.com/Atelier-Shiori/Shukofukurou-iOS/issues"] options:@{} completionHandler:^(BOOL success) {}];
        [cell setSelected:NO animated:YES];
    }
    else if ([cell.textLabel.text isEqualToString:@"Follow us on Twitter"]) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://twitter.com/maluosxdev"] options:@{} completionHandler:^(BOOL success) {}];
        [cell setSelected:NO animated:YES];
    }
    else if ([cell.textLabel.text isEqualToString:@"Follow us on Mastodon"]) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://mastodon.social/@malupdaterosxdev"] options:@{} completionHandler:^(BOOL success) {}];
        [cell setSelected:NO animated:YES];
    }
}

- (void)openManual {
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://malupdaterosx.moe/shukofukurou-ios-manual.pdf"]];
    svc.preferredBarTintColor = [ThemeManager sharedCurrentTheme].viewBackgroundColor;
    svc.preferredControlTintColor = [ThemeManager sharedCurrentTheme].tintColor;
    [self presentViewController:svc animated:YES completion:^{
    }];
}
    
- (void)clearImages {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Do you really want to clear the image cache?",nil) message:NSLocalizedString(@"Once done, this action cannot be undone.",nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes",nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
            [self loadImageCacheSize];
        }];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)toggledarkmode:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:_darkmodeswitch.on forKey:@"darkmode"];
    [NSNotificationCenter.defaultCenter postNotificationName:@"LoadTheme" object:nil];
}

- (void)loadImageCacheSize {
    _imagecachesize.detailTextLabel.text = [NSString stringWithFormat:@"%.2f MB", @(SDImageCache.sharedImageCache.getSize/1000000).doubleValue];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    UIViewGroupHeader *view = [[UIViewGroupHeader alloc] initIsSidebar:false isFirstSection:section == 0 ? true : false];
    view.label.text = sectionTitle.uppercaseString;
    return view;
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
    }];
}

@end
