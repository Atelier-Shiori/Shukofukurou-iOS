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
#import "StreamDataRetriever.h"
#import "TitleInfoCache.h"

@interface TitleInfoViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *posterImage;
@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationitem;
@property (strong) NSMutableDictionary *items;
@property (strong) NSArray *sections;
@property int currenttype;
@property int entryid;
@property int titleid;
@property bool forcerefresh;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *loadingview;
@property (weak, nonatomic) IBOutlet UILabel *titlestatus;
@property (weak, nonatomic) IBOutlet UILabel *titletype;
@property (strong) RelatedTableViewController *relatedtvc;
@end

@implementation TitleInfoViewController

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"UserLoggedIn" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"UserLoggedOut" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"ServiceChanged" object:nil];
    _relatedtvc = [self.storyboard instantiateViewControllerWithIdentifier:@"relatedview"];
}

- (void)recieveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"UserLoggedIn"]) {
        if (notification.object) {
            if (((ListViewController *)notification.object).listtype == _currenttype) {
                _sections = [self generateSections];
                [self updateUserEntry];
            }
        }
    }
    else if ([notification.name isEqualToString:@"UserLoggedOut"]) {
        // Remove Your Entry section
        _sections = [self generateSections];
        [_items removeObjectForKey:@"Your Entry"];
        [_tableview reloadData];
    }
    else if ([notification.name isEqualToString:@"ServiceChanged"]) {
        // Leave Title Information
        self.navigationItem.hidesBackButton = NO;
        _loadingview.hidden = YES;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)loadTitleInfo:(int)titleid withType:(int)type {
    _titleid = titleid;
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"] && !_forcerefresh) {
        NSDictionary *titleinfo = [TitleInfoCache getTitleInfoWithTitleID:titleid withServiceID:[listservice getCurrentServiceID] withType:type ignoreLastUpdated:NO];
        if (titleinfo) {
            [self populateInfoWithType:type withDictionary:titleinfo];
            [self view];
            self.loadingview.hidden = YES;
            return;
        }
    }
    __weak TitleInfoViewController *weakSelf = self;
    self.navigationItem.hidesBackButton = YES;
    self.loadingview.hidden = NO;
    [listservice retrieveTitleInfo:titleid withType:type useAccount:NO completion:^(id responseObject) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"]) {
            [weakSelf populateInfoWithType:type withDictionary:[TitleInfoCache saveTitleInfoWithTitleID:titleid withServiceID:[listservice getCurrentServiceID] withType:type withResponseObject:responseObject]];
            weakSelf.forcerefresh = false;
        }
        else {
            [weakSelf populateInfoWithType:type withDictionary:responseObject];
        }
        weakSelf.navigationItem.hidesBackButton = NO;
        weakSelf.loadingview.hidden = YES;
    } error:^(NSError *error) {
        NSLog(@"%@",error);
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"]) {
            NSDictionary *titleinfo = [TitleInfoCache getTitleInfoWithTitleID:titleid withServiceID:[listservice getCurrentServiceID] withType:type ignoreLastUpdated:NO];
            if (titleinfo) {
                [self populateInfoWithType:type withDictionary:titleinfo];
                [self view];
                self.loadingview.hidden = YES;
                weakSelf.forcerefresh = false;
                return;
            }
        }
        weakSelf.navigationItem.hidesBackButton = NO;
        weakSelf.loadingview.hidden = YES;
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)populateInfoWithType:(int)type withDictionary:(NSDictionary *)titleinfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currenttype = type;
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
            if ([airingstatus isEqualToString:@"finished airing"]||[airingstatus isEqualToString:@"currently airing"]) {
                self.selectedaired = true;
            }
            else {
                self.selectedaired = false;
            }
        }
        else {
            NSString *publishtatus = titleinfo[@"status"];
            self.titlestatus.text = publishtatus;
            self.titletype.text = titleinfo[@"type"];
            if ([publishtatus isEqualToString:@"finished"]) {
                self.selectedfinished = true;
            }
            else {
                self.selectedfinished = false;
            }
            if ([publishtatus isEqualToString:@"finished"]||[publishtatus isEqualToString:@"publishing"]) {
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
    [options addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"View on %@", [listservice currentservicename]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf performViewOnListSite];
    }]];
    [options addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf performShare:sender];
    }]];
    [options addAction:[UIAlertAction actionWithTitle:@"Advanced Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UINavigationController *navController = [UINavigationController new];
        AdvEditTableViewController *advedit = [[UIStoryboard storyboardWithName:@"AdvancedEdit" bundle:nil] instantiateViewControllerWithIdentifier:@"advedit"];
        [advedit populateTableViewWithID:weakSelf.titleid withEntryDictionary:[AtarashiiListCoreData retrieveSingleEntryForTitleID:weakSelf.titleid withService:[listservice getCurrentServiceID] withType:weakSelf.currenttype] withType:weakSelf.currenttype];
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
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"]) {
        [options addAction:[UIAlertAction actionWithTitle:@"Refresh Title Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            weakSelf.forcerefresh = true;
            [weakSelf loadTitleInfo:weakSelf.titleid withType:weakSelf.currenttype];
        }]];
    }
    if (self.navigationController.viewControllers.count > 3) {
        [options addAction:[UIAlertAction actionWithTitle:@"Return to Parent" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        }]];
    }
    [options addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    
    options.popoverPresentationController.barButtonItem = sender;
    options.popoverPresentationController.sourceView = self.view;
    
    [self
     presentViewController:options
     animated:YES
     completion:nil];
}

- (void)performViewOnListSite {
    NSString *URL = [self getTitleURL];
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:URL] options:@{} completionHandler:^(BOOL success) {}];
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
    switch ([listservice getCurrentServiceID]) {
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
        int currentservice = [listservice getCurrentServiceID];
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
        };
    }
    else if ([cellInfo.cellTitle isEqualToString:@"Score"]) {
        cell.rawValue = ((NSNumber *)cellInfo.cellValue).intValue;
        switch ([listservice getCurrentServiceID]) {
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
    cell.stepper.value = cell.currentprogress;
    cell.stepper.maximumValue = cellInfo.cellValueMax > 0 ? cellInfo.cellValueMax : 999999999;
    cell.episodefield.text = @(cell.currentprogress).stringValue;
    cell.valueChanged = ^(NSNumber * _Nonnull newvalue, NSString * _Nonnull fieldname) {
        cellInfo.cellValue = newvalue;
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
            break;
        case cellActionViewStaff:
        case cellActionViewReviews:
        case cellActionViewRelated:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            break;
    }
    __weak TitleInfoViewController *weakSelf = self;
    cell.cellPressed = ^(int actiontype, TitleInfoUpdateTableViewCell * _Nonnull cell) {
        if ([weakSelf validateCells]) {
            if (weakSelf.currenttype == 0) {
                switch (actiontype) {
                    case cellActionAddEntry:
                        [self addAnimeEntry:cell];
                        break;
                    case cellActionUpdateEntry:
                        [self updateAnime:cell];
                        break;
                    case cellActionViewRelated:
                        [self.navigationController pushViewController:weakSelf.relatedtvc animated:YES];
                        break;
                    case cellActionViewReviews:
                        [self showReviews];
                        break;
                    case cellActionViewStaff:
                        [self showStaff];
                        break;
                    default:
                        break;
                }
            }
            else {
                switch (actiontype) {
                    case cellActionAddEntry:
                        [self addMangaEntry:cell];
                        break;
                    case cellActionUpdateEntry:
                        [self updateManga:cell];
                        break;
                    case cellActionViewRelated:
                        [self.navigationController pushViewController:weakSelf.relatedtvc animated:YES];
                        break;
                    case cellActionViewReviews:
                        [self showReviews];
                        break;
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
    ((UITableViewCell *)cell).selected = NO;
}

#pragma mark Data Source Dictionary Generators

- (void)populateWithInfowithDictionary:(NSDictionary *)titleinfo withType:(int)type {
    NSMutableDictionary *tmpdictionary = [NSMutableDictionary new];
    NSDictionary *userentry;
    if ([listservice checkAccountForCurrentService]) {
        userentry = [AtarashiiListCoreData retrieveSingleEntryForTitleID:((NSNumber *)titleinfo[@"id"]).intValue withService:[listservice getCurrentServiceID] withType:type];
        if (!userentry) {
            // Generate blank user entry
            if (type == 0) {
                userentry = @{@"watched_episodes" : @(0), @"watched_status" : @"watching", @"score" : @(0) , @"episodes" : titleinfo[@"episodes"]};
            }
            else {
                userentry = @{@"chapters_read" : @(0), @"volumes_read" : @(0), @"read_status" : @"reading", @"score" : @(0), @"chapters" : titleinfo[@"chapters"], @"volumes" : titleinfo[@"volumes"]};
            }
            _entryid = 0;
        }
        else {
            _entryid = ((NSNumber *)userentry[@"entryid"]).intValue;
            _selectedreconsuming = _currenttype == 0 ? ((NSNumber *)userentry[@"rewatching"]).boolValue : ((NSNumber *)userentry[@"rereading"]).boolValue;
        }
    }
    // Set Title, Poster Image and Synopsis
    if (((NSString *)titleinfo[@"image_url"]).length > 0) {
        [_posterImage sd_setImageWithURL:[NSURL URLWithString:(NSString *)titleinfo[@"image_url"]]];
    }
    else {
        _posterImage.image = [UIImage new];
    }
    // Generate Cell Array
    tmpdictionary[@"Synopsis"] = @[[[EntryCellInfo alloc] initCellWithTitle:@"" withValue:titleinfo[@"synopsis"] withCellType:cellTypeSynopsis]];
    tmpdictionary[@"Title Details"] = type == 0 ? [self generateAnimeTitleArray:titleinfo] : [self generateMangaTitleArray:titleinfo];
    if (userentry) {
        tmpdictionary[@"Your Entry"] = type == 0 ? [self generateUserEntryAnimeArray:userentry] : [self generateUserEntryMangaArray:userentry];
    }
    if (_currenttype == Anime) {
        NSDictionary *streamsites;
        NSArray *titles = [self aggregateTitles:titleinfo];
        for (NSString *stitle in titles) {
            streamsites = [StreamDataRetriever retrieveSitesForTitle:stitle];
            if (streamsites.allKeys.count > 0) {
                tmpdictionary[@"Stream Sites"] = [self generateStreamSitesCellArray:streamsites];
                break;
            }
        }
    }
    _items = tmpdictionary;
    _sections = [self generateSections];
    [_tableview reloadData];
}

- (NSArray *)generateUserEntryAnimeArray:(NSDictionary *)entry {
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

- (NSArray *)generateUserEntryMangaArray:(NSDictionary *)entry {
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
    int currentService = [listservice getCurrentServiceID];
    NSDictionary *userentry = [AtarashiiListCoreData retrieveSingleEntryForTitleID:_titleid withService:currentService withType:_currenttype];
    if (!userentry) {
        // Generate blank user entry
        if (_currenttype == 0) {
            userentry = @{@"watched_episodes" : @(0), @"watched_status" : @"watching", @"score" : @(0) , @"episodes" : @([self getSegmentInfo:@"episodes"])};
        }
        else {
            userentry = @{@"chapters_read" : @(0), @"volumes_read" : @(0), @"read_status" : @"reading", @"score" : @(0), @"chapters" : @([self getSegmentInfo:@"chapters"]), @"volumes" : @([self getSegmentInfo:@"volumes"])};
        }
        _entryid = 0;
    }
    else {
        _selectedreconsuming = _currenttype == 0 ? ((NSNumber *)userentry[@"rewatching"]).boolValue : ((NSNumber *)userentry[@"rereading"]).boolValue;
    }
    _items[@"Your Entry"] = _currenttype == 0 ? [self generateUserEntryAnimeArray:userentry] : [self generateUserEntryMangaArray:userentry];
    switch (currentService) {
        case 2:
        case 3:
            _entryid = ((NSNumber *)userentry[@"entryid"]).intValue;
            break;
            
        default:
            break;
    }
    [_tableview reloadData];
}

- (NSArray *)generateAnimeTitleArray:(NSDictionary *)titleinfo {
    NSMutableArray *detailarray = [NSMutableArray new];
    // Basic Info
    // [detailarray addObject:@{@"title" : @"Type", @"values" : @""}];
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Type" withValue:titleinfo[@"type"] withCellType:cellTypeInfo]];
    [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Episodes" withValue:(((NSNumber *)titleinfo[@"episodes"]).intValue > 0 || titleinfo[@"episodes"] != nil) ? ((NSNumber *)titleinfo[@"episodes"]).stringValue : @"Unknown" withCellType:cellTypeInfo]];
    if (titleinfo[@"duration"] == nil  || ((NSNumber *)titleinfo[@"duration"]).intValue == 0){
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Duration" withValue:((NSNumber *)titleinfo[@"duration"]).stringValue withCellType:cellTypeInfo]];
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
    if (titleinfo[@"members_score"] != nil || ((NSNumber *)titleinfo[@"members_score"]).intValue > 0) {
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:[NSString stringWithFormat:@"%.2f", ((NSNumber *)titleinfo[@"members_score"]).floatValue] withCellType:cellTypeInfo]];
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
    [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:[listservice getCurrentServiceID] == 2 ? @"Reactions" : @"Reviews" withCellAction:cellActionViewReviews]];
    switch ([listservice getCurrentServiceID]) {
        case 1:
        case 3:
            [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:@"Characters/Staff" withCellAction:cellActionViewStaff]];
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
        [detailarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:[NSString stringWithFormat:@"%.2f", ((NSNumber *)titleinfo[@"members_score"]).floatValue] withCellType:cellTypeInfo]];
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
    [detailarray addObject:[[EntryCellInfo alloc] initActionCellWithTitle:[listservice getCurrentServiceID] == 2 ? @"Reactions" : @"Reviews" withCellAction:cellActionViewReviews]];
    return detailarray.copy;
}

- (NSArray *)generateStreamSitesCellArray:(NSDictionary *)sitesDictionary {
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSString *sitename in [sitesDictionary.allKeys sortedArrayUsingSelector: @selector(compare:)]) {
        [tmparray addObject:[[EntryCellInfo alloc] initCellWithTitle:sitename withValue:[NSURL URLWithString:sitesDictionary[sitename]] withCellType:cellTypeStreamSite]];
    }
    return tmparray;
}

#pragma mark updating

- (void)addAnimeEntry:(TitleInfoUpdateTableViewCell *)updatecell {
    NSDictionary *entry = [self generateUpdateDictionary];
    __weak TitleInfoViewController *weakSelf = self;
    [updatecell setEnabled: NO];
    _loadingview.hidden = NO;
    _navigationitem.hidesBackButton = YES;
    [listservice addAnimeTitleToList:_titleid withEpisode:((NSNumber *)entry[@"episode"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue completion:^(id responseObject) {
        // Reload List
        ListViewController *lvc = [ViewControllerManager getAppDelegateViewControllerManager].getAnimeListRootViewController.lvc;
        [lvc retrieveList:YES completion:^(bool success) {
            if (success) {
                [weakSelf updateUserEntry];
                [lvc reloadList];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
            [updatecell setEnabled: YES];
            weakSelf.loadingview.hidden = YES;
            weakSelf.navigationitem.hidesBackButton = NO;
                [weakSelf.tableview reloadData];
            });
        }];

    } error:^(NSError * error) {
        NSLog(@"%@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
        [updatecell setEnabled: YES];
        weakSelf.loadingview.hidden = YES;
        weakSelf.navigationitem.hidesBackButton = NO;
        });
    }];
}

- (void)addMangaEntry:(TitleInfoUpdateTableViewCell *)updatecell {
    NSDictionary *entry = [self generateUpdateDictionary];
    __weak TitleInfoViewController *weakSelf = self;
    [updatecell setEnabled: NO];
    _loadingview.hidden = NO;
    _navigationitem.hidesBackButton = YES;
    [listservice addMangaTitleToList:_titleid withChapter:((NSNumber *)entry[@"chapter"]).intValue withVolume:((NSNumber *)entry[@"volume"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue completion:^(id responseObject) {
        ListViewController *lvc = [ViewControllerManager getAppDelegateViewControllerManager].getMangaListRootViewController.lvc;
        [lvc retrieveList:YES completion:^(bool success) {
            if (success) {
                [weakSelf updateUserEntry];
                [lvc reloadList];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
            [updatecell setEnabled: YES];
            weakSelf.loadingview.hidden = YES;
            weakSelf.navigationitem.hidesBackButton = NO;
                [weakSelf.tableview reloadData];
            });
        }];
    } error:^(NSError *error) {
        NSLog(@"%@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
        [updatecell setEnabled: YES];
        weakSelf.loadingview.hidden = YES;
        weakSelf.navigationitem.hidesBackButton = NO;
        });
    }];
}

- (void)updateAnime:(TitleInfoUpdateTableViewCell *)updatecell {
    NSDictionary *entry = [self generateUpdateDictionary];
    NSDictionary * extraparameters = @{};
    int selectededitid = 0;
    int currentservice = [listservice getCurrentServiceID];
    switch (currentservice) {
        case 1: {
            extraparameters = @{@"rewatching" : @(self.selectedreconsuming)};
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
    _loadingview.hidden = NO;
    _navigationitem.hidesBackButton = YES;
    [listservice updateAnimeTitleOnList:selectededitid withEpisode:((NSNumber *)entry[@"episode"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue withExtraFields:extraparameters completion:^(id responseobject) {
        NSDictionary *updatedfields = @{@"watched_episodes" : entry[@"episode"], @"watched_status" : entry[@"status"], @"score" : entry[@"score"], @"rewatching" : @(weakSelf.selectedreconsuming)};
        switch ([listservice getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserName:[listservice getCurrentServiceUsername] withService:[listservice getCurrentServiceID] withType:0 withId:weakSelf.titleid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:0 withId:weakSelf.entryid withIdType:1];
                break;
        }
        // Reload List
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:@"AnimeReloadList" object:nil];
        [updatecell setEnabled: YES];
        weakSelf.loadingview.hidden = YES;
        weakSelf.navigationitem.hidesBackButton = NO;
                [weakSelf.tableview reloadData];
            });
    }
    error:^(NSError * error) {
        NSLog(@"%@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
        [updatecell setEnabled: YES];
        weakSelf.loadingview.hidden = YES;
        weakSelf.navigationitem.hidesBackButton = NO;
            });
    }];
}

- (void)updateManga:(TitleInfoUpdateTableViewCell *)updatecell {
    NSDictionary *entry = [self generateUpdateDictionary];
    NSDictionary * extraparameters = @{};
    int selectededitid = 0;
    switch ([listservice getCurrentServiceID]) {
        case 1: {
            extraparameters = @{@"rereading" : @(self.selectedreconsuming)};
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
    _loadingview.hidden = NO;
    _navigationitem.hidesBackButton = YES;
    [listservice updateMangaTitleOnList:selectededitid withChapter:((NSNumber *)entry[@"chapter"]).intValue withVolume:((NSNumber *)entry[@"volume"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue withExtraFields:extraparameters completion:^(id responseobject) {
        NSDictionary *updatedfields = @{@"chapters_read" : entry[@"chapter"], @"volumes_read" : entry[@"volume"], @"read_status" : entry[@"status"], @"score" : entry[@"score"], @"rereading" : @(weakSelf.selectedreconsuming)};
        switch ([listservice getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserName:[listservice getCurrentServiceUsername] withService:[listservice getCurrentServiceID] withType:1 withId:selectededitid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:1 withId:selectededitid withIdType:1];
                break;
        }
        // Reload List
        dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:@"MangaReloadList" object:nil];
        [updatecell setEnabled: YES];
        weakSelf.loadingview.hidden = YES;
        weakSelf.navigationitem.hidesBackButton = NO;
            [weakSelf.tableview reloadData];
        });
    }error:^(NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@", error.localizedDescription);
        [updatecell setEnabled: YES];
        weakSelf.loadingview.hidden = YES;
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
    [charactervc retrievePersonList:_titleid];
}
@end
