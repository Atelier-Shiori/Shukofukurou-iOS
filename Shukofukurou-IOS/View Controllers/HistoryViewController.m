//
//  HistoryViewController.m
//  Shukofukurou-IOS
//
//  Created by 天々座理世 on 2019/08/01.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "HistoryViewController.h"
#import "HistoryCell.h"
#import "ViewControllerManager.h"
#import <MBProgressHUDFramework/MBProgressHUDFramework.h>
#import "ThemeManager.h"

@interface HistoryViewController ()
@property (strong) NSArray *historyItems;
@property (strong) MBProgressHUD *hud;
@end

@implementation HistoryViewController
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    HistoryRootViewController *historyroot = [vcm getHistoryRootViewController];
    historyroot.historyvc = self;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sidebarShowAlwaysNotification:) name:@"sidebarStateDidChange" object:nil];
    [self hidemenubtn];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ServiceChanged" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"UserLoggedIn" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"UserLoggedOut" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"HistoryEntryInserted" object:nil];
    [self loadhistory];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"UserLoggedIn"]|| [notification.name isEqualToString:@"ServiceChanged"] || [notification.name isEqualToString:@"HistoryEntryInserted"]) {
        [self loadhistory];
    }
    else if ([notification.name isEqualToString:@"UserLoggedOut"]) {
        _historyItems = @[];
        [self.tableView reloadData];
    }
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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.historyItems.count;
}

#pragma mark Table View Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *historyentry = _historyItems[indexPath.row];
    HistoryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"animeentrycell"];
    if (cell == nil && tableView != self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"animeentrycell"];
    }
    cell.title = historyentry[@"title"];
    [cell setActionText:((NSNumber *)historyentry[@"historyactiontype"]).intValue withSegment:historyentry[@"segment"] withMediaType:((NSNumber *)historyentry[@"mediatype"]).intValue];
    NSDate *historydate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)historyentry[@"historyactiondate"]).longValue];
    cell.datestring.text = [NSDateFormatter localizedStringFromDate: historydate
    dateStyle: NSDateFormatterShortStyle
    timeStyle: NSDateFormatterShortStyle];
    return cell;
}

- (void)loadhistory {
    HistoryManager *historymgr = HistoryManager.sharedInstance;
    [historymgr pruneLocalHistory];
    [historymgr pruneicloudHistory:^{
    }];
    NSArray *tmphistory = [historymgr retrieveHistoryList];
    _historyItems = [tmphistory filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"mediatype == %i", _historytypeselector.selectedSegmentIndex]];
    [self.tableView reloadData];
}

- (IBAction)historySelectorChanged:(id)sender {
    [self loadhistory];
}

- (IBAction)clearHistory:(id)sender {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Clear History" message:@"Do you want to clear the history. This cannot be undone. History will clear on all devices connected to your iCloud account." preferredStyle:UIAlertControllerStyleAlert];
     UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
         HistoryManager *historymgr = HistoryManager.sharedInstance;
         [historymgr removeAllHistoryRecords];
         [historymgr removeAlliCloudHistoryRecords:^{
             [self loadhistory];
         }];
     }];
     UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
     }];
     [alertcontroller addAction:noaction];
     [alertcontroller addAction:yesaction];
     [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}

- (IBAction)refresh:(id)sender {
    [self showloadingview:YES];
    [HistoryManager.sharedInstance synchistory:^(NSArray * _Nonnull history) {
        self.historyItems = [history filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"mediatype == %i", self.historytypeselector.selectedSegmentIndex]];
        [self.tableView reloadData];
        [self showloadingview:NO];
    }];
}

- (void)showloadingview:(bool)show {
    if (show ) {
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = @"Syncing";
        if (@available(iOS 13, *)) { }
        else {
            _hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
            _hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
        }
    }
    else if (!show) {
        [_hud hideAnimated:YES];
    }
}
@end

@implementation HistoryRootViewController

@end
