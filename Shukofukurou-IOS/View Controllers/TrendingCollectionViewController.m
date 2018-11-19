//
//  TrendingCollectionViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/6/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "TrendingCollectionViewController.h"
#import "SeasonCollectionViewCell.h"
#import "TrendingCollectionHeaderView.h"
#import "TitleInfoViewController.h"
#import "TrendingRetriever.h"
#import "ViewControllerManager.h"
#import "listservice.h"

@interface TrendingCollectionViewController ()
@property (strong) NSDictionary *items;
@end

@implementation TrendingCollectionViewController

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
    TrendingViewController *tvc = [vcm getTrendingRootViewController];
    tvc.trendingcollectionvc = self;
    
    // Collection Items should only populate in the safe area.
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    
    // Set Notification Center Observer
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"ServiceChanged" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sidebarShowAlwaysNotification:) name:@"sidebarStateDidChange" object:nil];
    
    // Add Refresh Control
    self.collectionView.refreshControl = [UIRefreshControl new];
    [self.collectionView.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.title = @"Trending";
    
    [self hidemenubtn];
    self.typeselector.selectedSegmentIndex = [NSUserDefaults.standardUserDefaults integerForKey:@"selectedtrendtype"];
    [self loadretrieving];
    
}

- (void)recieveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"ServiceChanged"]) {
        // Reload List
        NSLog(@"Switching Lists");
        [self loadretrieving];
    }
}

- (void)loadretrieving {
    [TrendingRetriever getTrendListForService:[listservice getCurrentServiceID] withType:(int)_typeselector.selectedSegmentIndex shouldRefresh:NO completion:^(id  _Nonnull responseobject) {
        self.items = responseobject;
        [self.collectionView reloadData];
    } error:^(NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}

- (IBAction)refresh:(UIRefreshControl *)sender {
    // Refreshes list
    [sender beginRefreshing];
    [TrendingRetriever getTrendListForService:[listservice getCurrentServiceID] withType:(int)_typeselector.selectedSegmentIndex shouldRefresh:YES completion:^(id  _Nonnull responseobject) {
        self.items = responseobject;
        [self.collectionView reloadData];
        [sender endRefreshing];
    } error:^(NSError * _Nonnull error) {
        NSLog(@"%@", error);
        [sender endRefreshing];
    }];
}

- (IBAction)typechanged:(id)sender {
    [self loadretrieving];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _items.allKeys.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return ((NSArray *)_items[_items.allKeys[section]]).count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _items[_items.allKeys[indexPath.section]][indexPath.row];
    SeasonCollectionViewCell *cell= (SeasonCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"seasoncell" forIndexPath:indexPath];
    if (cell == nil && collectionView != self.collectionView) {
        cell = (SeasonCollectionViewCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"seasoncell" forIndexPath:indexPath];
        if (!cell) {
            return [UICollectionViewCell new];
        }
    }
    // Configure the cell
    cell.title.text = entry[@"title"];
    [cell loadimage:entry[@"image_url"]];
    
    return cell ? cell : [UICollectionViewCell new];
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.collectionView.refreshControl.refreshing) {
        NSDictionary *entry = _items[_items.allKeys[indexPath.section]][indexPath.row];
        [self showTitleView:((NSNumber *)entry[@"id"]).intValue withType:(int)_typeselector.selectedSegmentIndex];
        return YES;
    }
    return NO;
}


- (void)showTitleView:(int)titleid withType:(int)type {
    TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
    [self.navigationController pushViewController:titleinfovc animated:YES];
    [titleinfovc loadTitleInfo:titleid withType:type];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = [UICollectionReusableView new];
    if (kind == UICollectionElementKindSectionHeader) {
        TrendingCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        headerView.sectionLabel.text = _items.allKeys[indexPath.section];
        reusableview = headerView;
    }
    return reusableview;
}

#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(113, 180);
}

@end
