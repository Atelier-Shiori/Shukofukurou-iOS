//
//  SearchAdvSettings.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 5/20/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "SearchAdvSettings.h"
#import "listservice.h"
#import "AdvSearchSelectionCell.h"

@interface SearchAdvSettings()
@property (strong) NSMutableDictionary *tmpsearchoptions;
@property (strong) NSArray *sortedoptions;
@end

@implementation SearchAdvSettings

#pragma mark constants
+ (NSArray *)kitsumangaformats {
    static NSArray *kitsumangaformats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kitsumangaformats = @[@"No Selection", @"Doujin", @"Manga", @"Manhua", @"Novel", @"Oel", @"Oneshot"];;
    });
    return kitsumangaformats;
}

+ (NSArray *)anilistmangaformats {
    static NSArray *anilistmangaformats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        anilistmangaformats = @[@"No Selection", @"Manga", @"Novel", @"One Shot"];;
    });
    return anilistmangaformats;
}

+ (NSArray *)animeformats {
    static NSArray *animeformats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        animeformats = @[@"No Selection", @"TV", @"TV Short", @"ONA", @"OVA", @"Movie", @"Music", @"Special"];;
    });
    return animeformats;
}

+ (NSArray *)kitsustatus {
    static NSArray *kitsustatus;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kitsustatus = @[@"No Selection", @"Current", @"Finished", @"TBA", @"Unreleased", @"Upcoming"];;
    });
    return kitsustatus;
}

+ (NSArray *)aniliststatus {
    static NSArray *aniliststatus;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        aniliststatus = @[@"No Selection", @"Finished", @"Releasing", @"Not Yet Released", @"Cancelled"];;
    });
    return aniliststatus;
}

+ (NSArray *)season {
    static NSArray *aniliststatus;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        aniliststatus = @[@"No Selection", @"Winter", @"Spring", @"Summer", @"Fall"];;
    });
    return aniliststatus;
}


+ (NSArray *)years {
    static NSArray *years;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *tmparray = [NSMutableArray new];
        [tmparray addObject:@"No Selection"];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
        int currentyear = 1990;
        while (currentyear <= components.year) {
            [tmparray addObject:@(currentyear).stringValue];
            currentyear++;
        }
        years = [tmparray copy];
    });
    return years;
}

#pragma mark methods

- (void)populateSearchOptionsForType:(int)type {
    if (_currentadvsearch != type || [listservice.sharedInstance getCurrentServiceID] != _currentlistservice) {
        _currentlistservice = [listservice.sharedInstance getCurrentServiceID];
        _currentadvsearch = type;
        [self generateSearchOptionsForType:type];
    }
}

- (void)generateSearchOptionsForType:(int)type {
    _advsearchoptions = @{};
    switch (type) {
        case 0: {
            _tmpsearchoptions = [[NSMutableDictionary alloc] initWithDictionary:@{@"From" : @"No Selection", @"To" : @"No Selection", @"Season" : @"No Selection", @"Status" : @"No Selection", @"Format" : @"No Selection" }];
            _sortedoptions = @[@"From", @"To", @"Season", @"Status", @"Format"];
            break;
        }
        case 1: {
            _tmpsearchoptions = [[NSMutableDictionary alloc] initWithDictionary:@{@"Status" : @"No Selection", @"Format" : @"No Selection"}];
            _sortedoptions = @[@"Status", @"Format"];
            break;
        }
        default: {
            return;
        }
    }
    [self.tableView reloadData];
}

- (void)generateadvsearchdictionary {
    NSMutableDictionary *tmpdict = [NSMutableDictionary new];
    if (_currentadvsearch == 0) {
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 2:
                //_animeadvsearchoptions = @{@"season" : self.animeseasonpopover.title, @"subtype" : self.animeformat.title, @"status" : _kitsustatus.title, @"seasonYear" : }
                if (![(NSString *)_tmpsearchoptions[@"Season"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"season"] = ((NSString *)_tmpsearchoptions[@"Season"]).lowercaseString;
                }
                if (![(NSString *)_tmpsearchoptions[@"Format"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"subtype"] = (NSString *)_tmpsearchoptions[@"Format"];
                }
                if (![(NSString *)_tmpsearchoptions[@"Status"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"status"] = ((NSString *)_tmpsearchoptions[@"Status"]).lowercaseString;
                }
                if (![(NSString *)_tmpsearchoptions[@"From"] isEqualToString:@"No Selection"]) {
                    int fromyear = ((NSString *)_tmpsearchoptions[@"From"]).intValue;
                    int toyear;
                    if ([(NSString *)_tmpsearchoptions[@"To"] isEqualToString:@"No Selection"]) {
                        toyear = [self currentYear];
                    }
                    else {
                        toyear = ((NSString *)_tmpsearchoptions[@"To"]).intValue;
                    }
                    if (fromyear <= toyear) {
                        NSMutableArray *yeararray = [NSMutableArray new];
                        for (int i = fromyear; i <= toyear; i++) {
                            [yeararray addObject:@(i).stringValue];
                        }
                        tmpdict[@"seasonYear"] = [yeararray componentsJoinedByString:@","];
                    }
                }
                _advsearchoptions = tmpdict;
                break;
            case 3:
                if (![(NSString *)_tmpsearchoptions[@"Season"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"season"] = ((NSString *)_tmpsearchoptions[@"Season"]).uppercaseString;
                }
                if (![(NSString *)_tmpsearchoptions[@"Format"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"format"] = [((NSString *)_tmpsearchoptions[@"Format"]).uppercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                }
                if (![(NSString *)_tmpsearchoptions[@"Status"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"status"] = [((NSString *)_tmpsearchoptions[@"Status"]).uppercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                }
                if (![(NSString *)_tmpsearchoptions[@"From"] isEqualToString:@"No Selection"]) {
                    int fromyear = ((NSString *)_tmpsearchoptions[@"From"]).intValue;
                    int toyear;
                    if ([(NSString *)_tmpsearchoptions[@"To"] isEqualToString:@"No Selection"]) {
                        toyear = [self currentYear];
                    }
                    else {
                        toyear = ((NSString *)_tmpsearchoptions[@"To"]).intValue;
                    }
                    if (fromyear <= toyear) {
                        int startdate = [NSString stringWithFormat:@"%i0101", fromyear].intValue;
                        int enddate = [NSString stringWithFormat:@"%i0101", toyear].intValue;
                        tmpdict[@"startDate_greater"] = @(startdate);
                        tmpdict[@"endDate_lesser"] = @(enddate);
                    }
                }
                _advsearchoptions = tmpdict;
                break;
            default:
                break;
        }
    }
    else {
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 2:
                //_animeadvsearchoptions = @{@"season" : self.animeseasonpopover.title, @"subtype" : self.animeformat.title, @"status" : _kitsustatus.title, @"seasonYear" : }
                if (![(NSString *)_tmpsearchoptions[@"Format"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"subtype"] = ((NSString *)_tmpsearchoptions[@"Format"]).lowercaseString;
                }
                if (![(NSString *)_tmpsearchoptions[@"Status"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"status"] = ((NSString *)_tmpsearchoptions[@"Status"]).lowercaseString;
                }
                _advsearchoptions = tmpdict;
                break;
            case 3:
                if (![(NSString *)_tmpsearchoptions[@"Format"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"format"] = [((NSString *)_tmpsearchoptions[@"Format"]).uppercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                }
                if (![(NSString *)_tmpsearchoptions[@"Status"] isEqualToString:@"No Selection"]) {
                    tmpdict[@"status"] = [((NSString *)_tmpsearchoptions[@"Status"]).uppercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                }
                _advsearchoptions = tmpdict;
                break;
            default:
                break;
        }
    }
}

- (int)currentYear {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
    return (int)components.year;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _sortedoptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AdvSearchSelectionCell *cell;
    NSString *key = _sortedoptions[indexPath.row];
    cell = [[AdvSearchSelectionCell alloc] generateCell:[self getSelectionItems:key] withParentDictionary:_tmpsearchoptions withCellTitle:key withValueKey:key];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AdvSearchSelectionCell *cell = (AdvSearchSelectionCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell showPicker];
    }
}

- (NSArray *)getSelectionItems:(NSString *)key {
    switch (_currentadvsearch) {
        case 0: {
            if ([key isEqualToString:@"To"] || [key isEqualToString:@"From"]) {
                return [SearchAdvSettings years];
            }
            else if ([key isEqualToString:@"Season"]) {
                return [SearchAdvSettings season];
            }
            else if ([key isEqualToString:@"Status"]) {
                return _currentlistservice == 2 ? [SearchAdvSettings kitsustatus] : _currentlistservice == 3 ? [SearchAdvSettings aniliststatus] : @[];
            }
            else if ([key isEqualToString:@"Format"]) {
                return [SearchAdvSettings animeformats];
            }
            break;
        }
        case 1: {
            if ([key isEqualToString:@"Status"]) {
                return _currentlistservice == 2 ? [SearchAdvSettings kitsustatus] : _currentlistservice == 3 ? [SearchAdvSettings aniliststatus] : @[];
            }
            else if ([key isEqualToString:@"Format"]) {
                return _currentlistservice == 2 ? [SearchAdvSettings kitsumangaformats] : _currentlistservice == 3 ? [SearchAdvSettings anilistmangaformats] : @[];
            }
            break;
        }
    }
    return @[];
}

- (IBAction)close:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self generateadvsearchdictionary];
    self.completionHandler(self.advsearchoptions);
}

- (IBAction)reset:(id)sender {
    [self generateSearchOptionsForType:_currentadvsearch];
}

@end
