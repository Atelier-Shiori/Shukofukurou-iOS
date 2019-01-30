//
//  CustomListTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/24/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "CustomListTableViewController.h"
#import "listservice.h"
#import "AtarashiiListCoreData.h"
#import "ThemeManager.h"

@interface CustomListTableViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *savebtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelbtn;
@property (strong) NSMutableArray *customListArray;
@end

@implementation CustomListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadTheme];
    _customListArray = [NSMutableArray new];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)loadTheme {
    self.tableView.backgroundColor = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ?  [ThemeManager sharedCurrentTheme].viewAltBackgroundColor : [ThemeManager sharedCurrentTheme].viewBackgroundColor;
}

- (void)populateCustomLists:(NSDictionary *)entry withCurrentType:(int)type withSelectedId:(int)selid {
    [_customListArray removeAllObjects];
    NSString *cliststr = entry[@"custom_lists"];
    if (cliststr.length > 0) {
        NSArray *customlist = [cliststr componentsSeparatedByString:@"||"];
        // Process String
        for (NSString *clistentry in customlist) {
            bool enabled = [clistentry containsString:@"[true]"];
            NSString *customlistname = [[clistentry stringByReplacingOccurrencesOfString:@"[true]" withString:@""] stringByReplacingOccurrencesOfString:@"[false]" withString:@""];
            NSMutableDictionary *lentry = [NSMutableDictionary new];
            lentry[@"name"] = customlistname;
            lentry[@"enabled"] = @(enabled);
            [_customListArray addObject:lentry];
        }
        [self.tableView reloadData];
        _currenttype = type;
        _entryid = selid;
    }
    else {
        [self shownocustomlistsmessage];
    }
}

- (NSArray *)generateCustomListArray {
    NSMutableArray *finalarray = [NSMutableArray new];
    for (NSDictionary *customlistentry in _customListArray) {
        if (((NSNumber *)customlistentry[@"enabled"]).boolValue) {
            [finalarray addObject:customlistentry[@"name"]];
        }
    }
    return finalarray;
}

- (NSString *)generateCustomListStringWithArray:(NSArray *)clists {
    NSMutableArray *customlists = [NSMutableArray new];
    for (NSDictionary *clist in clists) {
        NSString *clistname = clist[@"name"];
        bool enabled = ((NSNumber *)clist[@"enabled"]).boolValue;
        NSString *finalstring = [NSString stringWithFormat:@"%@[%@]",clistname, enabled ? @"true" : @"false"];
        [customlists addObject:finalstring];
    }
    return [customlists componentsJoinedByString:@"||"];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _customListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"customlistcell" forIndexPath:indexPath];
    NSMutableDictionary *entry = _customListArray[indexPath.row];
    // Configure the cell...
    cell.textLabel.text = entry[@"name"];
    if (((NSNumber *)entry[@"enabled"]).boolValue) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSMutableDictionary *entry = _customListArray[indexPath.row];
    entry[@"enabled"] = @(!((NSNumber *)entry[@"enabled"]).boolValue);
    if (((NSNumber *)entry[@"enabled"]).boolValue) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell setSelected:NO animated:YES];
}

#pragma mark button actions

- (IBAction)cancelcustomlistedit:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)savecustomlists:(id)sender {
    _cancelbtn.enabled = NO;
    _savebtn.enabled = NO;
    __weak CustomListTableViewController *weakSelf = self;
    [AniList modifyCustomLists:_entryid withCustomLists:[self generateCustomListArray] completion:^(id responseObject) {
        weakSelf.cancelbtn.enabled = YES;
        weakSelf.savebtn.enabled = YES;
        if (responseObject[@"data"] != [NSNull null]) {
            NSString *customliststr = [weakSelf generateCustomListStringWithArray:responseObject[@"data"][@"SaveMediaListEntry"][@"customLists"]];
            [AtarashiiListCoreData updateSingleEntry:@{@"custom_lists" : customliststr} withUserId:[listservice getCurrentUserID] withService:[listservice getCurrentServiceID] withType:weakSelf.currenttype withId:weakSelf.entryid withIdType:1];
            switch (weakSelf.currenttype) {
                case 0:
                    [NSNotificationCenter.defaultCenter postNotificationName:@"AnimeReloadList" object:nil];
                    break;
                case 1:
                    [NSNotificationCenter.defaultCenter postNotificationName:@"MangaReloadList" object:nil];
                    break;
            }
        }
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } error:^(NSError *error) {
        NSLog(@"%@",error);
        weakSelf.cancelbtn.enabled = YES;
        weakSelf.savebtn.enabled = YES;
    }];
}

- (void)shownocustomlistsmessage {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Custom Lists Available" message:@"To add or remove entries from custom lists, you need to create custom lists on AniList first. After creating custom lists, refresh your library and try again." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
