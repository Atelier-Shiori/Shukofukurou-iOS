//
//  ListViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ListViewController.h"
#import "listservice.h"
#import "AtarashiiListCoreData.h"
#import "AnimeEntryTableViewCell.h"
#import "MangaEntryTableViewCell.h"
#import "RatingTwentyConvert.h"
#import "AniListScoreConvert.h"
#import "ListSelectorViewController.h"
#import "TitleInfoViewController.h"
#import "CustomListTableViewController.h"
#import "AdvEditTableViewController.h"

@interface ListViewController ()
@property (strong) NSMutableArray *list;
@property (strong) NSArray *filteredlist;
@property (strong) NSArray *searchresults;
@property (strong) NSString *selectedlist;
@property bool isCustomList;
@property (weak, nonatomic) IBOutlet UISearchBar *searchbar;
@property (strong) ListSelectorViewController *listselector;
@end

@implementation ListViewController

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _filteredlist = @[];
    _list = [NSMutableArray new];
    _listselector = (ListSelectorViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ListSelector"];
    __weak ListViewController *weakSelf = self;
    [self restoreSelectedListFromDefaults];
    [self setViewTitle];
    if ([listservice checkAccountForCurrentService]) {
        // Load List
        [self retrieveList:[NSUserDefaults.standardUserDefaults boolForKey:@"refreshlistonstart"] completion:^(bool success) {
            [weakSelf.tableView reloadData];
            [weakSelf.listselector generateLists:[self retrieveEntriesWithType:weakSelf.listtype withFilterPredicate:nil] withListType:weakSelf.listtype];
        }];
    }
    // Set Block
    _listselector.listChanged = ^(NSString * _Nonnull listname, NSString * _Nonnull listtype) {
        weakSelf.selectedlist = listname;
        weakSelf.isCustomList = [listtype isEqualToString:@"Custom Lists"];
        [weakSelf setSelectedListToDefaults];
        [weakSelf populateOwnList];
        [weakSelf setViewTitle];
    };
    // Set Observer
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:_listtype == Anime ? @"AnimeRefreshList" : @"MangaRefreshList" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:_listtype == Anime ? @"AnimeReloadList" : @"MangaReloadList" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"ServiceChanged" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"UserLoggedOut" object:nil];
}

- (void)recieveNotification:(NSNotification *)notification {
    bool refresh = YES;
    if (notification.object && [notification.object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *userinfo = notification.object;
        refresh = ((NSNumber *)userinfo[@"refresh"]).boolValue;
    }
    if (([notification.name isEqualToString:@"AnimeRefreshList"] && _listtype == Anime) || ([notification.name isEqualToString:@"MangaRefreshList"] && _listtype == Manga)) {
        NSLog(@"Refreshing List");
        [self retrieveList:refresh completion:^(bool success) {}];
    }
    else if (([notification.name isEqualToString:@"AnimeReloadList"] && _listtype == Anime) || ([notification.name isEqualToString:@"MangaReloadList"] && _listtype == Manga)) {
        NSLog(@"Reloading List");
        [self reloadList];
    }
    else if ([notification.name isEqualToString:@"ServiceChanged"]) {
        // Reload List
        NSLog(@"Switching Lists");
        [self switchlistservice];
    }
    else if ([notification.name isEqualToString:@"UserLoggedOut"]) {
        // Clear List
        NSLog(@"Clearing Lists");
        
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
- (void)setViewTitle {
    NSString *viewtype;
    switch (_listtype) {
        case Anime:
            viewtype = @"Anime";
            break;
        case Manga:
            viewtype = @"Manga";
            break;
        default:
            break;
    }
    _navigationitem.title = [NSString stringWithFormat:@"%@ - %@", viewtype, !_isCustomList ? _selectedlist.capitalizedString : _selectedlist];
}
- (void)retrieveList:(bool)refresh completion:(void (^)(bool success)) completionHandler {
    bool refreshlist = refresh;
    bool exists = [self hasListEntriesWithType:_listtype];
    if (exists && !refreshlist) {
        [self populateOwnList];
        completionHandler(true);
    }
    else {
        __weak ListViewController *weakSelf = self;
        [listservice retrieveownListWithType:_listtype completion:^(id responseObject) {
            [weakSelf saveEntriesWithDictionary:responseObject withType:weakSelf.listtype];
            // populate list
            [self reloadList];
            completionHandler(true);
        } error:^(NSError *error) {
            NSLog(@"%@", error.userInfo);
            completionHandler(false);
        }];
    }
}
- (void)populateList:(NSDictionary *)list {
    [_list removeAllObjects];
    if (_listtype == Anime) {
        [_list addObjectsFromArray:list[@"anime"]];
    }
    else {
        [_list addObjectsFromArray:list[@"manga"]];
    }
}

- (void)reloadList {
    if (_searchbar.text.length > 0) {
        [self filterWithSearchText:_searchbar.text];
    }
    else {
        [self populateOwnList];
    }
    [self.listselector generateLists:[self retrieveEntriesWithType:self.listtype withFilterPredicate:nil] withListType:self.listtype];
}

- (void)populateOwnList {
    [self populateOwnList:nil];
}

- (void)populateOwnList:(NSPredicate *)filterpredicates {
    [_list removeAllObjects];
    NSPredicate *filterpredicate;
    if (_isCustomList){
        filterpredicate = [NSPredicate predicateWithFormat:@"custom_lists CONTAINS[c] %@", [NSString stringWithFormat:@"%@[true]",_selectedlist]];
    }
    else {
        
        switch (_listtype) {
            case Anime:
                filterpredicate = [NSPredicate predicateWithFormat:@"watched_status ==[c] %@", _selectedlist];
                break;
            case Manga:
                filterpredicate = [NSPredicate predicateWithFormat:@"read_status ==[c] %@", _selectedlist];
                break;
        }
    }
    if (filterpredicates) {
        filterpredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[filterpredicate.copy, filterpredicates]];
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    _filteredlist = [[self retrieveEntriesWithType:_listtype withFilterPredicate:filterpredicate] sortedArrayUsingDescriptors:@[sort]];
    [self.tableView reloadData];
}

- (void)filterList {
    _filteredlist = nil;
    if (_isCustomList){
        _filteredlist = [_list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"custom_lists CONTAINS[c] %@", [NSString stringWithFormat:@"%@[true]",_selectedlist]]];
    }
    else {
        switch (_listtype) {
            case Anime:
            _filteredlist = [_list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"watched_status ==[c] %@", _selectedlist]];
                break;
            case Manga:
            _filteredlist = [_list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"read_status ==[c] %@", _selectedlist]];
                break;
        }
    }
    [self.tableView reloadData];
}

- (IBAction)selectlist:(id)sender {
    UINavigationController *navcontroller = [UINavigationController new];
    _listselector.selectedlist = _selectedlist;
    [navcontroller setViewControllers:@[_listselector]];
    [_listselector.tableView reloadData];
    navcontroller.modalPresentationStyle = UIModalPresentationPopover;
    navcontroller.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:navcontroller animated:YES completion:nil];
}

- (void)switchlistservice {
    [_list removeAllObjects];
    _filteredlist = @[];
    [self restoreSelectedListFromDefaults];
    [self setViewTitle];
    __weak ListViewController *weakSelf = self;
    if ([listservice checkAccountForCurrentService]) {
        // Load List
        [self retrieveList:[NSUserDefaults.standardUserDefaults boolForKey:@"refreshlistonstart"] completion:^(bool success) {
            [weakSelf.tableView reloadData];
            [weakSelf.listselector generateLists:[self retrieveEntriesWithType:weakSelf.listtype withFilterPredicate:nil] withListType:weakSelf.listtype];
        }];
    }
}

- (void)clearlists {
    [_list removeAllObjects];
    _filteredlist = @[];
    [self.tableView reloadData];
}


#pragma mark helpers

- (bool)hasListEntriesWithType:(int)type {
    switch ([listservice getCurrentServiceID]) {
        case 1:
            return [AtarashiiListCoreData hasListEntriesWithUserName:[listservice getCurrentServiceUsername] withService:0 withType:_listtype];
        case 2:
        case 3:
            return [AtarashiiListCoreData hasListEntriesWithUserID:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:_listtype];
        default:
            return false;
    }
}

- (NSArray *)retrieveEntriesWithType:(int)type withFilterPredicate:(NSPredicate *)predicate {
    switch ([listservice getCurrentServiceID]) {
        case 1:
            return [AtarashiiListCoreData retrieveEntriesForUserName:[listservice getCurrentServiceUsername] withService:[listservice getCurrentServiceID] withType:type withPredicate:predicate];
        case 2:
        case 3:
            return [AtarashiiListCoreData retrieveEntriesForUserId:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:type withPredicate:predicate];
        default:
            return false;
    }
}

- (void)saveEntriesWithDictionary:(NSDictionary *)data withType:(int)type {
    switch ([listservice getCurrentServiceID]) {
        case 1:
            [AtarashiiListCoreData insertorupdateentriesWithDictionary:data withUserName:[listservice getCurrentServiceUsername] withService:[listservice getCurrentServiceID] withType:type];
            break;
        case 2:
        case 3:
            [AtarashiiListCoreData insertorupdateentriesWithDictionary:data withUserId:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:type];
            break;
        default:
            break;
    }
}

- (void)setSelectedListToDefaults {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    switch ([listservice getCurrentServiceID]) {
        case 1: {
            if (_listtype == Anime) {
                [defaults setValue:_selectedlist forKey:@"myanimelist-selectedanimelist"];
            }
            else {
                [defaults setValue:_selectedlist forKey:@"myanimelist-selectedmangalist"];
            }
            break;
        }
        case 2: {
            if (_listtype == Anime) {
                [defaults setValue:_selectedlist forKey:@"kitsu-selectedanimelist"];
            }
            else {
                [defaults setValue:_selectedlist forKey:@"kitsu-selectedmangalist"];
            }
            break;
        }
        case 3: {
            if (_listtype == Anime) {
                [defaults setValue:_selectedlist forKey:@"anilist-selectedanimelist"];
                [defaults setBool:_isCustomList forKey:@"anilist-selectedlistcustomlistanime"];
            }
            else {
                [defaults setValue:_selectedlist forKey:@"anilist-selectedmangalist"];
                [defaults setBool:_isCustomList forKey:@"anilist-selectedlistcustomlistmanga"];
            }
            break;
        }
        default:
            break;
    }
}

- (void)restoreSelectedListFromDefaults {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    switch ([listservice getCurrentServiceID]) {
        case 1: {
            if (_listtype == Anime) {
                _selectedlist = [defaults valueForKey:@"myanimelist-selectedanimelist"];
            }
            else {
                _selectedlist = [defaults valueForKey:@"myanimelist-selectedmangalist"];
            }
            _isCustomList = NO;
            break;
        }
        case 2: {
            if (_listtype == Anime) {
                _selectedlist = [defaults valueForKey:@"kitsu-selectedanimelist"];
            }
            else {
                _selectedlist = [defaults valueForKey:@"kitsu-selectedmangalist"];
            }
            _isCustomList = NO;
            break;
        }
        case 3: {
            if (_listtype == Anime) {
                _selectedlist = [defaults valueForKey:@"anilist-selectedanimelist"];
                _isCustomList = [defaults boolForKey:@"anilist-selectedlistcustomlistanime"];
            }
            else {
                _selectedlist = [defaults valueForKey:@"anilist-selectedmangalist"];
                _isCustomList = [defaults boolForKey:@"anilist-selectedlistcustomlistmanga"];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredlist.count;
}

#pragma mark Table View Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_listtype == Anime) {
        return [self generateAnimeEntryCellAtIndexPath:indexPath tableView:tableView];
    }
    else if (_listtype == Manga) {
        return [self generateMangaEntryCellAtIndexPath:indexPath tableView:tableView];
    }
    return [UITableViewCell new];
}

- (UITableViewCell *)generateAnimeEntryCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    NSDictionary *entry = _filteredlist[indexPath.row];
    AnimeEntryTableViewCell *aentrycell = [tableView dequeueReusableCellWithIdentifier:@"animeentrycell"];
    if (aentrycell == nil && tableView != self.tableView) {
        aentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"animeentrycell"];
    }
    aentrycell.title.text = entry[@"title"];
    aentrycell.progress.text = [NSString stringWithFormat:@"Episode: %@/%@", entry[@"watched_episodes"], entry[@"episodes"]];
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
    aentrycell.score.text = [NSString stringWithFormat:@"Score: %@",score];
    [aentrycell loadimage:entry[@"image_url"]];
    
    // Geneerate Swipe Cells
    // Left
    __weak ListViewController *weakSelf = self;
    aentrycell.leftButtons = @[[MGSwipeButton buttonWithTitle:@"Delete" backgroundColor:UIColor.redColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
        [weakSelf deleteTitle:((NSNumber *)entry[@"id"]).intValue withInfo:entry];
        return true;
    }]];
    aentrycell.leftSwipeSettings.transition = MGSwipeTransitionDrag;
    
    //Right
    NSMutableArray *rightbuttons = [NSMutableArray new];
    [rightbuttons addObject:[MGSwipeButton buttonWithTitle:@"Options" backgroundColor:UIColor.grayColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
        [weakSelf showOtherOptions:entry withIndexPath:indexPath];
        return true;
    }]];
    if ([self canIncrement:entry]) {
        [rightbuttons addObject:[MGSwipeButton buttonWithTitle:@"Ep +" backgroundColor:UIColor.greenColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
            [weakSelf incrementProgress:entry];
            return true;
        }]];
    }
    aentrycell.rightButtons = rightbuttons.copy;
    aentrycell.rightSwipeSettings.transition = MGSwipeTransitionDrag;
    return aentrycell;
}

- (UITableViewCell *)generateMangaEntryCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    NSDictionary *entry = _filteredlist[indexPath.row];
    MangaEntryTableViewCell *mentrycell = [tableView dequeueReusableCellWithIdentifier:@"mangaentrycell"];
    if (mentrycell == nil && tableView != self.tableView) {
        mentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"mangaentrycell"];
    }
    mentrycell.title.text = entry[@"title"];
    mentrycell.progress.text = [NSString stringWithFormat:@"Chapters: %@/%@", entry[@"chapters_read"], entry[@"chapters"]];
    mentrycell.progressVolumes.text = [NSString stringWithFormat:@"Volumes: %@/%@", entry[@"volumes_read"], entry[@"volumes"]];
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
    mentrycell.score.text = [NSString stringWithFormat:@"Score: %@",score];
    [mentrycell loadimage:entry[@"image_url"]];
    
    // Geneerate Swipe Cells
    // Left
    __weak ListViewController *weakSelf = self;
    mentrycell.leftButtons = @[[MGSwipeButton buttonWithTitle:@"Delete" backgroundColor:UIColor.redColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
        [weakSelf deleteTitle:((NSNumber *)entry[@"id"]).intValue withInfo:entry];
        return true;
    }]];
    mentrycell.leftSwipeSettings.transition = MGSwipeTransitionDrag;
    
    //Right
    NSMutableArray *rightbuttons = [NSMutableArray new];
    [rightbuttons addObject:[MGSwipeButton buttonWithTitle:@"Options" backgroundColor:UIColor.grayColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
        [weakSelf showOtherOptions:entry withIndexPath:indexPath];
        return true;
    }]];
    if ([self canIncrement:entry]) {
        [rightbuttons addObject:[MGSwipeButton buttonWithTitle:@"Vol +" backgroundColor:UIColor.blueColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
            [weakSelf performMangaIncrement:entry volumeIncrement:YES];
            return true;
        }]];
        [rightbuttons addObject:[MGSwipeButton buttonWithTitle:@"Ch +" backgroundColor:UIColor.greenColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
            [weakSelf performMangaIncrement:entry volumeIncrement:NO];
            return true;
        }]];
    }
    mentrycell.rightButtons = rightbuttons.copy;
    mentrycell.rightSwipeSettings.transition = MGSwipeTransitionDrag;
    return mentrycell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = _filteredlist[indexPath.row];
    int titleid = ((NSNumber *)entry[@"id"]).intValue;
    TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
    [self.navigationController pushViewController:titleinfovc animated:YES];
    [titleinfovc loadTitleInfo:titleid withType:_listtype];

}

- (IBAction)refresh:(UIRefreshControl *)sender {
    // Refreshes list
    __weak ListViewController *weakSelf = self;
    [self retrieveList:true completion:^(bool success) {
        [weakSelf.tableView reloadData];
        [sender endRefreshing];
        [weakSelf.listselector generateLists:[weakSelf retrieveEntriesWithType:weakSelf.listtype withFilterPredicate:nil] withListType:weakSelf.listtype];
    }];
}

#pragma mark UISearchBarDelegate
- (void)filterWithSearchText:(NSString *)searchtext {
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"title CONTAINS[c] %@", searchtext];
    [self populateOwnList:searchPredicate];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        _searchbar.showsCancelButton = NO;
        [self populateOwnList];
    }
    else {
        [self filterWithSearchText:searchText];
        _searchbar.showsCancelButton = YES;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _searchbar.showsCancelButton = NO;
    searchBar.text = @"";
    [self populateOwnList];
    [searchBar resignFirstResponder];
}

#pragma mark Swipe Actions
- (void)deleteTitle:(int)titleid withInfo:(NSDictionary *)info {
    __weak ListViewController *weakSelf = self;
    __block int ntitleid = 0;
    switch ([listservice getCurrentServiceID]) {
        case 1:
            ntitleid = titleid;
            break;
        case 2:
        case 3:
            ntitleid = ((NSNumber *)info[@"entryid"]).intValue;
            break;
        default:
            break;
    }
    UIAlertController *prompt = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Are you sure you want to delete %@ from your list?", info[@"title"]] message:@"Once you delete this title, this cannot be undone." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // Delete Title
        [listservice removeTitleFromList:ntitleid withType:weakSelf.listtype completion:^(id responseObject) {
            switch ([listservice getCurrentServiceID]) {
                case 1:
                    [AtarashiiListCoreData removeSingleEntrywithUserName:[listservice getCurrentServiceUsername] withService:[listservice getCurrentServiceID] withType:weakSelf.listtype withId:ntitleid withIdType:0];
                    break;
                case 2:
                case 3:
                    [AtarashiiListCoreData removeSingleEntrywithUserId:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:weakSelf.listtype withId:ntitleid withIdType:1];
                    break;
                default:
                    break;
            }
            [self reloadList];
        } error:^(NSError *error) {
        }];
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    [prompt addAction:yesaction];
    [prompt addAction:noaction];
    [self presentViewController:prompt animated:YES completion:nil];
}

- (void)incrementProgress:(NSDictionary *)entry {
    int currentservice = [listservice getCurrentServiceID];
    int titleid = -1;
    switch (currentservice) {
        case 1:
            titleid = ((NSNumber *)entry[@"id"]).intValue;
            break;
        case 2:
        case 3: {
            titleid = ((NSNumber *)entry[@"entryid"]).intValue;
            break;
        }
        default:
            break;
    }
    
    bool rewatching = ((NSNumber *)entry[@"rewatching"]).boolValue;
    NSString *airingstatus = entry[@"status"];
    bool selectedaircompleted;
    bool selectedaired;
    NSString *watchstatus = entry[@"watched_status"];
    int watchedepisodes = ((NSNumber *)entry[@"watched_episodes"]).intValue+1;
    int episodes = ((NSNumber *)entry[@"episodes"]).intValue;
    if ([airingstatus isEqualToString:@"finished airing"]) {
        selectedaircompleted = true;
    }
    else {
        selectedaircompleted = false;
    }
    if ([airingstatus isEqualToString:@"finished airing"]||[airingstatus isEqualToString:@"currently airing"]) {
        selectedaired = true;
    }
    else {
        selectedaired = false;
    }
    if (!selectedaired && (![watchstatus isEqual:@"plan to watch"] || watchedepisodes > 0)) {
        // Invalid input, mark it as such
        return;
    }
    else if (selectedaired && [watchstatus isEqual:@"plan to watch"])  {
        watchstatus = @"watching";
    }
    if (watchedepisodes == episodes && episodes != 0 && selectedaircompleted && selectedaired) {
        watchstatus = @"completed";
        watchedepisodes = episodes;
        rewatching = false;
    }
    else if (watchedepisodes > episodes && episodes > 0) {
        return;
    }
    NSDictionary * extraparameters = @{};
    switch (currentservice) {
        case 2:
        case 3: {
            extraparameters = @{@"reconsuming" : @(rewatching)};
            break;
        }
        default:
            break;
    }
    int score = ((NSNumber *)entry[@"score"]).intValue;;
    [listservice updateAnimeTitleOnList:titleid withEpisode:watchedepisodes withStatus:watchstatus withScore:score withExtraFields:extraparameters completion:^(id responseobject) {
        NSDictionary *updatedfields = @{@"watched_episodes" : @(watchedepisodes), @"watched_status" : watchstatus, @"score" : @(score), @"rewatching" : @(rewatching)};
        switch ([listservice getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserName:[listservice getCurrentServiceUsername] withService:[listservice getCurrentServiceID] withType:0 withId:titleid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:0 withId:titleid withIdType:1];
                break;
        }
        [self reloadList];
    }
    error:^(NSError * error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

- (void)performMangaIncrement:(NSDictionary *)entry volumeIncrement:(bool)volumeIncrement {
    int currentservice = [listservice getCurrentServiceID];
    int titleid = -1;
    switch (currentservice) {
        case 1:
            titleid = ((NSNumber *)entry[@"id"]).intValue;
            break;
        case 2:
        case 3: {
            titleid = ((NSNumber *)entry[@"entryid"]).intValue;
            break;
        }
        default:
            break;
    }
    
    bool rereading = ((NSNumber *)entry[@"rereading"]).boolValue;
    NSString *publishstatus = entry[@"status"];
    bool selectedfinished;
    bool selectedpublished;
    NSString *readstatus = entry[@"read_status"];
    int readchapters = !volumeIncrement ? ((NSNumber *)entry[@"chapters_read"]).intValue+1 : ((NSNumber *)entry[@"chapters_read"]).intValue;
    int readvolumes = volumeIncrement ? ((NSNumber *)entry[@"volumes_read"]).intValue+1 : ((NSNumber *)entry[@"volumes_read"]).intValue;
    int chapters = ((NSNumber *)entry[@"chapters"]).intValue;
    int volumes = ((NSNumber *)entry[@"volumes"]).intValue;
    if ([publishstatus isEqualToString:@"finished"]) {
        selectedfinished = true;
    }
    else {
        selectedfinished = false;
    }
    if ([publishstatus isEqualToString:@"finished"]||[publishstatus isEqualToString:@"publishing"]) {
        selectedpublished = true;
    }
    else {
        selectedpublished = false;
    }
    if (!selectedpublished && (![readstatus isEqual:@"plan to read"] || readchapters > 0 || readvolumes > 0))  {
        // Invalid input, mark it as such
        return;
    }
    else if (selectedpublished && [readstatus isEqual:@"plan to read"])  {
        // Invalid input, mark it as such
        readstatus = @"reading";
    }
    if (readchapters == chapters && chapters != 0 && selectedpublished && selectedfinished) {
        readstatus = @"completed";
        readchapters = chapters;
        readvolumes = volumes;
        rereading = false;
    }
    else if (readchapters > chapters && chapters > 0) {
        return;
    }
    NSDictionary * extraparameters = @{};
    switch (currentservice) {
        case 2:
        case 3: {
            extraparameters = @{@"reconsuming" : @(rereading)};
            break;
        }
        default:
            break;
    }
    int score = ((NSNumber *)entry[@"score"]).intValue;;
    [listservice updateMangaTitleOnList:titleid withChapter:readchapters withVolume:readvolumes withStatus:readstatus withScore:score withExtraFields:extraparameters completion:^(id responseObject) {
        NSDictionary *updatedfields = @{@"chapters_read" : @(readchapters), @"volumes_read" : @(readvolumes), @"read_status" : readstatus, @"score" : @(score), @"rereading" : @(rereading)};
        switch ([listservice getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserName:[listservice getCurrentServiceUsername] withService:[listservice getCurrentServiceID] withType:1 withId:titleid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:1 withId:titleid withIdType:1];
                break;
        }
        [self reloadList];
    } error:^(NSError *error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

- (bool)canIncrement:(NSDictionary *)entry {
    switch (self.listtype) {
        case 0: {
            NSString *airingstatus = entry[@"status"];
            bool selectedaircompleted;
            bool selectedaired;
            NSString *watchstatus = entry[@"watched_status"];
            int watchedepisodes = ((NSNumber *)entry[@"watched_episodes"]).intValue+1;
            int episodes = ((NSNumber *)entry[@"episodes"]).intValue;
            if ([airingstatus isEqualToString:@"finished airing"]) {
                selectedaircompleted = true;
            }
            else {
                selectedaircompleted = false;
            }
            if ([airingstatus isEqualToString:@"finished airing"]||[airingstatus isEqualToString:@"currently airing"]) {
                selectedaired = true;
            }
            else {
                selectedaired = false;
            }
            if (!selectedaired && (![watchstatus isEqual:@"plan to watch"] || watchedepisodes > 0)) {
                // Invalid input, mark it as such
                return false;
            }
            if (watchedepisodes > episodes && episodes > 0) {
                return false;
            }
            return true;
        }
        case 1: {
            NSString *publishstatus = entry[@"status"];
            bool selectedfinished;
            bool selectedpublished;
            NSString *readstatus = entry[@"read_status"];
            int readchapters = ((NSNumber *)entry[@"chapters_read"]).intValue+1;
            int readvolumes = ((NSNumber *)entry[@"volumes_read"]).intValue;
            int chapters = ((NSNumber *)entry[@"chapters"]).intValue;
            if ([publishstatus isEqualToString:@"finished"]) {
                selectedfinished = true;
            }
            else {
                selectedfinished = false;
            }
            if ([publishstatus isEqualToString:@"finished"]||[publishstatus isEqualToString:@"publishing"]) {
                selectedpublished = true;
            }
            else {
                selectedpublished = false;
            }
            if (!selectedpublished && (![readstatus isEqual:@"plan to read"] || readchapters > 0 || readvolumes > 0))  {
                // Invalid input, mark it as such
                return false;
            }
            if (readchapters > chapters && chapters > 0) {
                return false;
            }
            return true;
        }
        default:
            return false;
    }
}

- (void)showOtherOptions:(NSDictionary *)entry withIndexPath:(NSIndexPath *)indexpath {
    int titleid = ((NSNumber *)entry[@"id"]).intValue;
    int currentservice = [listservice getCurrentServiceID];
    __weak ListViewController *weakSelf = self;
    UIAlertController *options = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
    options.popoverPresentationController.sourceView = cell;
    options.popoverPresentationController.sourceRect = cell.bounds;
    options.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
    [options addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"View on %@", [listservice currentservicename]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performViewOnListSite:titleid];
    }]];
    [options addAction:[UIAlertAction actionWithTitle:@"Advanced Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UINavigationController *navController = [UINavigationController new];
        AdvEditTableViewController *advedit = [[UIStoryboard storyboardWithName:@"AdvancedEdit" bundle:nil] instantiateViewControllerWithIdentifier:@"advedit"];
        [advedit populateTableViewWithID:((NSNumber *)entry[@"id"]).intValue withEntryDictionary:entry withType:weakSelf.listtype];
        advedit.entryUpdated = ^(int listtype) {
            [weakSelf reloadList];
        };
        navController.viewControllers = @[advedit];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:^{}];
    }]];
    if (currentservice == 3) {
        [options addAction:[UIAlertAction actionWithTitle:@"Manage Custom Lists" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UINavigationController *navcontroller = [UINavigationController new];
            CustomListTableViewController *clvc = [[UIStoryboard storyboardWithName:@"CustomList" bundle:nil] instantiateViewControllerWithIdentifier:@"customlistedit"];
            navcontroller.modalPresentationStyle = UIModalPresentationFormSheet;
            [navcontroller setViewControllers:@[clvc]];
            [self presentViewController:navcontroller animated:YES completion:nil];
            [clvc viewDidLoad];
            [clvc populateCustomLists:entry withCurrentType:weakSelf.listtype withSelectedId:((NSNumber *)entry[@"entryid"]).intValue];
        }]];
    }
    [options addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performShare:titleid withCell:cell];
    }]];
    [options addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];

    [self
     presentViewController:options
     animated:YES
     completion:nil];
}

- (void)performViewOnListSite:(int)titleid {
    NSString *URL = [self getTitleURL:titleid];
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:URL] options:@{} completionHandler:^(BOOL success) {}];
}

- (void)performShare:(int)titleid withCell:(UITableViewCell *)cell{
    NSArray *activityItems = @[[NSURL URLWithString:[self getTitleURL:titleid]]];
    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    activityViewControntroller.popoverPresentationController.sourceView = cell;
    activityViewControntroller.popoverPresentationController.sourceRect = cell.bounds;
    activityViewControntroller.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
    [self presentViewController:activityViewControntroller animated:true completion:nil];
}

# pragma mark helpers
- (NSString *)getTitleURL:(int)titleid {
    switch ([listservice getCurrentServiceID]) {
        case 1: {
            if (_listtype == Anime){
                return [NSString stringWithFormat:@"https://myanimelist.net/anime/%i",titleid];
            }
            else {
                return [NSString stringWithFormat:@"https://myanimelist.net/manga/%i",titleid];
            }
        }
        case 2: {
            if (_listtype == Anime) {
                return [NSString stringWithFormat:@"https://kitsu.io/anime/%i",titleid];
            }
            else {
                return [NSString stringWithFormat:@"https://kitsu.io/manga/%i",titleid];
            }
            
        }
        case 3: {
            if (_listtype == Anime) {
                return [NSString stringWithFormat:@"https://anilist.co/anime/%i",titleid];
            }
            else {
                return [NSString stringWithFormat:@"https://anilist.co/manga/%i",titleid];
            }
        }
        default:
            return @"";
    }
}
@end
