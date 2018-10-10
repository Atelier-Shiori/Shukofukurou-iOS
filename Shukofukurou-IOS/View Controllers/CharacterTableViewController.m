//
//  CharacterTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/2/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "CharacterTableViewController.h"
#import "CharacterDetailViewController.h"
#import "listservice.h"
#import "PersonTableViewCell.h"

@interface CharacterTableViewController ()
@property int titleid;
@property (strong) NSDictionary *items;
@property (strong) NSArray *sections;
@end

@implementation CharacterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)retrievePersonList:(int)titleid {
    self.navigationItem.hidesBackButton = YES;
    [listservice retrieveStaff:titleid completion:^(id responseObject) {
        [self generateStaffList:responseObject];
        self.navigationItem.hidesBackButton = NO;
    } error:^(NSError *error) {
        NSLog(@"%@",error);
        [self.navigationController popViewControllerAnimated:YES];
        self.navigationItem.hidesBackButton = NO;
    }];
}

- (void)generateStaffList:(NSDictionary *)data {
    NSMutableDictionary *finaldict = [[NSMutableDictionary alloc] initWithDictionary:data];
    NSMutableArray *voiceactors = [NSMutableArray new];
    NSSortDescriptor *rolesort = [NSSortDescriptor sortDescriptorWithKey:@"role" ascending:YES];
    NSSortDescriptor *namesort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    for (NSDictionary *character in (NSArray *)finaldict[@"Characters"]) {
        if (character[@"actors"] && [character[@"actors"] isKindOfClass:[NSArray class]]) {
            for (NSDictionary *entry in (NSArray *)character[@"actors"]) {
                if ([voiceactors filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name ==[c] %@", entry[@"name"]]].count == 0) {
                        [voiceactors addObject:entry];
                }
            }
        }
    }
    finaldict[@"Characters"] = [finaldict[@"Characters"] sortedArrayUsingDescriptors:@[rolesort,namesort]];
    finaldict[@"Voice Actors"] = [voiceactors sortedArrayUsingDescriptors:@[namesort]].copy;
    finaldict[@"Staff"] = [finaldict[@"Staff"] sortedArrayUsingDescriptors:@[namesort]];
    _items = finaldict.copy;
    _sections = @[@"Characters", @"Voice Actors", @"Staff"];
    [self.tableView reloadData];
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)_items[_sections[section]]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sections[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellType = _sections[indexPath.section];
    NSDictionary *entry = _items[cellType][indexPath.row];
    NSString *reuseIdentifier = [cellType isEqualToString:@"Characters"]  || [cellType isEqualToString:@"Voice Actors"] ? @"charactercell" : @"personcell";
    // Configure the cell...
    if ([cellType isEqualToString:@"Characters"] || [cellType isEqualToString:@"Voice Actors"]) {
        PersonSubtitleTableViewCell *subtitlecell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        subtitlecell.titlelabel.text = entry[@"name"];
        if ([cellType isEqualToString:@"Characters"]) {
            subtitlecell.subtitlelabel.text = entry[@"role"];
        }
        else if ([cellType isEqualToString:@"Voice Actors"]) {
           subtitlecell.subtitlelabel.text = entry[@"language"];
        }
        [subtitlecell loadimage:entry[@"image"]];
        return subtitlecell;
    }
    else {
        PersonTableViewCell *personcell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        personcell.titlelabel.text = entry[@"name"];
        [personcell loadimage:entry[@"image"]];
        return personcell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellType = _sections[indexPath.section];
    NSDictionary *entry = _items[cellType][indexPath.row];
    CharacterDetailViewController *characterdetailvc = [self.storyboard instantiateViewControllerWithIdentifier:@"characterdetail"];
    [self.navigationController pushViewController:characterdetailvc animated:YES];
    if ([cellType isEqualToString:@"Characters"]) {
        switch ([listservice getCurrentServiceID]) {
            case 1: {
                [characterdetailvc populateCharacterData:entry];
                break;
            }
            case 3: {
                [characterdetailvc retrieveCharacterDetailsForID:((NSNumber *)entry[@"id"]).intValue];
                break;
            }
            default: {
                break;
            }
        }
        
        
        
    }
    else {
        [characterdetailvc retrievePersonDetailsForID:((NSNumber *)entry[@"id"]).intValue];
    }
}

@end
