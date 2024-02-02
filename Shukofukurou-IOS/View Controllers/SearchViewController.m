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
#import "CharacterDetailViewController.h"
#import "SearchAdvSettings.h"

@interface SearchViewController ()
@property (strong) UISearchController *searchController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *searchselector;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;
@property bool loadingsearch;
@property int nextpage;
@property bool hasnextpage;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *advsearchtoolbaritem;
@property (strong) SearchAdvSettings *advsearchoptions;
@end

@implementation SearchViewController

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"SearchTableViewCell" bundle:nil] forCellReuseIdentifier:@"searchcell"];
    __weak SearchViewController *weakSelf = self;
    _advsearchoptions = [self.storyboard instantiateViewControllerWithIdentifier:@"advsearchopt"];
    _advsearchoptions.completionHandler = ^(NSDictionary * _Nonnull advsearchoptions) {
        if (weakSelf.searchController.searchBar.text.length > 0) {
            [weakSelf performSearch:weakSelf.searchController.searchBar.text];
        }
    };
    [_advsearchoptions viewDidLoad];
    [self setsegment];
    _searchArray = [NSMutableArray new];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ServiceChanged" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sidebarShowAlwaysNotification:) name:@"sidebarStateDidChange" object:nil];
    [self hidemenubtn];
    [self setupsearch];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

- (void)viewDidAppear:(BOOL)animated {
    self.navigationController.toolbarHidden = NO;
    if ([listservice.sharedInstance getCurrentServiceID] == 1) {
        _advsearchtoolbaritem.enabled = NO;
    }
    else {
        _advsearchtoolbaritem.enabled = YES;
    }
}

- (void)setupsearch {
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchBar.placeholder = @"Search";
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    self.navigationItem.searchController = _searchController;
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
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomVision) {
        [self.menubtn setEnabled:NO];
        [self.menubtn setTintColor: [UIColor clearColor]];
    }
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"ServiceChanged"]) {
        // Reload Search Results
        long selectedsegment = [NSUserDefaults.standardUserDefaults integerForKey:@"selectedsearchtype"];
        bool loadsearch = true;
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
            case 2:
                loadsearch = selectedsegment <= 1;
                break;
        }
        [self setsegment];
        if (_searchController.searchBar.text.length > 0 && loadsearch) {
            [self performSearch:_searchController.searchBar.text];
        }
        else {
            [self resetSearchUI];
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
    _loadingsearch = true;
    if (_searchselector.selectedSegmentIndex <= 1) {
        [listservice.sharedInstance searchTitle:searchtext withType:_searchtype withSearchOptions:_advsearchoptions.advsearchoptions completion:^(id responseObject, int nextoffset, bool hasnextpage) {
            [weakSelf clearsearch];
            [weakSelf.searchArray addObjectsFromArray:responseObject];
            [weakSelf.tableView reloadData];
            weakSelf.nextpage = nextoffset;
            weakSelf.hasnextpage = hasnextpage;
            weakSelf.loadingsearch = false;
        } error:^(NSError *error) {
            NSLog(@"Search Failed: %@", error.localizedDescription);
            weakSelf.loadingsearch = false;
            NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",errResponse);
        }];
    }
    else {
        [listservice.sharedInstance .anilistManager searchPeople:searchtext withType:(int)_searchselector.selectedSegmentIndex - 2 completion:^(id responseObject) {
            [weakSelf clearsearch];
            [weakSelf.searchArray addObjectsFromArray:responseObject];
            [weakSelf.tableView reloadData];
        } error:^(NSError *error) {
            NSLog(@"Search Failed: %@", error.localizedDescription);
            NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",errResponse);
        }];
    }
}

- (void)loadMoreSearchResults:(NSString *)searchtext  {
    __weak SearchViewController *weakSelf = self;
    if (_searchselector.selectedSegmentIndex <= 1) {
         _loadingsearch = true;
        [listservice.sharedInstance searchTitle:searchtext withType:_searchtype withOffset:_nextpage withSearchOptions:_advsearchoptions.advsearchoptions completion:^(id responseObject, int nextoffset, bool hasnextpage) {
            [weakSelf.searchArray addObjectsFromArray:responseObject];
            [weakSelf.tableView reloadData];
            weakSelf.nextpage = nextoffset;
            weakSelf.hasnextpage = hasnextpage;
            weakSelf.loadingsearch = false;
        } error:^(NSError *error) {
            NSLog(@"Search Failed: %@", error.localizedDescription);
             weakSelf.loadingsearch = false;
        }];
    }
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
    _nextpage = 0;
    _hasnextpage = false;
    [self resetAdvancedSearchOptions];
    [self setAdvancedSearchToolBarItemState];
}

- (void)setsegment {
    NSArray *segmentitems;
    long selectedsegment = [NSUserDefaults.standardUserDefaults integerForKey:@"selectedsearchtype"];
    [_searchselector removeAllSegments];
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1:
        case 2:
            segmentitems = @[@"Anime", @"Manga"];
            if (selectedsegment > 1) {
                selectedsegment = 0;
            }
            break;
        case 3:
            segmentitems = @[@"Anime", @"Manga", @"Characters", @"Staff"];
            break;
    }
    for (NSString *segmentstr in segmentitems) {
        [_searchselector insertSegmentWithTitle:segmentstr atIndex:_searchselector.numberOfSegments animated:NO];
    }
    _searchselector.selectedSegmentIndex = selectedsegment;
    _searchtype = (int)_searchselector.selectedSegmentIndex;
    [NSUserDefaults.standardUserDefaults setInteger:selectedsegment forKey:@"selectedsearchtype"];
    [_advsearchoptions generateSearchOptionsForType:(int)selectedsegment];
    [self setAdvancedSearchToolBarItemState];
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
     else if (_searchtype == CharacterSearchType || _searchtype == StaffSearchType) {
         return [self generateSearchPersonEntryCellAtIndexPath:indexPath tableView:tableView];
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
    if (!_loadingsearch && _hasnextpage && indexPath.row == _searchArray.count-1) {
        [self loadMoreSearchResults:self.searchController.searchBar.text];
    }
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
    if (!_loadingsearch && _hasnextpage && indexPath.row == _searchArray.count-1) {
        [self loadMoreSearchResults:self.searchController.searchBar.text];
    }
    return mentrycell;
}

- (UITableViewCell *)generateSearchPersonEntryCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    NSDictionary *entry = _searchArray[indexPath.row];
    SearchTableViewCell *mentrycell = [tableView dequeueReusableCellWithIdentifier:@"searchcell"];
    if (mentrycell == nil && tableView != self.tableView) {
        mentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"searchcell"];
    }
    mentrycell.title.text = entry[@"name"];
    mentrycell.progress.text = @"";
    mentrycell.progressVolumes.text = @"";
    mentrycell.type.text = @"";
    [mentrycell loadimage:entry[@"image"]];
    mentrycell.active.hidden = true;
    return mentrycell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _searchArray[indexPath.row];
    int titleid = ((NSNumber *)entry[@"id"]).intValue;
    if (_searchtype == AnimeSearchType || _searchtype == MangaSearchType) {
        TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
        [self.navigationController pushViewController:titleinfovc animated:YES];
        [titleinfovc loadTitleInfo:titleid withType:_searchtype];
    }
    else if (_searchtype == CharacterSearchType || _searchtype == StaffSearchType) {
        CharacterDetailViewController *characterdetailvc = (CharacterDetailViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"characterdetail"];
        [self.navigationController pushViewController:characterdetailvc animated:YES];
        if (_searchtype == CharacterSearchType) {
            [characterdetailvc retrieveCharacterDetailsForID:titleid];
        }
        else {
            [characterdetailvc retrievePersonDetailsForID:titleid];
        }
    }
    self.navigationController.toolbarHidden = YES;
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
        [self resetAdvancedSearchOptions];
    }
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _searchController.searchBar.showsCancelButton = NO;
    searchBar.text = @"";
    [self clearsearch];
    [self resetAdvancedSearchOptions];
    [searchBar resignFirstResponder];
}

#pragma mark Advanced Search
- (IBAction)showAdvancedSearch:(id)sender {
    [_advsearchoptions populateSearchOptionsForType:(int)_searchselector.selectedSegmentIndex];
    UINavigationController *navcontroller = [UINavigationController new];
    navcontroller.viewControllers = @[_advsearchoptions];
    navcontroller.navigationBar.hidden = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navcontroller.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:navcontroller animated:YES completion:nil];
}

- (void)setAdvancedSearchToolBarItemState {
    if (_searchselector.selectedSegmentIndex > 1) {
        _advsearchtoolbaritem.enabled = NO;
    }
    else {
        _advsearchtoolbaritem.enabled = YES;
    }
}

- (void)resetAdvancedSearchOptions {
    if (_searchselector.selectedSegmentIndex < 1) {
        [_advsearchoptions generateSearchOptionsForType:(int)_searchselector.selectedSegmentIndex];
    }
}

@end
