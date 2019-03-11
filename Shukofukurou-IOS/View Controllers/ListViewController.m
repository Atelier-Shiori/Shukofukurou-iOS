//
//  ListViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ListViewController.h"
#import "AiringNotificationManager.h"
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
#import "ViewControllerManager.h"
#import "SortTableViewController.h"
#import "MBProgressHUD.h"
#import "ThemeManager.h"
#import "Utility.h"

@interface ListViewController ()
@property (strong) NSMutableArray *list;
@property (strong) NSArray *filteredlist;
@property (strong) NSArray *searchresults;
@property (strong) NSString *selectedlist;
@property bool isCustomList;
@property (strong) UISearchController *searchController;
@property (strong) ListSelectorViewController *listselector;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;
@property (strong) MBProgressHUD *hud;
@property bool refreshing;
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
    if ([listservice.sharedInstance checkAccountForCurrentService]) {
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
        if (weakSelf.filteredlist.count > 0) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    };
    // Set Observer
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:_listtype == Anime ? @"AnimeRefreshList" : @"MangaRefreshList" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:_listtype == Anime ? @"AnimeReloadList" : @"MangaReloadList" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ServiceChanged" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"UserLoggedOut" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sidebarShowAlwaysNotification:) name:@"sidebarStateDidChange" object:nil];
    [self hidemenubtn];
    [self setupsearch];
}

- (void)setupsearch {
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchBar.placeholder = @"Filter";
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    self.navigationitem.searchController = _searchController;
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

- (void)receiveNotification:(NSNotification *)notification {
    if (([notification.name isEqualToString:@"AnimeRefreshList"] && _listtype == Anime) || ([notification.name isEqualToString:@"MangaRefreshList"] && _listtype == Manga)) {
        NSLog(@"Refreshing List");
        [self refreshListWithCompletionHandler:^(bool success) {
        }];
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
        [self clearlists];
    }
}

- (void)setViewTitle {
    _navigationitem.title =  !_isCustomList ? _selectedlist.capitalizedString : _selectedlist;
}

- (void)refreshListWithCompletionHandler:(void (^)(bool success)) completionHandler {
    NSLog(@"Refreshing List");
    if (_initalload) {
        [_refreshcontrol beginRefreshing];
    }
    else {
        if (_refreshing) {
            return;
        }
    }
    [self retrieveList:true completion:^(bool success) {
        NSLog(@"Refreshed: %i", success);
        [self.tableView reloadData];
        [self.listselector generateLists:[self retrieveEntriesWithType:self.listtype withFilterPredicate:nil] withListType:self.listtype];
        [self.refreshControl endRefreshing];
        completionHandler(success);
    }];
}

- (void)retrieveList:(bool)refresh completion:(void (^)(bool success)) completionHandler {
    bool refreshlist = refresh;
    bool exists = [self hasListEntriesWithType:_listtype];
    if (exists && !refreshlist) {
        [self populateOwnList];
        completionHandler(true);
    }
    else {
        if (_initalload) {
            [_refreshcontrol beginRefreshing];
        }
        else {
            [self showloadingview:YES];
        }
        [listservice.sharedInstance retrieveownListWithType:_listtype completion:^(id responseObject) {
            [self saveEntriesWithDictionary:responseObject withType:self.listtype];
            // populate list
            [self reloadList];
            if (self.listtype == Anime && [AiringNotificationManager airingNotificationServiceSource] == [listservice.sharedInstance getCurrentServiceID]) {
                AiringNotificationManager *anm = [AiringNotificationManager sharedAiringNotificationManager];
                [anm checknotifications:^(bool success) {
                    [self.refreshControl endRefreshing];
                    [self showloadingview:NO];
                    completionHandler(true);
                }];
            }
            else {
                [self.refreshControl endRefreshing];
                [self showloadingview:NO];
                completionHandler(true);
            }
        } error:^(NSError *error) {
            NSLog(@"%@", error.userInfo);
            [self.refreshControl endRefreshing];
            [self showloadingview:NO];
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
    if (_searchController.searchBar.text.length > 0) {
        [self filterWithSearchText:_searchController.searchBar.text];
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
            default:
                return;
        }
    }
    if (filterpredicates) {
        filterpredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[filterpredicate.copy, filterpredicates]];
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:[self getSortBy] ascending:[self getAccending]];
    _filteredlist = [[self retrieveEntriesWithType:_listtype withFilterPredicate:filterpredicate] sortedArrayUsingDescriptors:@[sort]];
    [self.tableView reloadData];
    _initalload = true;
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
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navcontroller.modalPresentationStyle = UIModalPresentationPopover;
        navcontroller.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:navcontroller animated:YES completion:nil];
}

- (void)switchlistservice {
    [_list removeAllObjects];
    _filteredlist = @[];
    [self restoreSelectedListFromDefaults];
    [self setViewTitle];
    __weak ListViewController *weakSelf = self;
    if ([listservice.sharedInstance checkAccountForCurrentService]) {
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
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1:
            return [AtarashiiListCoreData hasListEntriesWithUserName:[listservice.sharedInstance getCurrentServiceUsername] withService:0 withType:_listtype];
        case 2:
        case 3:
            return [AtarashiiListCoreData hasListEntriesWithUserID:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:_listtype];
        default:
            return false;
    }
}

- (NSArray *)retrieveEntriesWithType:(int)type withFilterPredicate:(NSPredicate *)predicate {
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1:
            return [AtarashiiListCoreData retrieveEntriesForUserName:[listservice.sharedInstance getCurrentServiceUsername] withService:[listservice.sharedInstance getCurrentServiceID] withType:type withPredicate:predicate];
        case 2:
        case 3:
            return [AtarashiiListCoreData retrieveEntriesForUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:type withPredicate:predicate];
        default:
            return nil;
    }
}

- (void)saveEntriesWithDictionary:(NSDictionary *)data withType:(int)type {
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1:
            [AtarashiiListCoreData insertorupdateentriesWithDictionary:data withUserName:[listservice.sharedInstance getCurrentServiceUsername] withService:[listservice.sharedInstance getCurrentServiceID] withType:type];
            break;
        case 2:
        case 3:
            [AtarashiiListCoreData insertorupdateentriesWithDictionary:data withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:type];
            break;
        default:
            break;
    }
}

- (void)setSelectedListToDefaults {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    switch ([listservice.sharedInstance getCurrentServiceID]) {
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
    switch ([listservice.sharedInstance getCurrentServiceID]) {
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    return tableView.sectionHeaderHeight;
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
    if (indexPath.row < _filteredlist.count) {
        NSDictionary *entry = _filteredlist[indexPath.row];
        AnimeEntryTableViewCell *aentrycell = [tableView dequeueReusableCellWithIdentifier:@"animeentrycell"];
        if (aentrycell == nil && tableView != self.tableView) {
            aentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"animeentrycell"];
        }
        aentrycell.title.text = entry[@"title"];
        aentrycell.progress.text = [NSString stringWithFormat:@"Episode: %@/%@", entry[@"watched_episodes"], entry[@"episodes"]];
        NSString *score = @"";
        switch ([listservice.sharedInstance getCurrentServiceID]) {
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
        aentrycell.active.hidden = ![(NSString *)entry[@"status"] isEqualToString:@"currently airing"];
        // Geneerate Swipe Cells
        // Left
        __weak ListViewController *weakSelf = self;
        int currentservice = [listservice.sharedInstance getCurrentServiceID];
        aentrycell.leftButtons = @[[MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"delete"] backgroundColor:UIColor.redColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
            [weakSelf deleteTitle:((NSNumber *)entry[@"id"]).intValue withInfo:entry];
            return true;
        }]];
        aentrycell.leftSwipeSettings.transition = MGSwipeTransitionDrag;
        
        //Right
        NSMutableArray *rightregularbuttons = [NSMutableArray new];
        NSMutableArray *rightcompactbuttons = [NSMutableArray new];
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            aentrycell.viewonsiteswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"TitleInfo"] backgroundColor:[UIColor colorWithRed:1.00 green:0.80 blue:0.00 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf performViewOnListSite:((NSNumber *)entry[@"id"]).intValue];
                return true;
            }];

            aentrycell.adveditswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"advedit"] backgroundColor:[UIColor colorWithRed:1.00 green:0.58 blue:0.00 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf performAdvancedEditwithEntry:entry withType:weakSelf.listtype];
                return true;
            }];
            if (currentservice == 3) {
                aentrycell.customlistbutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"customlist"] backgroundColor:[UIColor colorWithRed:0.35 green:0.34 blue:0.84 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                    NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                    [weakSelf performCustomListEdit:((NSNumber *)entry[@"entryid"]).intValue withEntry:entry];
                    return true;
                }];
            }
            aentrycell.shareswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"share"] backgroundColor:UIColor.grayColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf performShare:((NSNumber *)entry[@"id"]).intValue withCell:aentrycell];
                return true;
            }];
        }
        
        aentrycell.optionswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"option"] backgroundColor:UIColor.grayColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
            [weakSelf showOtherOptions:entry withIndexPath:indexPath];
            return true;
        }];
        
        // Set Swipe Button Array
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [rightregularbuttons addObject:aentrycell.shareswipebutton];
            if (currentservice == 3) {
                [rightregularbuttons addObject:aentrycell.customlistbutton];
            }
            [rightregularbuttons addObject:aentrycell.adveditswipebutton];
            [rightregularbuttons addObject:aentrycell.viewonsiteswipebutton];
            for (MGSwipeButton *btn in rightregularbuttons) {
                [btn iconTintColor:[UIColor whiteColor]];
            }
        }
        [rightcompactbuttons addObject:aentrycell.optionswipebutton];
        
        if ([self canIncrement:entry]) {
            aentrycell.incrementswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"increment"] backgroundColor:[UIColor colorWithRed:0.33 green:0.84 blue:0.41 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf incrementProgress:entry];
                return true;
            }];
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [rightregularbuttons addObject:aentrycell.incrementswipebutton];
            }
            [rightcompactbuttons addObject:aentrycell.incrementswipebutton];
        }
        for (MGSwipeButton *btn in rightcompactbuttons) {
            [btn iconTintColor:[UIColor whiteColor]];
        }
        aentrycell.regularswipebuttons = rightregularbuttons.copy;
        aentrycell.compactswipebuttons = rightcompactbuttons.copy;
        [aentrycell setSwipeButtons];
        aentrycell.rightSwipeSettings.transition = MGSwipeTransitionDrag;
        return aentrycell;
    }
    else {
        return [UITableViewCell new];
    }
}

- (UITableViewCell *)generateMangaEntryCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    if (indexPath.row < _filteredlist.count) {
        NSDictionary *entry = _filteredlist[indexPath.row];
        MangaEntryTableViewCell *mentrycell = [tableView dequeueReusableCellWithIdentifier:@"mangaentrycell"];
        if (mentrycell == nil && tableView != self.tableView) {
            mentrycell = [self.tableView dequeueReusableCellWithIdentifier:@"mangaentrycell"];
        }
        mentrycell.title.text = entry[@"title"];
        mentrycell.progress.text = [NSString stringWithFormat:@"Chapters: %@/%@", entry[@"chapters_read"], entry[@"chapters"]];
        mentrycell.progressVolumes.text = [NSString stringWithFormat:@"Volumes: %@/%@", entry[@"volumes_read"], entry[@"volumes"]];
        NSString *score = @"";
        switch ([listservice.sharedInstance getCurrentServiceID]) {
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
        mentrycell.active.hidden = ![(NSString *)entry[@"status"] isEqualToString:@"publishing"];
        
        // Geneerate Swipe Cells
        // Left
        __weak ListViewController *weakSelf = self;
        int currentservice = [listservice.sharedInstance getCurrentServiceID];
        mentrycell.leftButtons = @[[MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"delete"] backgroundColor:UIColor.redColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
            [weakSelf deleteTitle:((NSNumber *)entry[@"id"]).intValue withInfo:entry];
            return true;
        }]];
        mentrycell.leftSwipeSettings.transition = MGSwipeTransitionDrag;
        
        //Right
        NSMutableArray *rightregularbuttons = [NSMutableArray new];
        NSMutableArray *rightcompactbuttons = [NSMutableArray new];
        
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            mentrycell.viewonsiteswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"TitleInfo"] backgroundColor:[UIColor colorWithRed:1.00 green:0.80 blue:0.00 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf performViewOnListSite:((NSNumber *)entry[@"id"]).intValue];
                return true;
            }];
            
            mentrycell.adveditswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"advedit"] backgroundColor:[UIColor colorWithRed:1.00 green:0.58 blue:0.00 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf performAdvancedEditwithEntry:entry withType:weakSelf.listtype];
                return true;
            }];
            if (currentservice == 3) {
                mentrycell.customlistbutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"customlist"] backgroundColor:[UIColor colorWithRed:0.35 green:0.34 blue:0.84 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                    NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                    [weakSelf performCustomListEdit:((NSNumber *)entry[@"entryid"]).intValue withEntry:entry];
                    return true;
                }];
            }
            mentrycell.shareswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"share"] backgroundColor:UIColor.grayColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf performShare:((NSNumber *)entry[@"id"]).intValue withCell:mentrycell];
                return true;
            }];
        }
        
        mentrycell.optionswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"option"] backgroundColor:UIColor.grayColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
            [weakSelf showOtherOptions:entry withIndexPath:indexPath];
            return true;
            
        }];
        
        // Set Swipe Button Array
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [rightregularbuttons addObject:mentrycell.shareswipebutton];
            if (currentservice == 3) {
                [rightregularbuttons addObject:mentrycell.customlistbutton];
            }
            [rightregularbuttons addObject:mentrycell.adveditswipebutton];
            [rightregularbuttons addObject:mentrycell.viewonsiteswipebutton];
            for (MGSwipeButton *btn in rightregularbuttons) {
                [btn iconTintColor:[UIColor whiteColor]];
            }
        }
        [rightcompactbuttons addObject:mentrycell.optionswipebutton];
        if ([self canIncrement:entry]) {
            mentrycell.incrementswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"volincrement"] backgroundColor:[UIColor colorWithRed:0.37 green:0.79 blue:0.97 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf performMangaIncrement:entry volumeIncrement:YES];
                return true;
            }];
            mentrycell.incrementvolswipebutton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"increment"] backgroundColor:[UIColor colorWithRed:0.33 green:0.84 blue:0.41 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
                NSDictionary *entry = weakSelf.filteredlist[indexPath.row];
                [weakSelf performMangaIncrement:entry volumeIncrement:NO];
                return true;
            }];
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [rightregularbuttons addObject:mentrycell.incrementswipebutton];
                [rightregularbuttons addObject:mentrycell.incrementvolswipebutton];
            }
            [rightcompactbuttons addObject:mentrycell.incrementswipebutton];
            [rightcompactbuttons addObject:mentrycell.incrementvolswipebutton];
        }
        for (MGSwipeButton *btn in rightcompactbuttons) {
            [btn iconTintColor:[UIColor whiteColor]];
        }
        mentrycell.regularswipebuttons = rightregularbuttons.copy;
        mentrycell.compactswipebuttons = rightcompactbuttons.copy;
        [mentrycell setSwipeButtons];
        mentrycell.rightSwipeSettings.transition = MGSwipeTransitionDrag;
        return mentrycell;
    }
    else {
        return [UITableViewCell new];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[AnimeEntryTableViewCell class]] || [cell isKindOfClass:[MangaEntryTableViewCell class]]) {
        if (indexPath.row < _filteredlist.count && !_refreshcontrol.refreshing) {
            NSDictionary *entry = _filteredlist[indexPath.row];
            int titleid = ((NSNumber *)entry[@"id"]).intValue;
            TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[[UIStoryboard storyboardWithName:@"InfoView" bundle:nil] instantiateViewControllerWithIdentifier:@"TitleInfo"];
            [self.navigationController pushViewController:titleinfovc animated:YES];
            [titleinfovc loadTitleInfo:titleid withType:_listtype];
        }
    }
    else {
        [(UITableViewCell *)cell setSelected:NO animated:NO];
    }
}

- (IBAction)refresh:(UIRefreshControl *)sender {
    // Refreshes list
    [sender beginRefreshing];
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
        _searchController.searchBar.showsCancelButton = NO;
        [self populateOwnList];
    }
    else {
        [self filterWithSearchText:searchText];
        _searchController.searchBar.showsCancelButton = YES;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _searchController.searchBar.showsCancelButton = NO;
    searchBar.text = @"";
    [self populateOwnList];
    [searchBar resignFirstResponder];
}

#pragma mark Swipe Actions
- (void)deleteTitle:(int)titleid withInfo:(NSDictionary *)info {
    __weak ListViewController *weakSelf = self;
    __block int ntitleid = 0;
    switch ([listservice.sharedInstance getCurrentServiceID]) {
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
        [listservice.sharedInstance removeTitleFromList:ntitleid withType:weakSelf.listtype completion:^(id responseObject) {
            switch ([listservice.sharedInstance getCurrentServiceID]) {
                case 1:
                    [AtarashiiListCoreData removeSingleEntrywithUserName:[listservice.sharedInstance getCurrentServiceUsername] withService:[listservice.sharedInstance getCurrentServiceID] withType:weakSelf.listtype withId:ntitleid withIdType:0];
                    break;
                case 2:
                case 3:
                    [AtarashiiListCoreData removeSingleEntrywithUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:weakSelf.listtype withId:ntitleid withIdType:1];
                    break;
                default:
                    break;
            }
            // Check Notifications
            if ([AiringNotificationManager airingNotificationServiceSource] == [listservice.sharedInstance getCurrentServiceID]) {
                AiringNotificationManager *anm = [AiringNotificationManager sharedAiringNotificationManager];
                int sourceserviceid = [AiringNotificationManager airingNotificationServiceSource];
                [anm removeNotifyingTitle:titleid withService:sourceserviceid];
                [anm removeIgnoreNotifyingTitle:titleid withService:sourceserviceid];
            }
            [self reloadList];
            [NSNotificationCenter.defaultCenter postNotificationName:@"EntryUpdated" object:@{@"type" : @(self.listtype), @"id": @(titleid)}];
        } error:^(NSError *error) {
        }];
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    [prompt addAction:yesaction];
    [prompt addAction:noaction];
    [self presentViewController:prompt animated:YES completion:nil];
}

- (void)incrementProgress:(NSDictionary *)entry {
    int currentservice = [listservice.sharedInstance getCurrentServiceID];
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
    [listservice.sharedInstance updateAnimeTitleOnList:titleid withEpisode:watchedepisodes withStatus:watchstatus withScore:score withExtraFields:extraparameters completion:^(id responseobject) {
        NSDictionary *updatedfields = @{@"watched_episodes" : @(watchedepisodes), @"watched_status" : watchstatus, @"score" : @(score), @"rewatching" : @(rewatching), @"last_updated" : [Utility getLastUpdatedDateWithResponseObject:responseobject withService:[listservice.sharedInstance getCurrentServiceID]]};
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserName:[listservice.sharedInstance getCurrentServiceUsername] withService:[listservice.sharedInstance getCurrentServiceID] withType:0 withId:titleid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:0 withId:titleid withIdType:1];
                break;
        }
        [self reloadList];
        [NSNotificationCenter.defaultCenter postNotificationName:@"EntryUpdated" object:@{@"type" : @(self.listtype), @"id": entry[@"id"]}];
    }
    error:^(NSError * error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

- (void)performMangaIncrement:(NSDictionary *)entry volumeIncrement:(bool)volumeIncrement {
    int currentservice = [listservice.sharedInstance getCurrentServiceID];
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
    [listservice.sharedInstance updateMangaTitleOnList:titleid withChapter:readchapters withVolume:readvolumes withStatus:readstatus withScore:score withExtraFields:extraparameters completion:^(id responseObject) {
        NSDictionary *updatedfields = @{@"chapters_read" : @(readchapters), @"volumes_read" : @(readvolumes), @"read_status" : readstatus, @"score" : @(score), @"rereading" : @(rereading), @"last_updated" : [Utility getLastUpdatedDateWithResponseObject:responseObject withService:[listservice.sharedInstance getCurrentServiceID]]};
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserName:[listservice.sharedInstance getCurrentServiceUsername] withService:[listservice.sharedInstance getCurrentServiceID] withType:1 withId:titleid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:1 withId:titleid withIdType:1];
                break;
        }
        [self reloadList];
        [NSNotificationCenter.defaultCenter postNotificationName:@"EntryUpdated" object:@{@"type" : @(self.listtype), @"id": entry[@"id"]}];
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
            if (((watchedepisodes == episodes && episodes > 0) || [watchstatus isEqual:@"completed"])  && !selectedaircompleted) {
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
                return false;
            }
            if (readchapters > chapters && chapters > 0) {
                return false;
            }
            if (((readchapters == chapters && chapters > 0) || (readvolumes == volumes && volumes > 0) || [readstatus isEqual:@"completed"])  && !selectedfinished) {
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
    int currentservice = [listservice.sharedInstance getCurrentServiceID];
    UIAlertController *options = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
    options.popoverPresentationController.sourceView = cell;
    options.popoverPresentationController.sourceRect = cell.bounds;
    options.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
    [options addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"View on %@", [listservice.sharedInstance currentservicename]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performViewOnListSite:titleid];
    }]];
    [options addAction:[UIAlertAction actionWithTitle:@"Advanced Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performAdvancedEditwithEntry:entry withType:self.listtype];
    }]];
    if (currentservice == 3) {
        [options addAction:[UIAlertAction actionWithTitle:@"Manage Custom Lists" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self performCustomListEdit:((NSNumber *)entry[@"entryid"]).intValue withEntry:entry];
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

- (void)performAdvancedEditwithEntry:(NSDictionary *)entry withType:(int)type {
    UINavigationController *navController = [UINavigationController new];
    AdvEditTableViewController *advedit = [[UIStoryboard storyboardWithName:@"AdvancedEdit" bundle:nil] instantiateViewControllerWithIdentifier:@"advedit"];
    [advedit populateTableViewWithID:((NSNumber *)entry[@"id"]).intValue withEntryDictionary:entry withType:type];
     __weak ListViewController *weakSelf = self;
    advedit.entryUpdated = ^(int listtype) {
        [weakSelf reloadList];
        [NSNotificationCenter.defaultCenter postNotificationName:@"EntryUpdated" object:@{@"type" : @(listtype), @"id": entry[@"id"]}];
    };
    navController.viewControllers = @[advedit];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:navController animated:YES completion:^{}];
}

- (void)performCustomListEdit:(int)entryid withEntry:(NSDictionary *)entry {
    UINavigationController *navcontroller = [UINavigationController new];
    CustomListTableViewController *clvc = [[UIStoryboard storyboardWithName:@"CustomList" bundle:nil] instantiateViewControllerWithIdentifier:@"customlistedit"];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navcontroller.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [navcontroller setViewControllers:@[clvc]];
    [self presentViewController:navcontroller animated:YES completion:nil];
    [clvc viewDidLoad];
    [clvc populateCustomLists:entry withCurrentType:_listtype withSelectedId:entryid];
}

- (void)performViewOnListSite:(int)titleid {
    NSString *URL = [self getTitleURL:titleid];
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:URL] options:@{} completionHandler:^(BOOL success) {}];
}

- (void)performShare:(int)titleid withCell:(UITableViewCell *)cell{
    bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
    NSArray *activityItems = @[[NSURL URLWithString:[self getTitleURL:titleid]]];
    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityViewControntroller.popoverPresentationController.sourceView = cell;
        activityViewControntroller.popoverPresentationController.sourceRect = cell.bounds;
        activityViewControntroller.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
    }
    [self presentViewController:activityViewControntroller animated:true completion:nil];
}

# pragma mark helpers
- (NSString *)getTitleURL:(int)titleid {
    switch ([listservice.sharedInstance getCurrentServiceID]) {
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
#pragma mark sort
- (NSString *)getSortBy {
    NSString *sortbystr = @"";
    NSUserDefaults *userdefaults = NSUserDefaults.standardUserDefaults;
    switch (_listtype) {
        case Anime:
            sortbystr = [userdefaults valueForKey:@"anime-sortby"];
            break;
        case Manga:
            sortbystr = [userdefaults valueForKey:@"manga-sortby"];
            break;
        default:
            return sortbystr;
    }
    sortbystr = [sortbystr lowercaseString];
    sortbystr = [sortbystr stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    return sortbystr;
}
- (bool)getAccending {
    NSUserDefaults *userdefaults = NSUserDefaults.standardUserDefaults;
    switch (_listtype) {
        case Anime:
            return [userdefaults boolForKey:@"anime-accending"];
        case Manga:
            return [userdefaults boolForKey:@"manga-accending"];
        default:
            return false;
    }
}
- (IBAction)showsort:(id)sender {
    UINavigationController *navcontroller = [UINavigationController new];
    SortTableViewController *sorttvc = [self.storyboard instantiateViewControllerWithIdentifier:@"sortvc"];
    NSUserDefaults *userdefaults = NSUserDefaults.standardUserDefaults;
    NSString *sortbystr = @"";
    bool accending = false;
    switch (_listtype) {
        case Anime:
            sortbystr = [userdefaults valueForKey:@"anime-sortby"];
            accending = [userdefaults boolForKey:@"anime-accending"];
            break;
        case Manga:
            sortbystr = [userdefaults valueForKey:@"manga-sortby"];
            accending = [userdefaults boolForKey:@"manga-accending"];
            break;
    }
    __weak ListViewController *weakSelf = self;
    sorttvc.listSortChanged = ^(NSString * _Nonnull sortby, bool accending, int type) {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        switch (type) {
            case Anime:
                [defaults setValue:sortby forKey:@"anime-sortby"];
                [defaults setBool:accending forKey:@"anime-accending"];
                break;
            case Manga:
                [defaults setValue:sortby forKey:@"manga-sortby"];
                [defaults setBool:accending forKey:@"manga-accending"];
                break;
        }
        [weakSelf reloadList];
    };
    navcontroller.viewControllers = @[sorttvc];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navcontroller.modalPresentationStyle = UIModalPresentationPopover;
        navcontroller.popoverPresentationController.barButtonItem = sender;
    }
    [sorttvc loadView];
    [self presentViewController:navcontroller animated:YES completion:nil];
    [sorttvc loadSort:sortbystr withAccending:accending withType:_listtype];
}

#pragma mark HUD
- (void)showloadingview:(bool)show {
    if (show && !_refreshing) {
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = @"Loading";
        _hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
        _hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
        _refreshing = YES;
    }
    else if (!show) {
        [_hud hideAnimated:YES];
        _refreshing = NO;
    }
}
@end
