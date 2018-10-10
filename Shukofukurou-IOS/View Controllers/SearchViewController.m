//
//  SearchViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/30.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SearchViewController.h"
#import "ViewControllerManager.h"
#import "SearchTableViewCell.h"
#import "listservice.h"
#import "RatingTwentyConvert.h"
#import "AniListScoreConvert.h"
#import "TitleInfoViewController.h"

@interface SearchViewController ()
@property (strong) UISearchController *searchController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *searchselector;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;

@end

@implementation SearchViewController

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _searchArray = [NSMutableArray new];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"ServiceChanged" object:nil];
    _searchselector.selectedSegmentIndex = [NSUserDefaults.standardUserDefaults integerForKey:@"selectedsearchtype"];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sidebarShowAlwaysNotification:) name:@"sidebarStateDidChange" object:nil];
    [self hidemenubtn];
    [self setupsearch];
}

- (void)setupsearch {
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchBar.placeholder = @"Search";
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    self.navigationItem.searchController = _searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
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

- (void)recieveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"ServiceChanged"]) {
        // Reload Search Results
        if (_searchController.searchBar.text.length > 0) {
            [self performSearch:_searchController.searchBar.text];
        }
    }
}


- (IBAction)searchchanged:(id)sender {
    _searchtype = (int)_searchselector.selectedSegmentIndex;
    [NSUserDefaults.standardUserDefaults setInteger:_searchselector.selectedSegmentIndex forKey:@"selectedsearchtype"];
    [self resetSearchUI];
}


- (void)performSearch:(NSString *)searchtext {
    __weak SearchViewController *weakSelf = self;
    [listservice searchTitle:searchtext withType:_searchtype completion:^(id responseObject) {
        [weakSelf clearsearch];
        [weakSelf.searchArray addObjectsFromArray:responseObject];
        [weakSelf.tableView reloadData];
    } error:^(NSError *error) {
        NSLog(@"Search Failed: %@", error.localizedDescription);
    }];
}

- (void)clearsearch {
    [_searchArray removeAllObjects];
    [self.tableView reloadData];
}

- (void)resetSearchUI {
    _searchController.searchBar.showsCancelButton = NO;
    _searchController.searchBar.text = @"";
    [self clearsearch];
    [_searchController.searchBar resignFirstResponder];
}

#pragma mark - Table view data source
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    return tableView.sectionHeaderHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _searchArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     if (_searchtype == AnimeSearchType) {
         return [self generateAnimeSearchEntryCellAtIndexPath:indexPath tableView:tableView];
     }
     else if (_searchtype == MangaSearchType) {
         return [self generateSearchMangaEntryCellAtIndexPath:indexPath tableView:tableView];
     }
     return [UITableViewCell new];
 }

- (UITableViewCell *)generateAnimeSearchEntryCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    NSDictionary *entry = _searchArray[indexPath.row];
    SearchTableViewCell *aentrycell = [tableView dequeueReusableCellWithIdentifier:@"searchcell"];
    if (aentrycell == nil && tableView != self.tableView) {
        aentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"searchcell"];
    }
    aentrycell.title.text = entry[@"title"];
    aentrycell.progress.text = [NSString stringWithFormat:@"Episodes: %@", entry[@"episodes"]];
    aentrycell.type.text = [NSString stringWithFormat:@"Type: %@", entry[@"type"]];
    [aentrycell loadimage:entry[@"image_url"]];
    aentrycell.active.hidden = ![(NSString *)entry[@"status"] isEqualToString:@"currently airing"];
    return aentrycell;
}

- (UITableViewCell *)generateSearchMangaEntryCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    NSDictionary *entry = _searchArray[indexPath.row];
    SearchTableViewCell *mentrycell = [tableView dequeueReusableCellWithIdentifier:@"searchcell"];
    if (mentrycell == nil && tableView != self.tableView) {
        mentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"searchcell"];
    }
    mentrycell.title.text = entry[@"title"];
    mentrycell.progress.text = [NSString stringWithFormat:@"Chapters: %@", entry[@"chapters"]];
    mentrycell.progressVolumes.text = [NSString stringWithFormat:@"Volumes: %@", entry[@"volumes"]];
    mentrycell.type.text = [NSString stringWithFormat:@"Type: %@", entry[@"type"]];
    [mentrycell loadimage:entry[@"image_url"]];
    mentrycell.active.hidden = ![(NSString *)entry[@"status"] isEqualToString:@"publishing"];
    return mentrycell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _searchArray[indexPath.row];
    int titleid = ((NSNumber *)entry[@"id"]).intValue;
    TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
    [self.navigationController pushViewController:titleinfovc animated:YES];
    [titleinfovc loadTitleInfo:titleid withType:_searchtype];
}

#pragma mark UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performSearch:searchBar.text];
    _searchController.searchBar.showsCancelButton = YES;
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        _searchController.searchBar.showsCancelButton = NO;
        [self clearsearch];
    }
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _searchController.searchBar.showsCancelButton = NO;
    searchBar.text = @"";
    [self clearsearch];
    [searchBar resignFirstResponder];
}

@end
