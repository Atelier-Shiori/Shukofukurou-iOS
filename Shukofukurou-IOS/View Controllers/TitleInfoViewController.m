//
//  TitleInfoViewController.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/18/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "TitleInfoViewController.h"
#import "RelatedTableViewController.h"
#import "CharacterTableViewController.h"
#import "EpisodesTableViewController.h"
#import "ReviewTableViewController.h"
#import "AdvEditTableViewController.h"
#import "TitleInfoTableViewCell.h"
#import "Utility.h"
#import "NSString+HTMLtoNSAttributedString.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AtarashiiListCoreData.h"
#import "listservice.h"
#import "EntryCellInfo.h"
#import "AniListScoreConvert.h"
#import "RatingTwentyConvert.h"
#import "ViewControllerManager.h"
#import "NewStreamDataRetriever.h"
#import "TitleInfoCache.h"
#import "ThemeManager.h"
#import "HistoryManager.h"
#import <MBProgressHudFramework/MBProgressHUD.h>
#import "UIViewController+BackButtonHandler.h"

@interface TitleInfoViewController ()
@property (strong) NSArray *streamsitelinks;
@property (strong, nonatomic) IBOutlet UIImageView *posterImage;
@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationitem;
@property (strong) NSDictionary *blankentry;
@property bool isNewEntry;
@property (strong) NSMutableDictionary *items;
@property (strong) NSArray *sections;
@property int currenttype;
@property int entryid;
@property int titleid;
@property bool forcerefresh;
@property (weak, nonatomic) IBOutlet UILabel *titlestatus;
@property (weak, nonatomic) IBOutlet UILabel *titletype;
@property (strong) RelatedTableViewController *relatedtvc;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *titleinfobaritem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareitembaritem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *optionsitembaritem;
@property (strong) MBProgressHUD *hud;
@property bool setthemecolors;
@property bool refreshing;
@property (strong, nonatomic) IBOutlet UILabel *scorelabel;
@property (strong, nonatomic) IBOutlet UIImageView *scoreimage;
@property bool entrychanged;
@property bool isNSFW;
@property bool surpressscoreprompt;
@end

@implementation TitleInfoViewController

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    [self registerTableViewCells];
    // Set Background Color
    [self setThemeColors];
    _setthemecolors = true;
    // Do any additional setup after loading the view.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"UserLoggedIn" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"UserLoggedOut" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ServiceChanged" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ThemeChanged" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"EntryUpdated" object:nil];
    _relatedtvc = [self.storyboard instantiateViewControllerWithIdentifier:@"relatedview"];
    [self setToolbar];
    _scoreimage.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setThemeColors];
    _setthemecolors = true;
    NSIndexPath *indexPath = self.tableview.indexPathForSelectedRow;
    if (indexPath) {
        [self.tableview deselectRowAtIndexPath:indexPath animated:animated];
    }
}

- (bool)navigationShouldPopOnBackButton {
    if (_entrychanged) {
        [self showUnsavedChangesWithBlock:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
        return NO;
    }
    return YES;
}

- (void)setThemeColors {
    if (!_setthemecolors) {
        if (@available(iOS 13, *)) { }
        else {
            bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
            ThemeManagerTheme *current = [ThemeManager sharedCurrentTheme];
            self.view.backgroundColor = darkmode ? current.viewAltBackgroundColor : current.viewBackgroundColor;
            self.tableview.backgroundColor = darkmode ? current.viewAltBackgroundColor : current.viewBackgroundColor;
            self.scoreimage.tintColor = darkmode ? current.tintColor : current.textColor;
            self.titlestatus.textColor = current.textColor;
            self.titletype.textColor = current.textColor;
            self.scorelabel.textColor = current.textColor;
            int synopsissection = 0;
            for (NSString *section in _sections) {
                if ([section isEqualToString:@"Synopsis"]) {
                    break;
                }
                synopsissection++;
            }
            if (synopsissection < 2) {
                TitleInfoSynopsisTableViewCell *synopsis = [self.tableview cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:synopsissection]];
                [synopsis fixTextColor];
            }
        }
    }
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"UserLoggedIn"]) {
        if (notification.object) {
            if (((ListViewController *)notification.object).listtype == _currenttype) {
                [self updateUserEntry];
                _sections = [self generateSections];
                [_tableview reloadData];
            }
        }
    }
    else if ([notification.name isEqualToString:@"UserLoggedOut"]) {
        // Remove Your Entry section
        [_items removeObjectForKey:@"Your Entry"];
        _sections = [self generateSections];
        [_tableview reloadData];
    }
    else if ([notification.name isEqualToString:@"ServiceChanged"]) {
        // Leave Title Information
        self.navigationItem.hidesBackButton = NO;
        [self showloadingview:NO];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else if ([notification.name isEqualToString:@"ThemeChanged"]) {
        _setthemecolors = false;
    }
    else if ([notification.name isEqualToString:@"EntryUpdated"]) {
        NSDictionary *info = notification.object;
        if (((NSNumber *)info[@"id"]).intValue == _titleid && ((NSNumber *)info[@"type"]).intValue == _currenttype) {
            [self updateUserEntry];
            [_tableview reloadData];
        }
    }
}

- (void)loadTitleInfo:(int)titleid withType:(int)type {
    _titleid = titleid;
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"] && !_forcerefresh) {
        NSDictionary *titleinfo = [TitleInfoCache getTitleInfoWithTitleID:titleid withServiceID:[listservice.sharedInstance getCurrentServiceID] withType:type ignoreLastUpdated:NO];
        if (titleinfo) {
            if (type == Anime) {
                   [NewStreamDataRetriever retrieveStreamDataForTitleID:titleid withService:listservice.sharedInstance.getCurrentServiceID completion:^(NSArray * _Nonnull entries, bool success) {
                       if (success) {
                           self.streamsitelinks = entries;
                       }
                       [self populateInfoWithType:type withDictionary:titleinfo];
                       [self view];
                       [self showloadingview:NO];
                   }];
            }
            else {
                [self populateInfoWithType:type withDictionary:titleinfo];
                [self view];
                [self showloadingview:NO];
            }
            return;
        }
    }
    __weak TitleInfoViewController *weakSelf = self;
    self.navigationItem.hidesBackButton = YES;
    [self showloadingview:YES];
    [listservice.sharedInstance retrieveTitleInfo:titleid withType:type useAccount:NO completion:^(id responseObject) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"]) {
            if (type == Anime) {
                [NewStreamDataRetriever retrieveStreamDataForTitleID:titleid withService:listservice.sharedInstance.getCurrentServiceID completion:^(NSArray * _Nonnull entries, bool success) {
                    if (success) {
                        weakSelf.streamsitelinks = entries;
                    }
                    [weakSelf populateInfoWithType:type withDictionary:[TitleInfoCache saveTitleInfoWithTitleID:titleid withServiceID:[listservice.sharedInstance getCurrentServiceID] withType:type withResponseObject:responseObject]];
                    weakSelf.forcerefresh = false;
                    weakSelf.navigationItem.hidesBackButton = NO;
                    [weakSelf showloadingview:NO];
                }];
                return;
            }
            else {
                [weakSelf populateInfoWithType:type withDictionary:[TitleInfoCache saveTitleInfoWithTitleID:titleid withServiceID:[listservice.sharedInstance getCurrentServiceID] withType:type withResponseObject:responseObject]];
                weakSelf.forcerefresh = false;
            }
        }
        else {
            if (type == Anime) {
                [NewStreamDataRetriever retrieveStreamDataForTitleID:titleid withService:listservice.sharedInstance.getCurrentServiceID completion:^(NSArray * _Nonnull entries, bool success) {
                    if (success) {
                        weakSelf.streamsitelinks = entries;
                    }
                    [weakSelf populateInfoWithType:type withDictionary:responseObject];
                    weakSelf.navigationItem.hidesBackButton = NO;
                    [weakSelf showloadingview:NO];
                }];
                return;
            }
            else {
                [weakSelf populateInfoWithType:type withDictionary:responseObject];
            }
        }
        weakSelf.navigationItem.hidesBackButton = NO;
        [weakSelf showloadingview:NO];
    } error:^(NSError *error) {
        NSLog(@"%@",error);
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"]) {
            NSDictionary *titleinfo = [TitleInfoCache getTitleInfoWithTitleID:titleid withServiceID:[listservice.sharedInstance getCurrentServiceID] withType:type ignoreLastUpdated:NO];
            if (titleinfo) {
                [self populateInfoWithType:type withDictionary:titleinfo];
                [self view];
                [weakSelf showloadingview:NO];
                weakSelf.forcerefresh = false;
                return;
            }
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Can't load title information" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            weakSelf.navigationItem.hidesBackButton = NO;
            [weakSelf showloadingview:NO];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)populateInfoWithType:(int)type withDictionary:(NSDictionary *)titleinfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currenttype = type;
        self.isNSFW = ((NSNumber *)titleinfo[@"isNSFW"]).boolValue;
        self.navigationitem.title = titleinfo[@"title"];
        [self.relatedtvc generateRelated:titleinfo withType:self.currenttype];
        if (type == 0) {
            NSString *airingstatus = titleinfo[@"status"];
            self.titlestatus.text = airingstatus;
            self.titletype.text = titleinfo[@"type"];
            if ([airingstatus isEqualToString:@"finished airing"]) {
                self.selectedaircompleted = true;
            }
            else {
                self.selectedaircompleted = false;
            }
            if ([airingstatus isEqualToString:@"finished airing"]||[airingstatus isEqualToString:@"currently airing"]||[airingstatus isEqualToString:@"on hiatus"]) {
                self.selectedaired = true;
            }
            else {
                self.selectedaired = false;
            }
        }
        else {
            NSString *publishstatus = titleinfo[@"status"];
            self.titlestatus.text = publishstatus;
            self.titletype.text = titleinfo[@"type"];
            if ([publishstatus isEqualToString:@"finished"]) {
                self.selectedfinished = true;
            }
            else {
                self.selectedfinished = false;
            }
            if ([publishstatus isEqualToString:@"finished"]||[publishstatus isEqualToString:@"publishing"]||[publishstatus isEqualToString:@"on hiatus"]) {
                self.selectedpublished = true;
            }
            else {
                self.selectedpublished = false;
            }
        }
        [self populateWithInfowithDictionary:titleinfo withType:type];
    });
}

#pragma mark options

- (IBAction)presentoptions:(id)sender {
    UIAlertController *options = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak TitleInfoViewController *weakSelf = self;
    bool isregularclass = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
    if (!isregularclass) {
        if (!_isNSFW) {
            [options addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"View on %@", [listservice.sharedInstance currentservicename]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf performViewOnListSite];
            }]];
            [options addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf performShare:sender];
            }]];
        }
    }
    if ([listservice.sharedInstance checkAccountForCurrentService] && !_isNewEntry) {
        [options addAction:[UIAlertAction actionWithTitle:@"Advanced Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UINavigationController *navController = [UINavigationController new];
            AdvEditTableViewController *advedit = [[UIStoryboard storyboardWithName:@"AdvancedEdit" bundle:nil] instantiateViewControllerWithIdentifier:@"advedit"];
            [advedit populateTableViewWithID:weakSelf.titleid withEntryDictionary:[AtarashiiListCoreData retrieveSingleEntryForTitleID:weakSelf.titleid withService:[listservice.sharedInstance getCurrentServiceID] withType:weakSelf.currenttype] withType:weakSelf.currenttype];
            advedit.entryUpdated = ^(int listtype) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.currenttype == AnimeSearchType) {
                        [NSNotificationCenter.defaultCenter postNotificationName:@"AnimeReloadList" object:nil];
                    }
                    else {
                        [NSNotificationCenter.defaultCenter postNotificationName:@"MangaReloadList" object:nil];
                    }
                    [weakSelf updateUserEntry];
                    [weakSelf.tableview reloadData];
                });
            };
            navController.viewControllers = @[advedit];
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                navController.modalPresentationStyle = UIModalPresentationFormSheet;
            }
            [self presentViewController:navController animated:YES completion:^{}];
        }]];
    }
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"]) {
        [options addAction:[UIAlertAction actionWithTitle:@"Refresh Title Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf refreshTitleInfo];
        }]];
    }
    if (self.navigationController.viewControllers.count > 3) {
        [options addAction:[UIAlertAction actionWithTitle:@"Return to Parent" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf checkUnsavedChangesWithBlock:^{
                [weakSelf.navigationController popToRootViewControllerAnimated:YES];
            }];
        }]];
    }
    [options addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        options.popoverPresentationController.barButtonItem = sender;
        options.popoverPresentationController.sourceView = self.view;
    }
    
    [self
     presentViewController:options
     animated:YES
     completion:nil];
}

- (IBAction)viewonsite:(id)sender {
    [self performViewOnListSite];
}

- (IBAction)share:(id)sender {
    [self performShare:sender];
}

- (void)performViewOnListSite {
    NSString *URL = [self getTitleURL];
    [self openWebBrowserView:[NSURL URLWithString:URL]];
}

- (void)performShare:(id)sender {
    NSArray *activityItems = @[[NSURL URLWithString:[self getTitleURL]]];
    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    activityViewControntroller.popoverPresentationController.barButtonItem = sender;
    activityViewControntroller.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewControntroller animated:true completion:nil];
}

- (NSString *)getTitleURL {
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1: {
            if (_currenttype == Anime){
                return [NSString stringWithFormat:@"https://myanimelist.net/anime/%i" ,_titleid];
            }
            else {
                return [NSString stringWithFormat:@"https://myanimelist.net/manga/%i", _titleid];
            }
        }
        case 2: {
            if (_currenttype == Anime) {
                return [NSString stringWithFormat:@"https://kitsu.io/anime/%i", _titleid];
            }
            else {
                return [NSString stringWithFormat:@"https://kitsu.io/manga/%i", _titleid];
            }

        }
        case 3: {
            if (_currenttype == Anime) {
                return [NSString stringWithFormat:@"https://anilist.co/anime/%i", _titleid];
            }
            else {
                return [NSString stringWithFormat:@"https://anilist.co/manga/%i", _titleid];
            }
        }
        default:
            return @"";
    }
}

- (void)refreshTitleInfo {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"] && !_refreshing) {
        [self checkUnsavedChangesWithBlock:^{
            self.forcerefresh = true;
            [self loadTitleInfo:self.titleid withType:self.currenttype];
        }];
    }
}

# pragma mark Toolbar

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self setToolbar];
}

- (void)setToolbar {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        NSMutableArray *toolbarButtons = [self.navigationItem.rightBarButtonItems mutableCopy];
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
            if (![toolbarButtons containsObject:self.shareitembaritem]) {
                [toolbarButtons addObject:self.shareitembaritem];
                [toolbarButtons addObject:self.titleinfobaritem];
            }
        }
        else {
            if ([toolbarButtons containsObject:self.shareitembaritem]) {
                [toolbarButtons removeObject:self.shareitembaritem];
                [toolbarButtons removeObject:self.titleinfobaritem];
            }
        }
        [self.navigationItem setRightBarButtonItems:toolbarButtons animated:YES];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)_items[_sections[section]]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sections[section];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellType = _sections[indexPath.section];
    EntryCellInfo *cellEntry = _items[cellType][indexPath.row];
    // List Entry Cell Generation
    if (cellEntry.type == cellTypeProgressEntry) {
        return [self generateProgressCell:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else if (cellEntry.type == cellTypeEntry) {
        NSString *anilistscoretype = [NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"];
        int currentservice = [listservice.sharedInstance getCurrentServiceID];
        if (currentservice == 3 && ([anilistscoretype isEqualToString:@"POINT_100"] ||[anilistscoretype isEqualToString:@"POINT_10_DECIMAL"]) && [cellEntry.cellTitle isEqualToString:@"Score"]) {
            // Generate Advanced Score Cell
            return [self generateAdvScoreCell:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
        }
        else {
            return [self generateEntryCell:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
        }
    }
    else if (cellEntry.type == cellTypeInfo) {
        return [self generateTitleInfoCell:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else if (cellEntry.type == cellTypeInfoExpand) {
        return [self generateTitleInfoCellExpand:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else if (cellEntry.type == cellTypeSynopsis) {
        return [self generateSynopsis:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else if (cellEntry.type == cellTypeAction) {
        return [self generateActionCell:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else if (cellEntry.type == cellTypeStreamSite) {
        return [self generateStreamSiteCell:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return [UITableViewCell new];
}

- (UITableViewCell *)generateEntryCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"editdetailcell";
    TitleInfoListEntryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableview) {
        cell = [self.tableview dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.textLabel.text = cellInfo.cellTitle;
    if ([cellInfo.cellTitle isEqualToString:@"Status"]) {
        cell.detailTextLabel.text = cellInfo.cellValue;
        cell.entrytype = _currenttype;
        cell.valueChanged = ^(NSString * _Nonnull newvalue, NSString * _Nonnull fieldname) {
            cellInfo.cellValue = newvalue;
            [self setmodified:YES];
        };
    }
    else if ([cellInfo.cellTitle isEqualToString:@"Score"]) {
        cell.rawValue = ((NSNumber *)cellInfo.cellValue).intValue;
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                cell.detailTextLabel.text = @(cell.rawValue).stringValue;
                break;
            case 2:
                cell.detailTextLabel.text = [RatingTwentyConvert convertRatingTwentyToActualScore:cell.rawValue scoretype:(int)[NSUserDefaults.standardUserDefaults integerForKey:@"kitsu-ratingsystem"]];
                break;
            case 3:
                cell.detailTextLabel.text = [AniListScoreConvert convertAniListScoreToActualScore:cell.rawValue withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]];
                break;
        }
        cell.scoreChanged = ^(int newvalue, NSString * _Nonnull fieldname) {
            cellInfo.cellValue = @(newvalue);
            [self setmodified:YES];
        };
    }
    return cell;
}

- (UITableViewCell *)generateProgressCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"progresscell";
    TitleInfoProgressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableview) {
        cell = [self.tableview dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.fieldtitlelabel.text = cellInfo.cellTitle;
    cell.currentprogress = ((NSNumber *)cellInfo.cellValue).intValue;
    cell.stepper.maximumValue = cellInfo.cellValueMax > 0 ? cellInfo.cellValueMax : 999999999;
    cell.stepper.value = cell.currentprogress;
    cell.episodefield.text = @(cell.currentprogress).stringValue;
    cell.valueChanged = ^(NSNumber * _Nonnull newvalue, NSString * _Nonnull fieldname) {
        cellInfo.cellValue = newvalue;
        [self setmodified:YES];
    };
    return cell;
}

- (UITableViewCell *)generateAdvScoreCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"advscorecell";
    TitleInfoAdvScoreEntryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableview) {
        cell = [self.tableview dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.rawscore = ((NSNumber *)cellInfo.cellValue).intValue;
    cell.scorefield.text = [AniListScoreConvert convertAniListScoreToActualScore:cell.rawscore withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]];
    cell.scoreChanged = ^(int newvalue, NSString * _Nonnull fieldname) {
        cellInfo.cellValue = @(newvalue);
        [self setmodified:YES];
    };
    return cell;
}

- (UITableViewCell *)generateTitleInfoCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"titleinfocell";
    TitleInfoBasicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableview) {
        cell = [self.tableview dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.textLabel.text = cellInfo.cellTitle;
    cell.detailTextLabel.text = cellInfo.cellValue;
    return cell;
}

- (UITableViewCell *)generateTitleInfoCellExpand:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"titleinfocellexpand";
    TitleInfoBasicExpandTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableview) {
        cell = [self.tableview dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.titleLabel.text = cellInfo.cellTitle;
    cell.valueLabel.text = cellInfo.cellValue;
    return cell;
}

- (UITableViewCell *)generateSynopsis:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"synopsiscell";
    TitleInfoSynopsisTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableview) {
        cell = [self.tableview dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    
    cell.valueText.attributedText = [(NSString *)cellInfo.cellValue convertHTMLtoAttStr];
    [cell fixTextColor];
    return cell;
}

- (UITableViewCell *)generateActionCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"actioncell";
    TitleInfoUpdateTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableview) {
        cell = [self.tableview dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.textLabel.text = cellInfo.cellTitle;
    cell.actiontype = cellInfo.action;
    switch (cell.actiontype) {
        case cellActionAddEntry:
        case cellActionUpdateEntry:
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell setUpdateActionCell:YES];
            break;
        case cellActionViewStaff:
        case cellActionViewReviews:
        case cellActionViewRelated:
        case cellActionViewEpisodes:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (@available(iOS 13, *)) { }
            else {
                cell.textLabel.textColor = [ThemeManager.sharedCurrentTheme textColor];
            }
            cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
            [cell setUpdateActionCell:NO];
            break;
        default:
            break;
    }
    __weak TitleInfoViewController *weakSelf = self;
    cell.cellPressed = ^(int actiontype, TitleInfoUpdateTableViewCell * _Nonnull cell) {
        if ([weakSelf validateCells]) {
            if (weakSelf.currenttype == 0) {
                switch (actiontype) {
                    case cellActionAddEntry: {
                        [self addAnimeEntry:cell];
                        break;
                    }
                    case cellActionUpdateEntry: {
                        [self updateAnime:cell];
                        break;
                    }
                    case cellActionViewRelated: {
                        [self checkUnsavedChangesWithBlock:^{
                            [self.navigationController pushViewController:weakSelf.relatedtvc animated:YES];
                        }];
                        break;
                    }
                    case cellActionViewReviews: {
                        [self showReviews];
                        break;
                    }
                    case cellActionViewStaff: {
                        [self checkUnsavedChangesWithBlock:^{
                            [self showStaff];
                        }];
                        break;
                    }
                    case cellActionViewEpisodes: {
                        [self checkUnsavedChangesWithBlock:^{
                            [self showEpisodes];
                        }];
                        break;
                    }
                    default: {
                        break;
                    }
                }
            }
            else {
                switch (actiontype) {
                    case cellActionAddEntry: {
                        [self addMangaEntry:cell];
                        break;
                    }
                    case cellActionUpdateEntry: {
                        [self updateManga:cell];
                        break;
                    }
                    case cellActionViewRelated: {
                        [self checkUnsavedChangesWithBlock:^{
                            [self.navigationController pushViewController:weakSelf.relatedtvc animated:YES];
                        }];
                        break;
                    }
                    case cellActionViewReviews: {
                        [self showReviews];
                        break;
                    }
                    case cellActionViewStaff: {
                        [self checkUnsavedChangesWithBlock:^{
                            [self showStaff];
                        }];
                        break;
                    }
                    default:
                        break;
                }
            }
        }
    };
    return cell;
}

- (UITableViewCell *)generateStreamSiteCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"streamsitecell";
    TitleInfoStreamSiteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableview) {
        cell = [self.tableview dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.textLabel.text = cellInfo.cellTitle;
    cell.siteURL = cellInfo.cellValue;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
    id cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[TitleInfoUpdateTableViewCell class]]) {
        [(TitleInfoUpdateTableViewCell *)cell selectAction];
    }
    else if ([cell isKindOfClass:[TitleInfoProgressTableViewCell class]]) {
        [(TitleInfoProgressTableViewCell *)cell selectAction];
    }
    else if ([cell isKindOfClass:[TitleInfoListEntryTableViewCell class]]) {
        [(TitleInfoListEntryTableViewCell *)cell selectAction];
    }
    else if ([cell isKindOfClass:[TitleInfoUpdateTableViewCell class]]) {
        [(TitleInfoUpdateTableViewCell *)cell selectAction];
    }
    else if ([cell isKindOfClass:[TitleInfoAdvScoreEntryTableViewCell class]]) {
        [(TitleInfoAdvScoreEntryTableViewCell *)cell selectAction];
    }
    else if ([cell isKindOfClass:[TitleInfoStreamSiteTableViewCell class]]) {
        [(TitleInfoStreamSiteTableViewCell *)cell selectAction];
    }
}

#pragma mark Data Source Dictionary Generators

- (void)populateWithInfowithDictionary:(NSDictionary *)titleinfo withType:(int)type {
    NSMutableDictionary *tmpdictionary = [NSMutableDictionary new];
    // Generate blank user entry
    if (type == 0) {
        _blankentry = @{@"watched_episodes" : @(0), @"watched_status" : @"watching", @"score" : @(0) , @"episodes" : titleinfo[@"episodes"]};
    }
    else {
        _blankentry = @{@"chapters_read" : @(0), @"volumes_read" : @(0), @"read_status" : @"reading", @"score" : @(0), @"chapters" : titleinfo[@"chapters"], @"volumes" : titleinfo[@"volumes"]};
    }
    NSDictionary *userentry = [self retrieveEntry:((NSNumber *)titleinfo[@"id"]).intValue withType:type];
    // Set Title, Poster Image and Synopsis
    if (((NSString *)titleinfo[@"image_url"]).length > 0) {
        [_posterImage sd_setImageWithURL:[NSURL URLWithString:(NSString *)titleinfo[@"image_url"]]];
    }
    else {
        _posterImage.image = [UIImage new];
    }
    // Generate Cell Array
    tmpdictionary[@"Synopsis"] = @[[[EntryCellInfo alloc] initCellWithTitle:@"" withValue:titleinfo[@"synopsis"] withCellType:cellTypeSynopsis]];
    if (!_isNSFW) {
        tmpdictionary[@"Title Details"] = type == 0 ? [self generateAnimeTitleArray:titleinfo] : [self generateMangaTitleArray:titleinfo];
    }
    if (userentry) {
        tmpdictionary[@"Your Entry"] = type == 0 ? [self generateUserEntryAnimeArray:userentry] : [self generateUserEntryMangaArray:userentry];
    }
    if (!_isNSFW) {
        if (_currenttype == Anime) {
            NSDictionary *streamsites;
            NSArray *titles = [self aggregateTitles:titleinfo];
            for (NSString *stitle in titles) {
                if (_streamsitelinks.count > 0) {
                    tmpdictionary[@"Stream Sites"] = [self generateStreamSitesCellArray];
                    break;
                }
            }
        }
    }
    _items = tmpdictionary;
    _sections = [self generateSections];
    _shareitembaritem.enabled = !_isNSFW;
    _titleinfobaritem.enabled = !_isNSFW;
    [_tableview reloadData];
}

- (NSDictionary *)retrieveEntry:(int)titleid withType:(int)type {
    if ([listservice.sharedInstance checkAccountForCurrentService]) {
        NSDictionary *userentry = [AtarashiiListCoreData retrieveSingleEntryForTitleID:titleid withService:[listservice.sharedInstance getCurrentServiceID] withType:_currenttype];
        if (userentry) {
            _entryid = ((NSNumber *)userentry[@"entryid"]).intValue;
            _selectedreconsuming = type == 0 ? ((NSNumber *)userentry[@"rewatching"]).boolValue : ((NSNumber *)userentry[@"rereading"]).boolValue;
            _isNewEntry = false;
        }
        else {
            userentry = _blankentry;
            _selectedreconsuming = false;
            _entryid = 0;
            _isNewEntry = true;
        }
        return userentry;
    }
    return nil;
}

- (NSArray *)generateUserEntryAnimeArray:( NSDictionary * _Nonnull)entry {
    NSMutableArray *entrycellarray = [NSMutableArray new];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Episode" withValue:entry[@"watched_episodes"] withMaximumCellValue:((NSNumber *)entry[@"episodes"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Status" withValue:entry[@"watched_status"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:entry[@"score"] withCellType:cellTypeEntry]];
    if (entry[@"entryid"]) {
        [entrycellarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Update Entry" withCellAction:cellActionUpdateEntry]];
    }
    else {
        [entrycellarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Add Entry" withCellAction:cellActionAddEntry]];
    }
    return entrycellarray;
}

- (NSArray *)generateUserEntryMangaArray:(NSDictionary * _Nonnull)entry {
    NSMutableArray *entrycellarray = [NSMutableArray new];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Chapter" withValue:entry[@"chapters_read"] withMaximumCellValue:((NSNumber *)entry[@"chapters"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Volume" withValue:entry[@"volumes_read"] withMaximumCellValue:((NSNumber *)entry[@"volumes"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Status" withValue:entry[@"read_status"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:entry[@"score"] withCellType:cellTypeEntry]];
    if (entry[@"entryid"]) {
        [entrycellarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Update Entry" withCellAction:cellActionUpdateEntry]];
    }
    else {
        [entrycellarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Add Entry" withCellAction:cellActionAddEntry]];
    }
    return entrycellarray;
}

- (void)updateUserEntry {
    int currentService = [listservice.sharedInstance getCurrentServiceID];
    NSDictionary *userentry = [self retrieveEntry:_titleid withType:_currenttype];
    _items[@"Your Entry"] = _currenttype == 0 ? [self generateUserEntryAnimeArray:userentry] : [self generateUserEntryMangaArray:userentry];
    switch (currentService) {
        case 2:
        case 3:
            _entryid = ((NSNumber *)userentry[@"entryid"]).intValue;
            break;
            
        default:
            break;
    }
    [self setmodified:NO];
    [_tableview reloadData];
}

- (NSArray *)generateAnimeTitleArray:(NSDictionary *)titleinfo {
    NSMutableArray *detailarray = [NSMutableArray new];
    // Basic Info
    // [detailarray addObject:@{@"title" : @"Type", @"values" : @""}];
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Type" withValue:titleinfo[@"type"] withCellType:cellTypeInfo]];
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Episodes" withValue:(((NSNumber *)titleinfo[@"episodes"]).intValue > 0 || titleinfo[@"episodes"] != nil) ? ((NSNumber *)titleinfo[@"episodes"]).stringValue : @"Unknown" withCellType:cellTypeInfo]];
    if (((NSNumber *)titleinfo[@"duration"]).intValue > 0){
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Duration" withValue:[NSString stringWithFormat:@"%@ mins", ((NSNumber *)titleinfo[@"duration"]).stringValue] withCellType:cellTypeInfo]];
    }
    if (((NSString *)titleinfo[@"season"]).length > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Aired Season" withValue:titleinfo[@"season"] withCellType:cellTypeInfo]];
    }
    if (titleinfo[@"start_date"] && titleinfo[@"start_date"] != [NSNull null] && ((NSString *)titleinfo[@"start_date"]).length > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Started" withValue:titleinfo[@"start_date"] withCellType:cellTypeInfo]];
    }
    if (titleinfo[@"end_date"] && titleinfo[@"end_date"] != [NSNull null] && ((NSString *)titleinfo[@"end_date"]).length > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Ended" withValue:titleinfo[@"end_date"] withCellType:cellTypeInfo]];
    }
    if (((NSString *)titleinfo[@"source"]).length > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Source" withValue:titleinfo[@"source"] withCellType:cellTypeInfo]];
    }
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Status" withValue:titleinfo[@"status"] withCellType:cellTypeInfo]];
    // Other Info
    NSDictionary *dtitles =  titleinfo[@"other_titles"];
    NSMutableArray *othertitles = [NSMutableArray new];
    if (dtitles[@"english"] != nil){
        NSArray *e = dtitles[@"english"];
        for (NSString *etitle in e){
            [othertitles addObject:etitle];
        }
    }
    if (dtitles[@"japanese"] != nil){
        NSArray *j = dtitles[@"japanese"];
        for (NSString *jtitle in j){
            [othertitles addObject:jtitle];
        }
    }
    if (dtitles[@"synonyms"] != nil){
        NSArray *syn = dtitles[@"synonyms"];
        for (NSString *stitle in syn){
            [othertitles addObject:stitle];
        }
    }
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Other Titles" withValue:[Utility appendstringwithArray:othertitles] withCellType:cellTypeInfoExpand]];
    NSString *genres;
    if (titleinfo[@"genres"]!= nil) {
        NSArray *genresa = titleinfo[@"genres"];
        genres = [Utility appendstringwithArray:genresa];
    }
    else{
        genres = @"None";
    }
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Genres" withValue:genres withCellType:cellTypeInfoExpand]];
    if (((NSArray *)titleinfo[@"producers"]).count > 0){
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Producers" withValue:[Utility appendstringwithArray:(NSArray *)titleinfo[@"producers"]] withCellType:cellTypeInfoExpand]];
    }
    if (((NSString *)titleinfo[@"hashtag"]).length > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Hashtag" withValue:titleinfo[@"hashtag"] withCellType:cellTypeInfo]];
    }
    if (titleinfo[@"members_score"] != nil || ((NSNumber *)titleinfo[@"members_score"]).intValue > 0) {
        NSString *scorestring = [NSString stringWithFormat:@"%.2f", ((NSNumber *)titleinfo[@"members_score"]).floatValue];
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:scorestring withCellType:cellTypeInfo]];
        _scorelabel.text = scorestring;
    }
    NSNumber *popularity = titleinfo[@"popularity_rank"];
    if (popularity.intValue > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Popularity" withValue:popularity.stringValue withCellType:cellTypeInfo]];
    }
    NSNumber *favorites = titleinfo[@"favorited_count"];
    if (favorites.intValue > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Favorited" withValue:favorites.stringValue withCellType:cellTypeInfo]];
    }
    [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Related" withCellAction:cellActionViewRelated]];
    [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:[listservice.sharedInstance getCurrentServiceID] == 2 ? @"Reactions" : @"Reviews" withCellAction:cellActionViewReviews]];
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1:
            break;
        case 3:
            [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Characters/Staff" withCellAction:cellActionViewStaff]];
            break;
        case 2:
            if ([(NSString *)titleinfo[@"type"] isEqualToString:@"TV"]) {
                [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Episodes" withCellAction:cellActionViewEpisodes]];
            }
            break;
        default:
            break;
    }
    return detailarray.copy;
}

- (NSArray *)generateMangaTitleArray:(NSDictionary *)titleinfo {
    NSMutableArray *detailarray = [NSMutableArray new];
    // Basic Info
    // [detailarray addObject:@{@"title" : @"Type", @"values" : @""}];
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Type" withValue:titleinfo[@"type"] withCellType:cellTypeInfo]];
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Chapters" withValue:(((NSNumber *)titleinfo[@"chapters"]).intValue > 0 || titleinfo[@"chapters"] != nil) ? ((NSNumber *)titleinfo[@"chapters"]).stringValue : @"Unknown" withCellType:cellTypeInfo]];
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Volumes" withValue:(((NSNumber *)titleinfo[@"volumes"]).intValue > 0 || titleinfo[@"volumes"] != nil) ? ((NSNumber *)titleinfo[@"volumes"]).stringValue : @"Unknown" withCellType:cellTypeInfo]];
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Status" withValue:titleinfo[@"status"] withCellType:cellTypeInfo]];
    if (titleinfo[@"start_date"] && titleinfo[@"start_date"] != [NSNull null] && ((NSString *)titleinfo[@"start_date"]).length > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Started" withValue:titleinfo[@"start_date"] withCellType:cellTypeInfo]];
    }
    if (titleinfo[@"end_date"] && titleinfo[@"end_date"] != [NSNull null] && ((NSString *)titleinfo[@"end_date"]).length > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Ended" withValue:titleinfo[@"end_date"] withCellType:cellTypeInfo]];
    }
    // Other Info
    NSDictionary *dtitles =  titleinfo[@"other_titles"];
    NSMutableArray *othertitles = [NSMutableArray new];
    if (dtitles[@"english"] != nil){
        NSArray *e = dtitles[@"english"];
        for (NSString *etitle in e){
            [othertitles addObject:etitle];
        }
    }
    if (dtitles[@"japanese"] != nil){
        NSArray *j = dtitles[@"japanese"];
        for (NSString *jtitle in j){
            [othertitles addObject:jtitle];
        }
    }
    if (dtitles[@"synonyms"] != nil){
        NSArray *syn = dtitles[@"synonyms"];
        for (NSString *stitle in syn){
            [othertitles addObject:stitle];
        }
    }
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Other Titles" withValue:[Utility appendstringwithArray:othertitles] withCellType:cellTypeInfoExpand]];
    NSString *genres;
    if (titleinfo[@"genres"]!= nil) {
        NSArray *genresa = titleinfo[@"genres"];
        genres = [Utility appendstringwithArray:genresa];
    }
    else{
        genres = @"None";
    }
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Genres" withValue:genres withCellType:cellTypeInfoExpand]];
    if (titleinfo[@"members_score"] != nil || ((NSNumber *)titleinfo[@"members_score"]).intValue > 0) {
        NSString *scorestring = [NSString stringWithFormat:@"%.2f", ((NSNumber *)titleinfo[@"members_score"]).floatValue];
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:scorestring withCellType:cellTypeInfo]];
        _scorelabel.text = scorestring;
    }
    NSNumber *popularity = titleinfo[@"popularity_rank"];
    if (popularity.intValue > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Popularity" withValue:popularity.stringValue withCellType:cellTypeInfo]];
    }
    NSNumber *favorites = titleinfo[@"favorited_count"];
    if (favorites.intValue > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Favorited" withValue:favorites.stringValue withCellType:cellTypeInfo]];
    }
    [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Related" withCellAction:cellActionViewRelated]];
    [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:[listservice.sharedInstance getCurrentServiceID] == 2 ? @"Reactions" : @"Reviews" withCellAction:cellActionViewReviews]];
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 3:
            [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Characters/Staff" withCellAction:cellActionViewStaff]];
            break;
        case 1:
        case 2:
            break;
        default:
            break;
    }
    return detailarray.copy;
}

- (NSArray *)generateStreamSitesCellArray {
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *link in _streamsitelinks) {
        [tmparray addObject:[[EntryCellInfo alloc] initCellWithTitle:link[@"sitename"] withValue:[NSURL URLWithString:link[@"url"]] withCellType:cellTypeStreamSite]];
    }
    return tmparray;
}

#pragma mark updating

- (void)addAnimeEntry:(TitleInfoUpdateTableViewCell *)updatecell {
    NSDictionary *entry = [self generateUpdateDictionary];
    if ([self shouldShowScorePrompt:entry] && [NSUserDefaults.standardUserDefaults boolForKey:@"scoreprompt"]) {
        [self showScorePrompt:updatecell];
        return;
    }
    __weak TitleInfoViewController *weakSelf = self;
    [updatecell setEnabled: NO];
    [self showloadingview:YES];
    _navigationitem.hidesBackButton = YES;
    [listservice.sharedInstance addAnimeTitleToList:_titleid withEpisode:((NSNumber *)entry[@"episode"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue completion:^(id responseObject) {
        // Reload List
        ListViewController *lvc = [ViewControllerManager getAppDelegateViewControllerManager].getAnimeListRootViewController.lvc;
        [lvc retrieveList:YES completion:^(bool success) {
            if (success) {
                [weakSelf updateUserEntry];
                [lvc reloadList];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
            [updatecell setEnabled: YES];
            [weakSelf showloadingview:NO];
            weakSelf.navigationitem.hidesBackButton = NO;
                [weakSelf.tableview reloadData];
            });
        }];

    } error:^(NSError * error) {
        NSLog(@"%@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showError:error];
        [updatecell setEnabled: YES];
        [weakSelf showloadingview:NO];
        weakSelf.navigationitem.hidesBackButton = NO;
        });
    }];
}

- (void)addMangaEntry:(TitleInfoUpdateTableViewCell *)updatecell {
    NSDictionary *entry = [self generateUpdateDictionary];
    if ([self shouldShowScorePrompt:entry] && [NSUserDefaults.standardUserDefaults boolForKey:@"scoreprompt"]) {
        [self showScorePrompt:updatecell];
        return;
    }
    __weak TitleInfoViewController *weakSelf = self;
    [updatecell setEnabled: NO];
    [self showloadingview:YES];
    _navigationitem.hidesBackButton = YES;
    [listservice.sharedInstance addMangaTitleToList:_titleid withChapter:((NSNumber *)entry[@"chapter"]).intValue withVolume:((NSNumber *)entry[@"volume"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue completion:^(id responseObject) {
        ListViewController *lvc = [ViewControllerManager getAppDelegateViewControllerManager].getMangaListRootViewController.lvc;
        [lvc retrieveList:YES completion:^(bool success) {
            if (success) {
                [weakSelf updateUserEntry];
                [lvc reloadList];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [updatecell setEnabled: YES];
                [weakSelf showloadingview:NO];
            weakSelf.navigationitem.hidesBackButton = NO;
                [weakSelf.tableview reloadData];
            });
        }];
    } error:^(NSError *error) {
        NSLog(@"%@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showError:error];
        [updatecell setEnabled: YES];
        [weakSelf showloadingview:NO];
        weakSelf.navigationitem.hidesBackButton = NO;
        });
    }];
}

- (void)updateAnime:(TitleInfoUpdateTableViewCell *)updatecell {
    NSDictionary *entry = [self generateUpdateDictionary];
    if ([self shouldShowScorePrompt:entry] && [NSUserDefaults.standardUserDefaults boolForKey:@"scoreprompt"]) {
        [self showScorePrompt:updatecell];
        return;
    }
    NSDictionary * extraparameters = @{};
    int selectededitid = 0;
    int currentservice = [listservice.sharedInstance getCurrentServiceID];
    switch (currentservice) {
        case 1: {
            extraparameters = @{@"is_rewatching" : @(self.selectedreconsuming)};
            selectededitid = self.titleid;
            break;
        }
        case 2:
        case 3: {
            extraparameters = @{@"reconsuming" : @(self.selectedreconsuming)};
            selectededitid = self.entryid;
            break;
        }
        default:
            break;
    }
    __weak TitleInfoViewController *weakSelf = self;
    [updatecell setEnabled: NO];
    [self showloadingview:YES];
    _navigationitem.hidesBackButton = YES;
    [listservice.sharedInstance updateAnimeTitleOnList:selectededitid withEpisode:((NSNumber *)entry[@"episode"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue withExtraFields:extraparameters completion:^(id responseobject) {
        NSDictionary *updatedfields = @{@"watched_episodes" : entry[@"episode"], @"watched_status" : entry[@"status"], @"score" : entry[@"score"], @"rewatching" : @(weakSelf.selectedreconsuming), @"last_updated" : [Utility getLastUpdatedDateWithResponseObject:responseobject withService:[listservice.sharedInstance getCurrentServiceID]]};
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:0 withId:weakSelf.titleid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:0 withId:weakSelf.entryid withIdType:1];
                break;
        }
        [HistoryManager.sharedInstance insertHistoryRecord:self.titleid withTitle:self.navigationitem.title withHistoryActionType:HistoryActionTypeUpdateTitle withSegment:((NSNumber *)entry[@"episode"]).intValue withMediaType:0 withService:listservice.sharedInstance.getCurrentServiceID];
        // Reload List
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:@"AnimeReloadList" object:nil];
                [updatecell setEnabled: YES];
                [weakSelf showloadingview:NO];
                [weakSelf setmodified:NO];
                weakSelf.navigationitem.hidesBackButton = NO;
                [weakSelf.tableview reloadData];
            });
    }
    error:^(NSError * error) {
        NSLog(@"%@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showError:error];
        [updatecell setEnabled: NO];
        [weakSelf showloadingview:NO];
        weakSelf.navigationitem.hidesBackButton = NO;
            });
    }];
}

- (void)updateManga:(TitleInfoUpdateTableViewCell *)updatecell {
    NSDictionary *entry = [self generateUpdateDictionary];
    if ([self shouldShowScorePrompt:entry] && [NSUserDefaults.standardUserDefaults boolForKey:@"scoreprompt"]) {
        [self showScorePrompt:updatecell];
        return;
    }
    NSDictionary * extraparameters = @{};
    int selectededitid = 0;
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1: {
            extraparameters = @{@"is_rereading" : @(self.selectedreconsuming)};
            selectededitid = self.titleid;
            break;
        }
        case 2:
        case 3: {
            extraparameters = @{@"reconsuming" : @(self.selectedreconsuming)};
            selectededitid = self.entryid;
            break;
        }
        default:
            break;
    }
    __weak TitleInfoViewController *weakSelf = self;
    [updatecell setEnabled: NO];
    [self showloadingview:YES];
    _navigationitem.hidesBackButton = YES;
    [listservice.sharedInstance updateMangaTitleOnList:selectededitid withChapter:((NSNumber *)entry[@"chapter"]).intValue withVolume:((NSNumber *)entry[@"volume"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue withExtraFields:extraparameters completion:^(id responseobject) {
        NSDictionary *updatedfields = @{@"chapters_read" : entry[@"chapter"], @"volumes_read" : entry[@"volume"], @"read_status" : entry[@"status"], @"score" : entry[@"score"], @"rereading" : @(weakSelf.selectedreconsuming), @"last_updated" : [Utility getLastUpdatedDateWithResponseObject:responseobject withService:[listservice.sharedInstance getCurrentServiceID]]};
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:1 withId:selectededitid withIdType:1];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:1 withId:selectededitid withIdType:1];
                break;
        }
        [HistoryManager.sharedInstance insertHistoryRecord:self.titleid withTitle:self.navigationitem.title withHistoryActionType:HistoryActionTypeUpdateTitle withSegment:((NSNumber *)entry[@"chapter"]).intValue withMediaType:1 withService:listservice.sharedInstance.getCurrentServiceID];
        // Reload List
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:@"MangaReloadList" object:nil];
            [updatecell setEnabled: YES];
            [weakSelf setmodified:NO];
            [weakSelf showloadingview:NO];
            weakSelf.navigationitem.hidesBackButton = NO;
            [weakSelf.tableview reloadData];
        });
    }error:^(NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showError:error];
        NSLog(@"%@", error.localizedDescription);
        [updatecell setEnabled: YES];
        [weakSelf showloadingview:NO];
        weakSelf.navigationitem.hidesBackButton = NO;
        });
    }];
}

- (bool)validateCells {
    switch (_currenttype) {
        case 0: {
            EntryCellInfo *episodecell;
            EntryCellInfo *statuscell;
            for (EntryCellInfo *cellInfo in _items[@"Your Entry"]) {
                if (cellInfo.type == cellTypeAction) {
                    continue;
                }
                else {
                    if ([cellInfo.cellTitle isEqualToString:@"Episode"]) {
                        episodecell = cellInfo;
                    }
                    else if ([cellInfo.cellTitle isEqualToString:@"Status"]) {
                        statuscell = cellInfo;
                    }
                }
            }
            if (!_selectedaired && (![(NSString *)statuscell.cellValue isEqual:@"plan to watch"] || ((NSNumber *)episodecell.cellValue).intValue > 0)) {
                // Invalid input, mark it as such
                return false;
            }
            if (((NSNumber *)episodecell.cellValue).intValue == episodecell.cellValueMax && episodecell.cellValueMax != 0 && _selectedaircompleted && _selectedaired) {
                statuscell.cellValue = @"completed";
                episodecell.cellValue = @(episodecell.cellValueMax);
                _selectedreconsuming = false;
            }
            if ([(NSString *)statuscell.cellValue isEqual:@"completed"] && episodecell.cellValueMax != 0 && ((NSNumber *)episodecell.cellValue).intValue != episodecell.cellValueMax && _selectedaircompleted) {
                episodecell.cellValue = @(episodecell.cellValueMax);
                _selectedreconsuming = false;
            }
            if (![(NSString *)statuscell.cellValue isEqual:@"completed"] && ((NSNumber *)episodecell.cellValue).intValue == episodecell.cellValueMax && _selectedaircompleted) {
                statuscell.cellValue = @"completed";
                _selectedreconsuming = false;
            }
            return true;
        }
        case 1: {
            EntryCellInfo *chaptercell;
            EntryCellInfo *volumecell;
            EntryCellInfo *statuscell;
            for (EntryCellInfo *cellInfo in _items[@"Your Entry"]) {
                if (cellInfo.type == cellTypeAction) {
                    continue;
                }
                else {
                    if ([cellInfo.cellTitle isEqualToString:@"Chapter"]) {
                        chaptercell = cellInfo;
                    }
                    else if ([cellInfo.cellTitle isEqualToString:@"Volume"]) {
                        volumecell = cellInfo;
                    }
                    else if ([cellInfo.cellTitle isEqualToString:@"Status"]) {
                        statuscell = cellInfo;
                    }
                }
            }
            if(!_selectedpublished && (![(NSString *)statuscell.cellValue isEqual:@"plan to read"] ||((NSNumber *)chaptercell.cellValue).intValue  > 0 || ((NSNumber *)volumecell.cellValue).intValue  > 0)) {
                // Invalid input, mark it as such
                return false;
            }
            if (((((NSNumber *)chaptercell.cellValue).intValue  == chaptercell.cellValueMax && chaptercell.cellValueMax != 0) || (((NSNumber *)volumecell.cellValue).intValue == volumecell.cellValueMax && volumecell.cellValueMax != 0)) && _selectedfinished && _selectedpublished) {
                statuscell.cellValue = @"completed";
                chaptercell.cellValue = @(chaptercell.cellValueMax);
                volumecell.cellValue= @(volumecell.cellValueMax);
                _selectedreconsuming = false;
            }
            if ([(NSString *)statuscell.cellValue isEqual:@"completed"] && ((((NSNumber *)chaptercell.cellValue).intValue != chaptercell.cellValueMax && chaptercell.cellValueMax != 0) || (((NSNumber *)volumecell.cellValue).intValue != volumecell.cellValueMax && volumecell.cellValueMax != 0)) && _selectedfinished) {
                chaptercell.cellValue = @(chaptercell.cellValueMax);
                volumecell.cellValue = @(volumecell.cellValueMax);
                _selectedreconsuming = false;
            }
            if (![(NSString *)statuscell.cellValue isEqual:@"completed"] && ((NSNumber *)chaptercell.cellValue).intValue  == chaptercell.cellValueMax && ((NSNumber *)volumecell.cellValue).intValue  == volumecell.cellValueMax   && _selectedfinished) {
                statuscell.cellValue = @"completed";
                _selectedreconsuming = false;
            }
            return true;
        }
    }
    return false;
}

#pragma mark Score Prompt
- (bool)shouldShowScorePrompt:(NSDictionary *)entry {
    if (self.surpressscoreprompt) {
        return false;
    }
    else if (self.currenttype == 0) {
        if (_entrychanged && [(NSString *)entry[@"status"] isEqualToString:@"completed"] && ((NSNumber *)entry[@"score"]).doubleValue == 0) {
            return true;
        }
        return false;
    }
    else {
        if (_entrychanged && [(NSString *)entry[@"status"] isEqualToString:@"completed"] && ((NSNumber *)entry[@"score"]).doubleValue == 0) {
            return true;
        }
        return false;
    }
    return false;
}

- (void)showScorePrompt:(TitleInfoUpdateTableViewCell *)updatecell {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Set a score?" message:@"It looks like you completed a title. Do you want to set a score before saving the entry? You can always set a score later." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.surpressscoreprompt = true;
        if (self.isNewEntry) {
            if (self.currenttype == 0) {
                [self addAnimeEntry:updatecell];
            }
            else {
                [self addMangaEntry:updatecell];
            }
        }
        else {
            if (self.currenttype == 0) {
                [self updateAnime:updatecell];
            }
            else {
                [self updateManga:updatecell];
            }
        }
    }];
    [alertcontroller addAction:noaction];
    [alertcontroller addAction:yesaction];
    [self presentViewController:alertcontroller animated:YES completion:nil];
}


- (NSDictionary *)generateUpdateDictionary {
    NSMutableDictionary *info = [NSMutableDictionary new];
    for (EntryCellInfo *cellInfo in _items[@"Your Entry"]) {
        if (cellInfo.type == cellTypeAction) {
            continue;
        }
        else {
            info[cellInfo.cellTitle.lowercaseString] = cellInfo.cellValue;
        }
    }
    return info.copy;
}

- (int)getSegmentInfo:(NSString *)segmentname {
    for (EntryCellInfo *cell in _items[@"Title Details"]) {
        if ([cell.cellTitle caseInsensitiveCompare:segmentname] == NSOrderedSame) {
            return ((NSString *)cell.cellValue).intValue;
        }
    }
    return -1;
}

- (NSArray *)aggregateTitles:(NSDictionary *)titleinfo {
    NSMutableArray *titles = [NSMutableArray new];
    [titles addObject:titleinfo[@"title"]];
    NSDictionary *dtitles =  titleinfo[@"other_titles"];
    if (dtitles[@"english"] != nil){
        NSArray *e = dtitles[@"english"];
        for (NSString *etitle in e){
            [titles addObject:etitle];
        }
    }
    if (dtitles[@"japanese"] != nil){
        NSArray *j = dtitles[@"japanese"];
        for (NSString *jtitle in j){
            [titles addObject:jtitle];
        }
    }
    if (dtitles[@"synonyms"] != nil){
        NSArray *syn = dtitles[@"synonyms"];
        for (NSString *stitle in syn){
            [titles addObject:stitle];
        }
    }
    return titles.copy;
}

- (NSArray *)generateSections {
    NSMutableArray *sections = [NSMutableArray new];
    if (_items[@"Your Entry"]) {
        [sections addObject:@"Your Entry"];
    }
    if (_items[@"Synopsis"]) {
        [sections addObject:@"Synopsis"];
    }
    if (_items[@"Title Details"]) {
        [sections addObject:@"Title Details"];
    }
    if (_items[@"Stream Sites"] && _currenttype == Anime) {
        [sections addObject:@"Stream Sites"];
    }
    return sections;
}

#pragma mark other view controllers
- (void)showReviews {
    ReviewTableViewController *reviewtvc = [self.storyboard instantiateViewControllerWithIdentifier:@"reviewtablevc"];
    [self.navigationController pushViewController:reviewtvc animated:YES];
    [reviewtvc retrieveReviewsForTitleID:_titleid withType:_currenttype];
}

- (void)showStaff {
    CharacterTableViewController *charactervc = [self.storyboard instantiateViewControllerWithIdentifier:@"StaffTbVC"];
    [self.navigationController pushViewController:charactervc animated:YES];
    [charactervc retrievePersonList:_titleid withType:_currenttype];
}

- (void)showEpisodes {
    EpisodesTableViewController *episodesvc = [self.storyboard instantiateViewControllerWithIdentifier:@"episodestbvc"];
    [self.navigationController pushViewController:episodesvc animated:YES];
    [episodesvc loadEpisodeListForTitleId:_titleid];
}

- (void)showloadingview:(bool)show {
    if (show && !_refreshing) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.label.text = @"Loading";
        if (@available(iOS 13, *)) { }
        else {
            _hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
            _hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
        }
        _refreshing = YES;
    }
    else if (!show) {
        [_hud hideAnimated:YES];
        _refreshing = NO;
    }
    _titleinfobaritem.enabled = !show;
    _shareitembaritem.enabled = !show;
    _optionsitembaritem.enabled = !show;
}

- (void)showError:(NSError *)error {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Operation failed" message:[NSString stringWithFormat:@"%@", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertcontroller addAction:okaction];
    [self.navigationController presentViewController:alertcontroller animated:YES completion:nil];
}
- (void)checkUnsavedChangesWithBlock:(void (^)(void))actionBlock {
    if (_entrychanged) {
        [self showUnsavedChangesWithBlock:actionBlock];
    }
    else {
        actionBlock();
    }
}

- (void)showUnsavedChangesWithBlock:(void (^)(void))actionBlock {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Unsaved Changes" message:@"Do you want to leave this title's information page without saving your library entry? Unsaved changes will be lost." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self updateUserEntry];
        actionBlock();
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertcontroller addAction:noaction];
    [alertcontroller addAction:yesaction];
    [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)setmodified:(bool)modified {
    _entrychanged = modified;
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = !modified;
    }
}

#pragma mark tableview cell registration
- (void)registerTableViewCells {
    NSDictionary *cells = @{@"TitleInfoListEntryTableViewCell" : @"editdetailcell", @"TitleInfoProgressTableViewCell" : @"progresscell", @"TitleInfoAdvScoreEntryTableViewCell" : @"advscorecell", @"TitleInfoBasicTableViewCell" : @"titleinfocell", @"TitleInfoBasicExpandTableViewCell" : @"titleinfocellexpand", @"TitleInfoSynopsisTableViewCell" : @"synopsiscell", @"TitleInfoUpdateTableViewCell" : @"actioncell", @"TitleInfoStreamSiteTableViewCell" : @"streamsitecell"};
    for (NSString *nibName in cells.allKeys) {
        [self.tableview registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:cells[nibName]];
    }
}

#pragma mark Safari View Controller
- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)openWebBrowserView:(NSURL *)url {
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:url];
    if (@available(iOS 13, *)) { }
    else {
        svc.preferredBarTintColor = [ThemeManager sharedCurrentTheme].viewBackgroundColor;
        svc.preferredControlTintColor = [ThemeManager sharedCurrentTheme].tintColor;
    }
    [self presentViewController:svc animated:YES completion:^{
    }];
}
@end

@implementation TitleInfoViewControllerView

@end
