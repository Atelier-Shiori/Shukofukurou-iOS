//
//  AiringViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/30.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AiringViewController.h"
#import "AiringDayTableViewController.h"
#import "ViewControllerManager.h"
#import "AiringTableViewCell.h"
#import "AiringSchedule.h"
#import "listservice.h"
#import "RatingTwentyConvert.h"
#import "AniListScoreConvert.h"
#import "TitleInfoViewController.h"
#import "TitleIDMapper.h"
#import <MBProgressHudFramework/MBProgressHUD.h>
#import "ThemeManager.h"


@interface AiringViewController ()
@property (weak, nonatomic) IBOutlet UINavigationItem *navcontroller;
@property (strong) NSArray *airinglist;
@property (strong) NSString *currentday;
@property (weak, nonatomic) IBOutlet UIRefreshControl *refreshcontrol;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;
@property (strong) AiringDayTableViewController *airingdaycontroller;
@property (strong) MBProgressHUD *hud;
@property bool refreshing;
@property NSTimer *countdowntimerrefresh;
@end

@implementation AiringViewController

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.countdowntimerrefresh = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(fireTimer) userInfo:nil repeats:YES];
    NSLog(@"Starting Timer");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.countdowntimerrefresh invalidate];
    NSLog(@"Stopping Timer");
}

- (void)fireTimer {
    for (AiringTableViewCell *cell in self.tableView.visibleCells) {
        [(AiringTableViewCell *)cell updateCountdown];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"AiringTableViewCell" bundle:nil] forCellReuseIdentifier:@"airingcell"];
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    AiringRootViewController *airingvc = [vcm getAiringRootViewController];
    airingvc.airingviewcontroller = self;
    [self autoselectday];
    __weak AiringViewController *weakSelf = self;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults valueForKey:@"airschedulerefreshdate"] || ((NSDate *)[defaults valueForKey:@"airschedulerefreshdate"]).timeIntervalSinceNow < 0) {
        [self showloadingview:YES];
        [AiringSchedule retrieveAiringScheduleShouldRefresh:true completionhandler:^(bool success, bool refreshed) {
            if (success && refreshed) {
                [self reloadData];
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*60*72] forKey:@"airschedulerefreshdate"];
            }
            [self showloadingview:NO];
        }];
    }
    else {
        [self reloadData];
    }
    // Set Block
    _airingdaycontroller = (AiringDayTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"dayselector"];
    _airingdaycontroller.listChanged = ^(NSString * _Nonnull day) {
        weakSelf.currentday = day;
        weakSelf.navcontroller.title = weakSelf.currentday;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        weakSelf.airinglist = [[AiringSchedule retrieveAiringDataForDay:weakSelf.currentday.lowercaseString] sortedArrayUsingDescriptors:@[sort]];
        [weakSelf.tableView reloadData];
        if (weakSelf.airinglist.count > 0) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    };
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(airScheduleHasNewDataNotification:) name:@"airscheduleHasNewData" object:nil];
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

- (void)airScheduleHasNewDataNotification:(NSNotification *)notification {
    [self reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _airinglist.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _airinglist[indexPath.row];
    AiringTableViewCell *aentrycell = [tableView dequeueReusableCellWithIdentifier:@"airingcell"];
    if (aentrycell == nil && tableView != self.tableView) {
        aentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"airingcell"];
        if (!aentrycell) {
            return [UITableViewCell new];
        }
    }
    aentrycell.title.text = entry[@"title"];
    aentrycell.progress.text = [NSString stringWithFormat:@"Episodes: %@", entry[@"episodes"]];
    aentrycell.type.text = [NSString stringWithFormat:@"Type: %@", entry[@"type"]];
    [aentrycell loadimage:entry[@"image_url"]];
    if (entry[@"nextairdate"] != [NSNull null] && entry[@"nextepisode"] != [NSNull null]) {
        aentrycell.airingDate = entry[@"nextairdate"];
        aentrycell.nextEpisode = ((NSNumber *)entry[@"nextepisode"]).intValue;
        aentrycell.enablecountdown = YES;
        [aentrycell updateCountdown];
    }
    return aentrycell ? aentrycell : [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.tableView.refreshControl.refreshing) {
        NSDictionary *entry = _airinglist[indexPath.row];
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1: {
                if (entry[@"idMal"] != [NSNull null]) {
                    [self showTitleView:((NSNumber *)entry[@"idMal"]).intValue];
                }
                break;
            }
            case 2: {
                [self showloadingview:YES];
                [[TitleIDMapper sharedInstance] retrieveTitleIdForService:3 withTitleId:((NSNumber *)entry[@"id"]).stringValue withTargetServiceId:2 withType:0 completionHandler:^(id  _Nonnull titleid, bool success) {
                    [self showloadingview:NO];
                    if (success) {
                        [self showTitleView:((NSNumber *)titleid).intValue];
                    }
                }];
                break;
            }
            case 3: {
                [self showTitleView:((NSNumber *)entry[@"id"]).intValue];
                break;
            }
        }
    }
    else {
        [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:NO];
    }
}

- (void)showTitleView:(int)titleid {
    TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
    [self.navigationController pushViewController:titleinfovc animated:YES];
    [titleinfovc loadTitleInfo:titleid withType:0];
}

- (IBAction)refresh:(id)sender {
    __weak AiringViewController *weakSelf = self;
    [AiringSchedule retrieveAiringScheduleShouldRefresh:true completionhandler:^(bool success, bool refreshed) {
        if (success && refreshed) {
            [weakSelf reloadData];
        }
        [sender endRefreshing];
    }];
}

- (void)performrefresh {
    if (!_refreshing) {
        [self showloadingview:YES];
        __weak AiringViewController *weakSelf = self;
        [AiringSchedule retrieveAiringScheduleShouldRefresh:true completionhandler:^(bool success, bool refreshed) {
            if (success && refreshed) {
                [weakSelf reloadData];
            }
            [self showloadingview:NO];
        }];
    }
}

- (void)reloadData {
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    self.airinglist = [[AiringSchedule retrieveAiringDataForDay:self.currentday.lowercaseString] sortedArrayUsingDescriptors:@[sort]];
    [self.tableView reloadData];
}

- (IBAction)selectday:(id)sender {
    _airingdaycontroller.selectedday = _currentday;
    [_airingdaycontroller.tableView reloadData];
    UINavigationController *navcontroller = [UINavigationController new];
    navcontroller.viewControllers = @[_airingdaycontroller];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navcontroller.modalPresentationStyle = UIModalPresentationPopover;
    }
    navcontroller.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:navcontroller animated:YES completion:nil];
}

- (void)autoselectday {
    // Auto selects day based on the computer's date.
    NSDateComponents *component = [NSCalendar.currentCalendar components:NSCalendarUnitWeekday fromDate:NSDate.date];
    switch (component.weekday) {
        case 1:
            //Sunday
            _currentday = @"Sunday";
            break;
        case 2:
            //Monday
            _currentday = @"Monday";
            break;
        case 3:
            //Tuesday
            _currentday = @"Tuesday";
            break;
        case 4:
            //Wednesday
            _currentday = @"Wednesday";
            break;
        case 5:
            //Thursday
            _currentday = @"Thursday";
            break;
        case 6:
            //Friday
            _currentday = @"Friday";
            break;
        case 7:
            //Saturday
            _currentday = @"Saturday";
            break;
        default:
            break;
    }
    _navcontroller.title = _currentday;
}

- (void)showloadingview:(bool)show {
    if (show && !_refreshing) {
        _refreshing = YES;
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = @"Loading";
        if (@available(iOS 13, *)) { }
        else {
            _hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
            _hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
        }
    }
    else if (!show) {
        [_hud hideAnimated:YES];
        _refreshing = NO;
    }
}

@end
