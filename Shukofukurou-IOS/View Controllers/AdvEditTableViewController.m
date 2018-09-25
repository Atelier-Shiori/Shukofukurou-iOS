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

@interface AdvEditTableViewController ()
@property (strong) NSArray *cellEntries;
@property int currenttype;
@property int entryid;
@property bool selectedaired;
@property bool selectedaircompleted;
@property bool selectedfinished;
@property bool selectedpublished;
@property bool selectedreconsuming;
@property (weak, nonatomic) IBOutlet UINavigationItem *navitem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *savebtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelbtn;
@end

@implementation AdvEditTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)populateTableViewWithID:(int)titleid withEntryDictionary:(nullable NSDictionary *)uentry withType:(int)type {
    _currenttype = type;
    NSDictionary *userentry = uentry ? uentry : nil;
    int currentservice = [listservice getCurrentServiceID];
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
        int currentservice = [listservice getCurrentServiceID];
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
    else if ([cellInfo.cellTitle isEqualToString:@"Start"] || [cellInfo.cellTitle isEqualToString:@"End"]) {
        cell.dateValue = (NSDate *)cellInfo.cellValue;
        NSDateFormatter *df = [NSDateFormatter new];
        df.dateFormat = @"yyyy-MM-dd";
        cell.detailTextLabel.text = [df stringFromDate:cell.dateValue];
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

/*
 - (UITableViewCell *)generateTitleInfoCell:(EntryCellInfo *)cellInfo withTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 NSString *reusableIdentifier = @"titleinfocell";
 TitleInfoBasicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
 if (!cell && tableView != self.tableView) {
 cell = [self.tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
 }
 cell.textLabel.text = cellInfo.cellTitle;
 cell.detailTextLabel.text = cellInfo.cellValue;
 return cell;
 }*/

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
    else if ([cell isKindOfClass:[TitleInfoSwitchEntryTableViewCell class]]) {
        [(TitleInfoSwitchEntryTableViewCell *)cell selectAction];
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
    int currentService = [listservice getCurrentServiceID];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Episode" withValue:entry[@"watched_episodes"] withMaximumCellValue:((NSNumber *)entry[@"episodes"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Status" withValue:entry[@"watched_status"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:entry[@"score"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Rewatching" withValue:entry[@"rewatching"] withCellType:cellTypeSwitch]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"# Rewatch" withValue:entry[@"rewatch_count"] withCellType:cellTypeProgressEntry]];
    if (currentService == 2 || currentService == 3) {
        // Notes
        [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Notes" withValue:entry[@"personal_comments"] != [NSNull null] ? entry[@"personal_comments"] : @"" withCellType:cellTypeNotes]];
        [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Private" withValue:entry[@"private"] withCellType:cellTypeSwitch]];
    }
    // Dates
    NSDictionary *dates = [self generateDateArray:entry];
    [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Set Start Date" withValue:dates[@"startDateExists"] withCellType:cellTypeSwitch withDateExists:((NSNumber *)dates[@"startDateExists"]).boolValue]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Start" withValue:dates[@"startDate"] withCellType:cellTypeEntry withDateExists:((NSNumber *)dates[@"startDateExists"]).boolValue]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Set End Date" withValue:dates[@"endDateExists"] withCellType:cellTypeSwitch withDateExists:((NSNumber *)dates[@"endDateExists"]).boolValue]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"End" withValue:dates[@"endDate"] withCellType:cellTypeEntry withDateExists:((NSNumber *)dates[@"endDateExists"]).boolValue]];

    return entrycellarray;
}

- (NSArray *)generateUserEntryMangaArray:(NSDictionary *)entry {
    NSMutableArray *entrycellarray = [NSMutableArray new];
    int currentService = [listservice getCurrentServiceID];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Chapter" withValue:entry[@"chapters_read"] withMaximumCellValue:((NSNumber *)entry[@"chapters"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Volume" withValue:entry[@"volumes_read"] withMaximumCellValue:((NSNumber *)entry[@"volumes"]).intValue withCellType:cellTypeProgressEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Status" withValue:entry[@"read_status"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Score" withValue:entry[@"score"] withCellType:cellTypeEntry]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Rereading" withValue:entry[@"rereading"] withCellType:cellTypeSwitch]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"# Reread" withValue:entry[@"reread_count"] withCellType:cellTypeProgressEntry]];
    if (currentService == 2 || currentService == 3) {
        // Notes
        [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Notes" withValue:entry[@"personal_comments"] != [NSNull null] ? entry[@"personal_comments"] : @"" withCellType:cellTypeNotes]];
        [entrycellarray addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Private" withValue:entry[@"private"] withCellType:cellTypeSwitch]];
    }
    // Dates
    NSDictionary *dates = [self generateDateArray:entry];
    [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Set Start Date" withValue:dates[@"startDateExists"] withCellType:cellTypeSwitch withDateExists:((NSNumber *)dates[@"startDateExists"]).boolValue]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Start" withValue:dates[@"startDate"] withCellType:cellTypeEntry withDateExists:((NSNumber *)dates[@"startDateExists"]).boolValue]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"Set End Date" withValue:dates[@"endDateExists"] withCellType:cellTypeSwitch withDateExists:((NSNumber *)dates[@"endDateExists"]).boolValue]];
    [entrycellarray addObject:[[EntryCellInfo alloc] initDateCellWithTitle:@"End" withValue:dates[@"endDate"] withCellType:cellTypeEntry withDateExists:((NSNumber *)dates[@"endDateExists"]).boolValue]];
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
#pragma mark Cancel/Save Action

- (IBAction)saveentry:(id)sender {
}

- (IBAction)canceledit:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
