//
//  ListSelectorViewController.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/11/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ListSelectorViewController.h"
#import "listservice.h"

@interface ListSelectorViewController ()
@property int listtype;
@property (strong) NSMutableDictionary *lists;
@property (strong) NSArray *listsectionTitles;
@end

@implementation ListSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)generateLists:(NSArray *)list withListType:(int)listtype {
    if (!_lists) {
        _lists = [NSMutableDictionary new];
    }
    _listtype = listtype;
    [_lists removeAllObjects];
    _lists[@"Normal Lists"] = [self generateNormalListCounts:list];
    if ([listservice getCurrentServiceID] == 3) {
        _lists[@"Custom Lists"] = [self generateCustomListsCount:list];
    }
    _listsectionTitles = _lists.allKeys;
}

- (NSArray *)generateNormalListCounts:(NSArray *)list {
    NSArray *filtered;
    if (_listtype == 0) {
        NSNumber *watching;
        NSNumber *completed;
        NSNumber *onhold;
        NSNumber *dropped;
        NSNumber *plantowatch;
        for (int i = 0; i < 5; i++) {
            switch(i) {
                case 0:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"watched_status ==[cd] %@", @"watching"]];
                    watching = @(filtered.count);
                    break;
                case 1:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"watched_status ==[cd] %@", @"completed"]];
                    completed = @(filtered.count);
                    break;
                case 2:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"watched_status ==[cd] %@", @"on-hold"]];
                    onhold = @(filtered.count);
                    break;
                case 3:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"watched_status ==[cd] %@", @"dropped"]];
                    dropped = @(filtered.count);
                    break;
                case 4:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"watched_status ==[cd] %@", @"plan to watch"]];
                    plantowatch = @(filtered.count);
                    break;
                default:
                    break;
            }
        }
        return @[@{@"name" : @"watching", @"count" : watching}, @{@"name" : @"completed", @"count" : completed}, @{@"name" : @"on-hold", @"count" : onhold}, @{@"name" : @"dropped", @"count" : dropped}, @{@"name" : @"plan to watch", @"count" : plantowatch}];
    }
    else {
        NSNumber *reading;
        NSNumber *completed;
        NSNumber *onhold;
        NSNumber *dropped;
        NSNumber *plantoread;
        for (int i = 0; i < 5; i++) {
            switch(i) {
                case 0:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"read_status ==[cd] %@", @"reading"]];
                    reading = @(filtered.count);
                    break;
                case 1:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"read_status ==[cd] %@", @"completed"]];
                    completed = @(filtered.count);
                    break;
                case 2:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"read_status ==[cd] %@", @"on-hold"]];
                    onhold = @(filtered.count);
                    break;
                case 3:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"read_status ==[cd] %@", @"dropped"]];
                    dropped = @(filtered.count);
                    break;
                case 4:
                    filtered = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"read_status ==[cd] %@", @"plan to read"]];
                    plantoread = @(filtered.count);
                    break;
                default:
                    break;
            }
        }
        return @[@{@"name" : @"reading", @"count" : reading}, @{@"name" : @"completed", @"count" : completed}, @{@"name" : @"on-hold", @"count" : onhold}, @{@"name" : @"dropped", @"count" : dropped}, @{@"name" : @"plan to read", @"count" : plantoread}];
    }
}

- (NSArray *)generateCustomListsCount:(NSArray *)array {
    if (array.count > 0) {
        NSDictionary *data = array[0];
        NSString *customliststr = data[@"custom_lists"] != [NSNull null] ? [[(NSString *)data[@"custom_lists"] stringByReplacingOccurrencesOfString:@"[true]" withString:@""] stringByReplacingOccurrencesOfString:@"[false]" withString:@""] : @"";
        NSMutableArray *finalcustomlist = [NSMutableArray new];
        if (customliststr.length > 0) {
            NSArray *lists = [customliststr componentsSeparatedByString:@"||"];
            for (NSString *listname in lists) {
                [finalcustomlist addObject:@{@"name" : listname.copy, @"count" : @([array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"custom_lists CONTAINS[c] %@", [NSString stringWithFormat:@"%@[true]",listname]]].count)}];
            }
        }
        if (_listtype == 0) {
            return finalcustomlist.copy;
        }
        else {
            return finalcustomlist.copy;
        }
    }
    return @[];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _listsectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)_lists[_listsectionTitles[section]]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _listsectionTitles[section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListLabelCell"];
    NSString *listType = _listsectionTitles[indexPath.section];
    NSDictionary *list = _lists[listType][indexPath.row];
    NSString *celllabel = [NSString stringWithFormat:@"%@ (%@)", [listType isEqualToString:@"Normal Lists"] ? ((NSString *)list[@"name"]).capitalizedString : list[@"name"], list[@"count"]];
    cell.textLabel.text = celllabel;
    if ([(NSString *)list[@"name"] isEqualToString:_selectedlist]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else  {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *listtype = _listsectionTitles[indexPath.section];
    NSDictionary *listentry = _lists[listtype][indexPath.row];
    if (![(NSString *)listentry[@"name"] isEqualToString:_selectedlist]) {
        self.listChanged(listentry[@"name"], listtype);
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)closelistselector:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
