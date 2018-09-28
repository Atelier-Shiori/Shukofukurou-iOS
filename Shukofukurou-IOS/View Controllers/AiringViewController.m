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
#import "SearchTableViewCell.h"
#import "AiringSchedule.h"
#import "listservice.h"
#import "RatingTwentyConvert.h"
#import "AniListScoreConvert.h"
#import "TitleInfoViewController.h"
#import "TitleIdConverter.h"


@interface AiringViewController ()
@property (weak, nonatomic) IBOutlet UINavigationItem *navcontroller;
@property (strong) NSArray *airinglist;
@property (strong) NSString *currentday;
@property (weak, nonatomic) IBOutlet UIRefreshControl *refreshcontrol;
@property (strong) AiringDayTableViewController *airingdaycontroller;
@end

@implementation AiringViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    AiringRootViewController *airingvc = [vcm getAiringRootViewController];
    airingvc.airingviewcontroller = self;
    [self autoselectday];
    __weak AiringViewController *weakSelf = self;
    [AiringSchedule retrieveAiringScheduleShouldRefresh:[NSUserDefaults.standardUserDefaults boolForKey:@"refreshlistonstart"] completionhandler:^(bool success) {
        if (success) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
            weakSelf.airinglist = [[AiringSchedule retrieveAiringDataForDay:weakSelf.currentday.lowercaseString] sortedArrayUsingDescriptors:@[sort]];
            [weakSelf.tableView reloadData];
        }
    }];
    // Set Block
    _airingdaycontroller = (AiringDayTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"dayselector"];
    _airingdaycontroller.listChanged = ^(NSString * _Nonnull day) {
        weakSelf.currentday = day;
        weakSelf.navcontroller.title = weakSelf.currentday;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        weakSelf.airinglist = [[AiringSchedule retrieveAiringDataForDay:weakSelf.currentday.lowercaseString] sortedArrayUsingDescriptors:@[sort]];
        [weakSelf.tableView reloadData];
    };
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
    SearchTableViewCell *aentrycell = [tableView dequeueReusableCellWithIdentifier:@"airingcell"];
    if (aentrycell == nil && tableView != self.tableView) {
        aentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"airingcell"];
    }
    aentrycell.title.text = entry[@"title"];
    aentrycell.progress.text = [NSString stringWithFormat:@"Episodes: %@", entry[@"episodes"]];
    aentrycell.type.text = [NSString stringWithFormat:@"Type: %@", entry[@"type"]];
    NSString *score = @"";
    switch ([listservice getCurrentServiceID]) {
        case 1:
            score = entry[@"score"];
            break;
        case 2:
            score = [RatingTwentyConvert convertRatingTwentyToActualScore:((NSNumber *)entry[@"score"]).intValue scoretype:(int)[NSUserDefaults.standardUserDefaults integerForKey:@"kitsu-ratingsystem"]];
            break;
        case 3:
            score = [AniListScoreConvert convertAniListScoreToActualScore:((NSNumber *)entry[@"score"]).intValue withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]];
            break;
        default:
            break;
    }
    [aentrycell loadimage:entry[@"image_url"]];
    return aentrycell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _airinglist[indexPath.row];
    switch ([listservice getCurrentServiceID]) {
        case 1:
            if (entry[@"idMal"] != [NSNull null]) {
                [self showTitleView:((NSNumber *)entry[@"idMal"]).intValue];
            }
            break;
        case 2:
            if (entry[@"idMal"] != [NSNull null]) {
                [TitleIdConverter getKitsuIDFromMALId:((NSNumber *)entry[@"idMal"]).intValue withTitle:entry[@"title"] titletype:entry[@"type"] withType:0 completionHandler:^(int kitsuid) {
                    [self showTitleView:kitsuid];
                } error:^(NSError *error) {
                }];
            }
            break;
        case 3:
            [self showTitleView:((NSNumber *)entry[@"id"]).intValue];
            break;
    }
}

- (void)showTitleView:(int)titleid {
    TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
    [self.navigationController pushViewController:titleinfovc animated:YES];
    [titleinfovc loadTitleInfo:titleid withType:0];
}

- (IBAction)refresh:(id)sender {
    __weak AiringViewController *weakSelf = self;
    [AiringSchedule retrieveAiringScheduleShouldRefresh:true completionhandler:^(bool success) {
        if (success) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
            weakSelf.airinglist = [[AiringSchedule retrieveAiringDataForDay:weakSelf.currentday] sortedArrayUsingDescriptors:@[sort]];
        }
        [weakSelf.tableView reloadData];
        [sender endRefreshing];
    }];
}

- (IBAction)selectday:(id)sender {
    _airingdaycontroller.selectedday = _currentday;
    [_airingdaycontroller.tableView reloadData];
    UINavigationController *navcontroller = [UINavigationController new];
    navcontroller.viewControllers = @[_airingdaycontroller];
    navcontroller.modalPresentationStyle = UIModalPresentationPopover;
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

@end
