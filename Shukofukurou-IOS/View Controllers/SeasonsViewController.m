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
@property int currentyear;
@end

@implementation SeasonsViewController

static NSString * const reuseIdentifier = @"Cell";

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _seasonlist.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _seasonlist[indexPath.row];
    SeasonCollectionViewCell *cell = (SeasonCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"seasoncell" forIndexPath:indexPath];
    if (cell == nil && collectionView != self.collectionView) {
        cell = (SeasonCollectionViewCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"seasoncell" forIndexPath:indexPath];
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

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

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
    navcontroller.modalPresentationStyle = UIModalPresentationPopover;
    navcontroller.popoverPresentationController.barButtonItem = sender;
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
