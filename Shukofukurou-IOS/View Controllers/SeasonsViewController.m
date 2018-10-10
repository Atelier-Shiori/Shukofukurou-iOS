//
//  SeasonsViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/30.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SeasonsViewController.h"
#import "ViewControllerManager.h"
#import "SeasonsRootViewController.h"
#import "SeasonCollectionViewCell.h"
#import "SeasonSelectorTableViewController.h"
#import "AniListSeasonListGenerator.h"
#import "listservice.h"
#import "TitleInfoViewController.h"
#import "TitleIdConverter.h"

@interface SeasonsViewController ()
@property (strong) NSArray *seasonlist;
@property (weak, nonatomic) IBOutlet UINavigationItem *navationitem;
@property (strong) SeasonSelectorTableViewController *seasonselector;
@property (strong) NSString *currentseason;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;
@property int currentyear;
@end

@implementation SeasonsViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    SeasonsRootViewController *srvc = [vcm getSeasonRootViewController];
    srvc.seasonviewcontroller = self;
    
    // Collection Items should only populate in the safe area.
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    
    // Set Season and Year
    _currentseason = [NSUserDefaults.standardUserDefaults valueForKey:@"seasonselect"];
    _currentyear = (int)[[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] components:NSCalendarUnitYear fromDate:[NSDate date]].year;
    _navationitem.title = [NSString stringWithFormat:@" %i - %@", _currentyear, _currentseason];
    // Set Block
    __weak SeasonsViewController *weakSelf = self;
    _seasonselector = (SeasonSelectorTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"seasonselector"];
    _seasonselector.seasonChanged = ^(NSString * _Nonnull season) {
        weakSelf.currentseason = season;
        [NSUserDefaults.standardUserDefaults setValue:season forKey:@"seasonselect"];
        weakSelf.navationitem.title = [NSString stringWithFormat:@" %i - %@", weakSelf.currentyear, weakSelf.currentseason];
        [weakSelf reloadData:NO];
    };
    _seasonselector.yearChanged = ^(int year) {
        weakSelf.currentyear = year;
        weakSelf.navationitem.title = [NSString stringWithFormat:@" %i - %@", weakSelf.currentyear, weakSelf.currentseason];
        [weakSelf reloadData:NO];
    };
    
    // Retrieve Season Data
    [self reloadData:NO];
    
    // Refresh Control
    self.collectionView.refreshControl = [UIRefreshControl new];
    [self.collectionView.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
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

- (void)reloadData:(bool)refresh {
    __weak SeasonsViewController *weakSelf = self;
    [AniListSeasonListGenerator retrieveSeasonDataWithSeason:weakSelf.currentseason  withYear:weakSelf.currentyear refresh:refresh completion:^(id responseObject) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        weakSelf.seasonlist = [responseObject sortedArrayUsingDescriptors:@[sort]];
        [weakSelf.collectionView reloadData];
    } error:^(NSError *error) {
    }];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _seasonlist.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _seasonlist[indexPath.row];
    SeasonCollectionViewCell *cell = (SeasonCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"seasoncell" forIndexPath:indexPath];
    if (cell == nil && collectionView != self.collectionView) {
        cell = (SeasonCollectionViewCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"seasoncell" forIndexPath:indexPath];
        if (!cell) {
            return [UICollectionViewCell new];
        }
    }
    // Configure the cell
    cell.title.text = entry[@"title"];
    [cell loadimage:entry[@"image_url"]];
    return cell;
}

#pragma mark <UICollectionViewDelegate>


- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _seasonlist[indexPath.row];
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
    return YES;
}


- (void)showTitleView:(int)titleid {
    TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
    [self.navigationController pushViewController:titleinfovc animated:YES];
    [titleinfovc loadTitleInfo:titleid withType:0];
}

#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(113, 180);
}

#pragma mark selectors

- (IBAction)selectyear:(id)sender {
    _seasonselector.year = _currentyear;
    [_seasonselector generateselectionitems:yearselect];
    [self startselector:sender];
}

- (IBAction)selectseason:(id)sender {
    _seasonselector.selectedseason = _currentseason;
    [_seasonselector generateselectionitems:seasonselect];
    [self startselector:sender];
}

- (void)startselector:(id)sender {
    UINavigationController *navcontroller = [UINavigationController new];
    navcontroller.viewControllers = @[_seasonselector];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navcontroller.modalPresentationStyle = UIModalPresentationPopover;
        navcontroller.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:navcontroller animated:YES completion:nil];
}

- (IBAction)refresh:(UIRefreshControl *)sender {
    // Refreshes list
    __weak SeasonsViewController *weakSelf = self;
    [AniListSeasonListGenerator retrieveSeasonDataWithSeason:weakSelf.currentseason  withYear:weakSelf.currentyear refresh:YES completion:^(id responseObject) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        weakSelf.seasonlist = [responseObject sortedArrayUsingDescriptors:@[sort]];
        [weakSelf.collectionView reloadData];
        [sender endRefreshing];
    } error:^(NSError *error) {
        [sender endRefreshing];
    }];
}


@end
