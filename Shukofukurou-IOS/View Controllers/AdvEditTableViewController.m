//
//  AdvEditTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/25/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AdvEditTableViewController.h"
#import "AtarashiiListCoreData.h"
#import "AniListScoreConvert.h"
#import "RatingTwentyConvert.h"
#import "EntryCellInfo.h"
#import "TitleInfoTableViewCell.h"
#import "listservice.h"
#import "ThemeManager.h"
#import <MBProgressHudFramework/MBProgressHUD.h>
#import "Utility.h"
#import "HistoryManager.h"

@interface AdvEditTableViewController ()
@property (strong) NSDictionary *origentry;
@property (strong) NSArray *cellEntries;
@property int currenttype;
@property int titleid;
@property int entryid;
@property bool selectedaired;
@property bool selectedaircompleted;
@property bool selectedfinished;
@property bool selectedpublished;
@property bool selectedreconsuming;
@property (weak, nonatomic) IBOutlet UINavigationItem *navitem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *savebtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelbtn;
@property (strong) MBProgressHUD *hud;
@end

@implementation AdvEditTableViewController

- (void)viewDidLoad {
    [self loadTheme];
    [self registerTableViewCells];
    [super viewDidLoad];
}

- (void)loadTheme {
    if (@available(iOS 13, *)) { }
    else {
        self.tableView.backgroundColor = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ?  [ThemeManager sharedCurrentTheme].viewAltBackgroundColor : [ThemeManager sharedCurrentTheme].viewBackgroundColor;
    }
}

- (void)populateTableViewWithID:(int)titleid withEntryDictionary:(nullable NSDictionary *)uentry withType:(int)type {
    _currenttype = type;
    _titleid = titleid;
    NSDictionary *userentry = uentry ? uentry : nil;
    _origentry = userentry;
    int currentservice = [listservice.sharedInstance getCurrentServiceID];
    if (!userentry) {
        userentry = [AtarashiiListCoreData retrieveSingleEntryForTitleID:titleid withService:currentservice withType:type];
    }
    if (currentservice == 2 || currentservice == 3) {
        _entryid = ((NSNumber *)userentry[@"entryid"]).intValue;
    }
    _navitem.title = userentry[@"title"];
    // Set Air/Publish status
    if (_currenttype == 0) {
        NSString *airingstatus = userentry[@"status"];
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
        NSString *publishtatus = userentry[@"status"];
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
    // Generate Cell Array
    _cellEntries = _currenttype == 0 ? [self generateUserEntryAnimeArray:userentry] : [self generateUserEntryMangaArray:userentry];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellEntries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EntryCellInfo *cellEntry = _cellEntries[indexPath.row];
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
    else if (cellEntry.type == cellTypeSwitch) {
        return [self generateTitleSwitchCell:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else if (cellEntry.type == cellTypeNotes) {
        return [self generateNotesCell:cellEntry withTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return [UITableViewCell new];
}

- (UITableViewCell *)generateEntryCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"editdetailcell";
    TitleInfoListEntryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
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
        };
    }
    else if ([cellInfo.cellTitle isEqualToString:@"Start"] || [cellInfo.cellTitle isEqualToString:@"End"]) {
        cell.dateValue = (NSDate *)cellInfo.cellValue;
        NSDateFormatter *df = [NSDateFormatter new];
        df.dateFormat = @"yyyy-MM-dd";
        cell.detailTextLabel.text = [df stringFromDate:cell.dateValue ? cell.dateValue : [NSDate date]];
        cell.dateChanged = ^(NSDate * _Nonnull date, NSString * _Nonnull fieldname) {
            cellInfo.cellValue = date;
        };
        [cell setEnabled:cellInfo.dateExists];
    }
    return cell;
}

- (UITableViewCell *)generateProgressCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"progresscell";
    TitleInfoProgressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
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
    if (!cell && tableView != self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.rawscore = ((NSNumber *)cellInfo.cellValue).intValue;
    cell.scorefield.text = [AniListScoreConvert convertAniListScoreToActualScore:cell.rawscore withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]];
    cell.scoreChanged = ^(int newvalue, NSString * _Nonnull fieldname) {
        cellInfo.cellValue = @(newvalue);
    };
    return cell;
}

- (UITableViewCell *)generateTitleSwitchCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"switchcell";
    TitleInfoSwitchEntryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.cellTitle.text = cellInfo.cellTitle;
    cell.toggleswitch.on = ((NSNumber *)cellInfo.cellValue).boolValue;
    if ([cellInfo.cellTitle isEqualToString:@"Set Start Date"] || [cellInfo.cellTitle isEqualToString:@"Set End Date"]) {
        [cell setEnabled:!cellInfo.dateExists];
        cell.dateToggle = YES;
    }
    cell.switchChanged = ^(bool switchstate, NSString * _Nonnull fieldname, bool dateToggle) {
        if (dateToggle) {
            NSString *datetitle = [cellInfo.cellTitle isEqualToString:@"Set Start Date"] ? @"Start" : @"End";
            TitleInfoListEntryTableViewCell *ecell = [self getDateCell:datetitle];
            [ecell setEnabled:switchstate];
        }
        cellInfo.cellValue = @(switchstate);
    };
    return cell;
}

- (UITableViewCell *)generateNotesCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"notescell";
    TitleInfoNotesEntryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell && tableView != self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    }
    cell.notes.text = cellInfo.cellValue;
    cell.notesChanged = ^(NSString * _Nonnull newvalue, NSString * _Nonnull fieldname) {
        cellInfo.cellValue = newvalue;
    };
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
    id cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[TitleInfoProgressTableViewCell class]]) {
        [(TitleInfoProgressTableViewCell *)cell selectAction];
    }
    else if ([cell isKindOfClass:[TitleInfoListEntryTableViewCell class]]) {
        [(TitleInfoListEntryTableViewCell *)cell selectAction];
    }
    else if ([cell isKindOfClass:[TitleInfoAdvScoreEntryTableViewCell class]]) {
        [(TitleInfoAdvScoreEntryTableViewCell *)cell selectAction];
    }
    else if ([cell isKindOfClass:[TitleInfoNotesEntryTableViewCell class]]) {
        [(TitleInfoNotesEntryTableViewCell *)cell selectAction];
    }
    ((UITableViewCell *)cell).selected = NO;
}

- (TitleInfoListEntryTableViewCell *)getDateCell:(NSString *)fieldName {
    for (id cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[TitleInfoListEntryTableViewCell class]]) {
            TitleInfoListEntryTableViewCell *ecell = (TitleInfoListEntryTableViewCell *)cell;
            if ([ecell.textLabel.text isEqualToString:@"Start"] || [ecell.textLabel.text isEqualToString:@"End"]) {
                return ecell;
            }
        }
    }
    return nil;
}

#pragma mark Generate Cell Info
- (NSArray *)generateUserEntryAnimeArray:(NSDictionary *)entry {
    NSMutableArray *entrycellarray = [NSMutableArray new];
    int currentService = [listservice.sharedInstance getCurrentServiceID];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Episode" withValue:entry[@"watched_episodes"] withMaximumCellValue:((NSNumber *)entry[@"episodes"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Status" withValue:entry[@"watched_status"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:entry[@"score"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Rewatching" withValue:entry[@"rewatching"] withCellType:cellTypeSwitch]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"# Rewatch" withValue:entry[@"rewatch_count"] withCellType:cellTypeProgressEntry]];
    // Notes
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Notes" withValue:entry[@"personal_comments"] != [NSNull null] ? entry[@"personal_comments"] : @"" withCellType:cellTypeNotes]];
    if (currentService == 2 || currentService == 3) {
        [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Private" withValue:entry[@"private"] withCellType:cellTypeSwitch]];
    }
    if (currentService == 2 || currentService == 3) {
        // Dates
        NSDictionary *dates = [self generateDateArray:entry];
        [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Set Start Date" withValue:dates[@"startDateExists"] withCellType:cellTypeSwitch withDateExists:((NSNumber *)dates[@"startDateExists"]).boolValue]];
        [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Start" withValue:dates[@"startDate"] withCellType:cellTypeEntry withDateExists:((NSNumber *)dates[@"startDateExists"]).boolValue]];
        [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Set End Date" withValue:dates[@"endDateExists"] withCellType:cellTypeSwitch withDateExists:((NSNumber *)dates[@"endDateExists"]).boolValue]];
        [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"End" withValue:dates[@"endDate"] withCellType:cellTypeEntry withDateExists:((NSNumber *)dates[@"endDateExists"]).boolValue]];
    }

    return entrycellarray;
}

- (NSArray *)generateUserEntryMangaArray:(NSDictionary *)entry {
    NSMutableArray *entrycellarray = [NSMutableArray new];
    int currentService = [listservice.sharedInstance getCurrentServiceID];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Chapter" withValue:entry[@"chapters_read"] withMaximumCellValue:((NSNumber *)entry[@"chapters"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Volume" withValue:entry[@"volumes_read"] withMaximumCellValue:((NSNumber *)entry[@"volumes"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Status" withValue:entry[@"read_status"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:entry[@"score"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Rereading" withValue:entry[@"rereading"] withCellType:cellTypeSwitch]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"# Reread" withValue:entry[@"reread_count"] withCellType:cellTypeProgressEntry]];
    // Notes
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Notes" withValue:entry[@"personal_comments"] != [NSNull null] ? entry[@"personal_comments"] : @"" withCellType:cellTypeNotes]];
    if (currentService == 2 || currentService == 3) {
        [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Private" withValue:entry[@"private"] withCellType:cellTypeSwitch]];
    }
    // Dates
    if (currentService == 2 || currentService == 3) {
        NSDictionary *dates = [self generateDateArray:entry];
        [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Set Start Date" withValue:dates[@"startDateExists"] withCellType:cellTypeSwitch withDateExists:((NSNumber *)dates[@"startDateExists"]).boolValue]];
        [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Start" withValue:dates[@"startDate"] withCellType:cellTypeEntry withDateExists:((NSNumber *)dates[@"startDateExists"]).boolValue]];
        [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Set End Date" withValue:dates[@"endDateExists"] withCellType:cellTypeSwitch withDateExists:((NSNumber *)dates[@"endDateExists"]).boolValue]];
        [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"End" withValue:dates[@"endDate"] withCellType:cellTypeEntry withDateExists:((NSNumber *)dates[@"endDateExists"]).boolValue]];
    }
    return entrycellarray;
}
#pragma mark Helpers
- (NSDictionary *)generateDateArray:(NSDictionary *)entry {
    NSDateFormatter *dateformat = [NSDateFormatter new];
    NSMutableDictionary *datedict = [NSMutableDictionary new];
    dateformat.dateFormat = @"yyyy-MM-dd";
    if (_currenttype == MALAnime) {
        if (entry[@"watching_start"] && entry[@"watching_start"] != [NSNull null] && ((NSString *)entry[@"watching_start"]).length > 0) {
            datedict[@"startDate"] = [dateformat dateFromString:[(NSString *)entry[@"watching_start"] substringToIndex:10]];
            datedict[@"startDateExists"] = @(YES);
        }
        else {
            datedict[@"startDate"] = [NSDate date];
            datedict[@"startDateExists"] = @(NO);
        }
        if (entry[@"watching_end"]  && entry[@"watching_end"] != [NSNull null] && ((NSString *)entry[@"watching_end"]).length > 0) {
            datedict[@"endDate"] = [dateformat dateFromString:[(NSString *)entry[@"watching_end"] substringToIndex:10]];
            datedict[@"endDateExists"] = @(YES);
        }
        else {
            datedict[@"endDate"] = [NSDate date];
            datedict[@"endDateExists"] = @(NO);
        }
    }
    else {
        if (entry[@"reading_start"] && entry[@"reading_start"] != [NSNull null] && ((NSString *)entry[@"reading_start"]).length > 0) {
            datedict[@"startDate"] = [dateformat dateFromString:[(NSString *)entry[@"reading_start"] substringToIndex:10]];
            datedict[@"startDateExists"] = @(YES);
        }
        else {
            datedict[@"startDate"] = [NSDate date];
            datedict[@"startDateExists"] = @(NO);
        }
        if (entry[@"reading_end"]  && entry[@"reading_end"] != [NSNull null] && ((NSString *)entry[@"reading_end"]).length > 0) {
            datedict[@"endDate"] = [dateformat dateFromString:[(NSString *)entry[@"reading_end"] substringToIndex:10]];
            datedict[@"endDateExists"] = @(YES);
        }
        else {
            datedict[@"endDate"] = [NSDate date];
            datedict[@"endDateExists"] = @(NO);
        }
    }
    return datedict.copy;
}

- (bool)validateCells {
    switch (_currenttype) {
        case 0: {
            EntryCellInfo *episodecell;
            EntryCellInfo *statuscell;
            for (EntryCellInfo *cellInfo in _cellEntries) {
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
            for (EntryCellInfo *cellInfo in _cellEntries) {
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
    for (EntryCellInfo *cellInfo in _cellEntries) {
        if (cellInfo.type == cellTypeAction) {
            continue;
        }
        else {
            info[cellInfo.cellTitle.lowercaseString] = cellInfo.cellValue;
        }
    }
    return info;
}

- (NSDictionary *)generateExtraFieldsWithType:(int)type withUpdateDictionary:(NSDictionary *)udict{
    NSMutableDictionary *extrafields = [NSMutableDictionary new];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"yyyy-MM-dd";
    //NSString *tags = @"";
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1: {
            /*
             if (((NSArray *)_tagsfield.objectValue).count > 0){
             tags = [(NSArray *)_tagsfield.objectValue componentsJoinedByString:@","];
             extrafields[@"tags"] = tags;
             }
             */
            /*if (((NSNumber *)udict[@"set start date"]).boolValue) {
                extrafields[@"start"] = [df stringFromDate:(NSDate *)udict[@"start"]];
            }
            if (((NSNumber *)udict[@"set end date"]).boolValue) {
                extrafields[@"end"] = [df stringFromDate:(NSDate *)udict[@"end"]];
            }*/
            if (type == 0) {
                extrafields[@"is_rewatching"] = udict[@"rewatching"];
                extrafields[@"num_times_rewatched"] = udict[@"# rewatch"];
            }
            else {
                extrafields[@"is_rereading"] = udict[@"rereading"];
                extrafields[@"num_times_reread"] = udict[@"# reread"];
            }
            if (((NSString *)udict[@"notes"]).length > 0) {
                extrafields[@"comments"] = udict[@"notes"];
            }
            else {
                extrafields[@"comments"] = @"";
            }
            break;
        }
        case 2: {
            if (((NSString *)udict[@"notes"]).length > 0) {
                extrafields[@"notes"] = udict[@"notes"];
            }
            else {
                extrafields[@"notes"] = [NSNull null];
            }
            if (((NSNumber *)udict[@"set start date"]).boolValue) {
                extrafields[@"startedAt"] = [df stringFromDate:(NSDate *)udict[@"start"]];
            }
            if (((NSNumber *)udict[@"set end date"]).boolValue) {
                extrafields[@"finishedAt"] = [df stringFromDate:(NSDate *)udict[@"end"]];
            }
            extrafields[@"private"] = @(((NSNumber *)udict[@"private"]).boolValue);
            extrafields[@"reconsuming"] = type == 0 ? @(((NSNumber *)udict[@"rewatching"]).boolValue) : @(((NSNumber *)udict[@"rereading"]).boolValue);
            extrafields[@"reconsumeCount"] = type == 0 ? udict[@"# rewatch"] : udict[@"# reread"];
            break;
        }
        case 3:{
            if (((NSString *)udict[@"notes"]).length > 0) {
                extrafields[@"notes"] = udict[@"notes"];
            }
            else {
                extrafields[@"notes"] = [NSNull null];
            }
            if (((NSNumber *)udict[@"set start date"]).boolValue) {
                NSString *tmpstr = [df stringFromDate:(NSDate *)udict[@"start"]];
                extrafields[@"startedAt"] = @{@"year" : [tmpstr substringWithRange:NSMakeRange(0, 4)], @"month" : [tmpstr substringWithRange:NSMakeRange(5, 2)], @"day" : [tmpstr substringWithRange:NSMakeRange(8, 2)]};
            }
            else {
                extrafields[@"startedAt"] = @{@"year" : @(0), @"month" : @(0), @"day" : @(0)};
            }
            if (((NSNumber *)udict[@"set end date"]).boolValue) {
                NSString *tmpstr = [df stringFromDate:(NSDate *)udict[@"end"]];
                extrafields[@"completedAt"] = @{@"year" : [tmpstr substringWithRange:NSMakeRange(0, 4)], @"month" : [tmpstr substringWithRange:NSMakeRange(5, 2)], @"day" : [tmpstr substringWithRange:NSMakeRange(8, 2)]};
            }
            else {
                extrafields[@"completedAt"] = @{@"year" : @(0), @"month" : @(0), @"day" : @(0)};
            }
            extrafields[@"private"] = @(((NSNumber *)udict[@"private"]).boolValue);
            extrafields[@"reconsuming"] = type == 0 ? @(((NSNumber *)udict[@"rewatching"]).boolValue) : @(((NSNumber *)udict[@"rereading"]).boolValue);
            extrafields[@"reconsumeCount"] = type == 0 ? udict[@"# rewatch"] : udict[@"# reread"];
            break;
        }
        default:
            break;
    }
    return extrafields;
}

- (NSDictionary *)generateExtraFieldsUpdateEntryWithType:(int)type withUpdateDictionary:(NSDictionary *)udict {
    NSMutableDictionary *extrafields = [NSMutableDictionary new];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"yyyy-MM-dd";
    //NSString *tags = @"";
    int currentService = [listservice.sharedInstance getCurrentServiceID];
    /*
     if (currentService == 1) {
     if (((NSArray *)_tagsfield.objectValue).count > 0){
     tags = [(NSArray *)_tagsfield.objectValue componentsJoinedByString:@","];
     extrafields[@"tags"] = tags;
     }
     }
     */
    if (((NSNumber *)udict[@"set start date"]).boolValue) {
        if (_currenttype == 0) {
            extrafields[@"watching_start"] = [df stringFromDate:(NSDate *)udict[@"start"]];
        }
        else {
            extrafields[@"reading_start"] = [df stringFromDate:(NSDate *)udict[@"start"]];
        }
    }
    if (((NSNumber *)udict[@"set end date"]).boolValue) {
        if (_currenttype == 0) {
            extrafields[@"watching_end"] = [df stringFromDate:(NSDate *)udict[@"end"]];
        }
        else {
            extrafields[@"reading_end"] = [df stringFromDate:(NSDate *)udict[@"end"]];
        }
    }
    if (type == 0) {
        extrafields[@"rewatching"] = @(((NSNumber *)udict[@"rewatching"]).boolValue);
        extrafields[@"rewatch_count"] = udict[@"# rewatch"];
    }
    else {
        extrafields[@"rereading"] = @(((NSNumber *)udict[@"rereading"]).boolValue);
        extrafields[@"reread_count"] = udict[@"# reread"];
    }
    if (currentService == 2 || currentService == 3) {
        if (((NSString *)udict[@"notes"]).length > 0) {
            extrafields[@"personal_comments"] = udict[@"notes"];
        }
        else {
            extrafields[@"personal_comments"] = [NSNull null];
        }
        extrafields[@"private"] = @(((NSNumber *)udict[@"private"]).boolValue);
    }
    return extrafields;
}

#pragma mark Cancel/Save Action

- (IBAction)saveentry:(id)sender {
    [self.view endEditing:YES];
    if ([self validateCells]) {
        if (_currenttype == 0) {
            [self updateAnime];
        }
        else {
            [self updateManga];
        }
    }
}

- (void)updateAnime {
    NSDictionary *entry = [self generateUpdateDictionary];
    NSDictionary * extraparameters = [self generateExtraFieldsWithType:_currenttype withUpdateDictionary:entry];
    int selectededitid = 0;
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1: {
            selectededitid = self.titleid;
            break;
        }
        case 2:
        case 3: {
            selectededitid = self.entryid;
            break;
        }
        default:
            break;
    }
    __weak AdvEditTableViewController *weakSelf = self;
    _savebtn.enabled = NO;
    _cancelbtn.enabled = NO;
    [self showloadingview:YES];
    [listservice.sharedInstance updateAnimeTitleOnList:selectededitid withEpisode:((NSNumber *)entry[@"episode"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue withExtraFields:extraparameters completion:^(id responseobject) {
        NSMutableDictionary *updatedfields = [[NSMutableDictionary alloc] initWithDictionary:@{@"watched_episodes" : entry[@"episode"], @"watched_status" : entry[@"status"], @"score" : entry[@"score"], @"last_updated" : [Utility getLastUpdatedDateWithResponseObject:responseobject withService:[listservice.sharedInstance getCurrentServiceID]]}];
        [updatedfields addEntriesFromDictionary:[self generateExtraFieldsUpdateEntryWithType:0 withUpdateDictionary:entry]];
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:0 withId:selectededitid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:0 withId:selectededitid withIdType:1];
                break;
        }
        weakSelf.entryUpdated(weakSelf.currenttype);
        [HistoryManager.sharedInstance insertHistoryRecord:((NSNumber *)self.origentry[@"id"]).intValue withTitle:self.origentry[@"title"] withHistoryActionType:HistoryActionTypeUpdateTitle withSegment:((NSNumber *)entry[@"episode"]).intValue withMediaType:0 withService:listservice.sharedInstance.getCurrentServiceID];
        // Reload List
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.savebtn.enabled = YES;
            weakSelf.cancelbtn.enabled = YES;
            [self showloadingview:NO];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        });
    }
                                  error:^(NSError * error) {
                                      NSLog(@"%@", error.localizedDescription);
                                      NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                                      NSLog(@"%@",errResponse);
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        [weakSelf showError:error];
                                          weakSelf.savebtn.enabled = YES;
                                          weakSelf.cancelbtn.enabled = YES;
                                          [self showloadingview:NO];
                                      });
                                  }];
}

- (void)updateManga {
    NSDictionary *entry = [self generateUpdateDictionary];
    NSDictionary * extraparameters = [self generateExtraFieldsWithType:_currenttype withUpdateDictionary:entry];
    int selectededitid = 0;
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 1: {
            selectededitid = self.titleid;
            break;
        }
        case 2:
        case 3: {
            selectededitid = self.entryid;
            break;
        }
        default:
            break;
    }
    __weak AdvEditTableViewController *weakSelf = self;
    _savebtn.enabled = NO;
    _cancelbtn.enabled = NO;
    [self showloadingview:YES];
    [listservice.sharedInstance updateMangaTitleOnList:selectededitid withChapter:((NSNumber *)entry[@"chapter"]).intValue withVolume:((NSNumber *)entry[@"volume"]).intValue withStatus:entry[@"status"] withScore:((NSNumber *)entry[@"score"]).intValue withExtraFields:extraparameters completion:^(id responseobject) {
        NSMutableDictionary *updatedfields = [[NSMutableDictionary alloc] initWithDictionary:@{@"chapters_read" : entry[@"chapter"], @"volumes_read" : entry[@"volume"], @"read_status" : entry[@"status"], @"score" : entry[@"score"], @"last_updated" : [Utility getLastUpdatedDateWithResponseObject:responseobject withService:[listservice.sharedInstance getCurrentServiceID]]}];
        [updatedfields addEntriesFromDictionary:[self generateExtraFieldsUpdateEntryWithType:1 withUpdateDictionary:entry]];
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:1 withId:selectededitid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:1 withId:selectededitid withIdType:1];
                break;
        }
        weakSelf.entryUpdated(weakSelf.currenttype);
        [HistoryManager.sharedInstance insertHistoryRecord:
         ((NSNumber *)self.origentry[@"id"]).intValue withTitle:self.origentry[@"title"] withHistoryActionType:HistoryActionTypeUpdateTitle withSegment:((NSNumber *)entry[@"chapter"]).intValue withMediaType:1 withService:listservice.sharedInstance.getCurrentServiceID];
        // Reload List
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.savebtn.enabled = YES;
            weakSelf.cancelbtn.enabled = YES;
            [self showloadingview:NO];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        });
    }error:^(NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@", error.localizedDescription);
            [weakSelf showError:error];
            weakSelf.savebtn.enabled = YES;
            weakSelf.cancelbtn.enabled = YES;
            [self showloadingview:NO];
        });
    }];
}

- (IBAction)canceledit:(id)sender {
    [self.view endEditing:YES];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark HUD
- (void)showloadingview:(bool)show {
    if (show) {
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = @"Saving...";
        if (@available(iOS 13, *)) { }
        else {
            _hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
            _hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
        }
    }
    else if (!show) {
        [_hud hideAnimated:YES];
    }
}

- (void)showError:(NSError *)error {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Operation failed" message:[NSString stringWithFormat:@"%@", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertcontroller addAction:okaction];
    [self.navigationController presentViewController:alertcontroller animated:YES completion:nil];
}

#pragma mark tableview cell registration
- (void)registerTableViewCells {
    NSDictionary *cells = @{ @"TitleInfoListEntryTableViewCell" : @"editdetailcell", @"TitleInfoProgressTableViewCell" : @"progresscell", @"TitleInfoAdvScoreEntryTableViewCell" : @"advscorecell", @"TitleInfoSwitchEntryTableViewCell" : @"switchcell", @"TitleInfoNotesEntryTableViewCell" : @"notescell" };
    for (NSString *nibName in cells.allKeys) {
        [self.tableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:cells[nibName]];
    }
}
@end
