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
#import "TitleInfoViewController.h"

@interface HistoryViewController ()
@property (strong) NSArray *historyItems;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *syncbtn;
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
    _syncbtn.enabled = [NSUserDefaults.standardUserDefaults boolForKey:@"synchistorytoicloud"];
    [self loadhistory];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
    if ([self needsRefresh]) {
        [self performRefresh];
    }
    _syncbtn.enabled = [NSUserDefaults.standardUserDefaults boolForKey:@"synchistorytoicloud"];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"UserLoggedIn"]|| [notification.name isEqualToString:@"ServiceChanged"] || [notification.name isEqualToString:@"HistoryEntryInserted"]) {
        NSLog(@"Reloading History");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadhistory];
        });
    }
    else if ([notification.name isEqualToString:@"UserLoggedOut"]) {
        _historyItems = @[];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
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
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *historyentry = _historyItems[indexPath.row];
    HistoryCell *cell = (HistoryCell *)[self.tableView dequeueReusableCellWithIdentifier:@"historycell"];
    if (cell == nil && tableView != self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"historycell"];
    }
    cell.title.text = historyentry[@"title"];
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
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"historyactiondate" ascending:NO];
    NSArray *tmphistory = [[historymgr retrieveHistoryList] sortedArrayUsingDescriptors:@[descriptor]];
    _historyItems = [tmphistory filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"mediatype == %i", _historytypeselector.selectedSegmentIndex]];
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < _historyItems.count) {
        self.navigationController.toolbarHidden = YES;
        TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
        [self.navigationController pushViewController:titleinfovc animated:YES];
        NSDictionary *historyentry = _historyItems[indexPath.row];
        [titleinfovc loadTitleInfo:((NSNumber *)historyentry[@"titleid"]).intValue withType:((NSNumber *)historyentry[@"mediatype"]).intValue];
    }
}

#pragma mark history
- (IBAction)historySelectorChanged:(id)sender {
    [self loadhistory];
}

- (IBAction)clearHistory:(id)sender {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Clear History" message:[NSUserDefaults.standardUserDefaults boolForKey:@"synchistorytoicloud"] ? @"Do you want to clear the history. This cannot be undone. History will clear on all devices connected to your iCloud account." : @"Do you want to clear the history. This cannot be undone." preferredStyle:UIAlertControllerStyleAlert];
     UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
         HistoryManager *historymgr = HistoryManager.sharedInstance;
         [historymgr removeAllHistoryRecords];
         [historymgr removeAlliCloudHistoryRecords:^{
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self loadhistory];
             });
         }];
     }];
     UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
     }];
     [alertcontroller addAction:noaction];
     [alertcontroller addAction:yesaction];
     [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}

- (IBAction)refresh:(id)sender {
    [self performRefresh];
}

- (void)performRefresh {
    [self showloadingview:YES];
    [HistoryManager.sharedInstance synchistory:^(NSArray * _Nonnull history) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"historyactiondate" ascending:NO];
            self.historyItems = [[history filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"mediatype == %i", self.historytypeselector.selectedSegmentIndex]] sortedArrayUsingDescriptors:@[descriptor]];
            [self.tableView reloadData];
            [self showloadingview:NO];
        });
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

- (bool)needsRefresh {
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"synchistorytoicloud"]) {
        return false;
    }
    return [[[NSDate dateWithTimeIntervalSince1970:[NSUserDefaults.standardUserDefaults integerForKey:@"historysyncdate"]] dateByAddingTimeInterval:6*60*60] timeIntervalSince1970] < [[NSDate date] timeIntervalSince1970];
}
@end

@implementation HistoryRootViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
}
@end
