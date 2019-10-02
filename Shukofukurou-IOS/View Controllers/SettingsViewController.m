//
//  SettingsViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SettingsViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "TitleInfoCache.h"
#import "ViewControllerManager.h"
#import "ThemeManager.h"
#import "UIViewThemed.h"
#import "TitleIDMapper.h"

#if defined(OSS)
#else
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
#endif

@interface SettingsViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *resetmappingscell;
@property (strong, nonatomic) IBOutlet UITableViewCell *clearimagecell;
@property (strong, nonatomic) IBOutlet UITableViewCell *imagecachesize;
@property (strong, nonatomic) IBOutlet UILabel *versionnum;
@property (strong, nonatomic) IBOutlet UISwitch *synctoicloud;
@property (strong, nonatomic) IBOutlet UISwitch *analyticstoggle;
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
    _synctoicloud.on = [defaults boolForKey:@"synchistorytoicloud"];
    _cachetitleinfo.on = [defaults boolForKey:@"cachetitleinfo"];
    _darkmodeswitch.on = [defaults boolForKey:@"darkmode"];
#if defined(OSS)
    _analyticstoggle.enabled = NO;
#else
    _analyticstoggle.on = [defaults boolForKey:@"sendanalytics"];
#endif
    if (@available(iOS 13, *)) {
        // Disable Dark Mode Switch
        _darkmodeswitch.enabled = NO;
    }
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
    }
    else if ([cell.textLabel.text isEqualToString:@"File a Bug Report"]) {
#if defined(OSS)
        [self showopensourcemessage];
#else
        [self openWebBrowserView:[NSURL URLWithString:@"https://github.com/Atelier-Shiori/Shukofukurou-iOS/issues"]];
        [cell setSelected:NO animated:YES];
#endif
    }
    else if ([cell.textLabel.text isEqualToString:@"Third Party Licenses"]) {
        [self openWebBrowserView:[NSURL URLWithString:@"https://malupdaterosx.moe/shukofukurou-for-ios/shukofukurou-for-ios-third-party-licenses/"]];
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
    else if ([cell.textLabel.text isEqualToString:@"Reset Title ID Mappings"]) {
        [self resetTitleIDMappings];
    }
}

- (void)openManual {
    [self openWebBrowserView:[NSURL URLWithString:@"https://malupdaterosx.moe/shukofukurou-ios-manual.pdf"]];
}
    
- (void)clearImages {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Do you really want to clear the image cache?",nil) message:NSLocalizedString(@"Once done, this action cannot be undone.",nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes",nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
            [self loadImageCacheSize];
            [self.clearimagecell setSelected:NO animated:YES];
        }];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.clearimagecell setSelected:NO animated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetTitleIDMappings {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Do you really want to reset the Title ID Mappings?",nil) message:NSLocalizedString(@"Once done, this action cannot be undone.",nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes",nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [TitleIDMapper.sharedInstance clearAllMappings];
        [self.resetmappingscell setSelected:NO animated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.resetmappingscell setSelected:NO animated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)toggledarkmode:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:_darkmodeswitch.on forKey:@"darkmode"];
    [NSNotificationCenter.defaultCenter postNotificationName:@"LoadTheme" object:nil];
}
- (IBAction)synctoicloudtoggle:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:_synctoicloud.on forKey:@"synchistorytoicloud"];
}

- (void)loadImageCacheSize {
    _imagecachesize.detailTextLabel.text = [NSString stringWithFormat:@"%.2f MB", @(SDImageCache.sharedImageCache.totalDiskSize/1000000).doubleValue];
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

- (void)openWebBrowserView:(NSURL *)url {
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:url];
    if (@available(iOS 13, *)) { }
    else {
        svc.preferredBarTintColor = [ThemeManager sharedCurrentTheme].viewBackgroundColor;
        svc.preferredControlTintColor = [ThemeManager sharedCurrentTheme].tintColor;
    }
    [self presentViewController:svc animated:YES completion:^{
    }];
}

- (IBAction)sendstatstoggle:(id)sender {
#if defined(OSS)
#else
        [MSCrashes setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
        [MSAnalytics setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
#endif
}

- (void)showopensourcemessage {
#if defined(OSS)
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"You are using the community version." message:@"You may not file bug reports on the community version." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertcontroller addAction:okaction];
    [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
#else
#endif
}
@end
