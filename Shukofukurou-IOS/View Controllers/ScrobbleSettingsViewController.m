//
//  ScrobbleSettingsViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/25/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "ScrobbleSettingsViewController.h"
#import "ScrobbleManager.h"
#import "AnimeRelations.h"
#import <MBProgressHUDFramework/MBProgressHUD.h>
#import <SafariServices/SafariServices.h>
#import "ThemeManager.h"

@interface ScrobbleSettingsViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *clearcachecell;
@property (strong, nonatomic) IBOutlet UITableViewCell *updateanimerelationscell;
@property (strong, nonatomic) IBOutlet UITableViewCell *resetscrobbledatacell;
@property (strong) MBProgressHUD *hud;
@end

@implementation ScrobbleSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [ThemeManager fixTableView:self.tableView];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"Clear Scrobble Cache"]) {
        [self clearScrobbleCache];
    }
    else if ([cell.textLabel.text isEqualToString:@"Update Anime Relations"]) {
        [self performUpdateAnimeRelations];
    }
    else if ([cell.textLabel.text isEqualToString:@"Reset Scrobble Data"]) {
        [self clearScrobbleData];
    }
    else if ([cell.textLabel.text isEqualToString:@"Scrobble User Guide"]) {
        [self performOpenScrobbleGuide];
    }
}

- (void)clearScrobbleCache {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Do you really want to clear the scrobble cache?",nil) message:NSLocalizedString(@"Once done, this action cannot be undone.",nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes",nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performClearScrobbleCache];
        [self.clearcachecell setSelected:NO animated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.clearcachecell setSelected:NO animated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearScrobbleData {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Do you really want to reset all scrobble data?",nil) message:NSLocalizedString(@"Once done, this action cannot be undone.",nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes",nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performresetScrobbleData];
        [self.resetscrobbledatacell setSelected:NO animated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.resetscrobbledatacell setSelected:NO animated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performClearScrobbleCache {
    [ScrobbleManager.sharedInstance clearScrobbleCache];
}

- (void)performUpdateAnimeRelations {
    [self showloadingview:YES withText:@"Updating Anime Relations..."];
    [AnimeRelations.sharedInstance updateRelations:^(bool success) {
        [self showloadingview:NO withText:@""];
        [self.updateanimerelationscell setSelected:NO animated:YES];
    }];
}

- (void)performresetScrobbleData {
    [ScrobbleManager.sharedInstance clearScrobbleCache];
    [AnimeRelations.sharedInstance clearAnimeRelations];
}

- (void)showloadingview:(bool)show withText:(NSString *)text {
    if (show) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        self.hud.label.text = text;
        if (@available(iOS 13, *)) { }
        else {
            self.hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
            self.hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
        }
    }
    else {
        [self.hud hideAnimated:YES];
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    }
}

- (void)performOpenScrobbleGuide {
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[[NSURL alloc] initWithString:@"https://help.malupdaterosx.moe/shukofukurou-for-ios/scrobble-manual/"]];
    if (@available(iOS 13, *)) { }
    else {
        svc.preferredBarTintColor = [ThemeManager sharedCurrentTheme].viewBackgroundColor;
        svc.preferredControlTintColor = [ThemeManager sharedCurrentTheme].tintColor;
    }
    [self presentViewController:svc animated:YES completion:^{
    }];
}

@end
