//
//  EpisodeDetailViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/5/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "EpisodeDetailViewController.h"
#import "EntryCellInfo.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "listservice.h"
#import "TitleInfoTableViewCell.h"
#import "NSString+HTMLtoNSAttributedString.h"
#import "ThemeManager.h"

@interface EpisodeDetailViewController ()
@property (strong) NSMutableDictionary *items;
@property (strong) NSArray *sections;
@property int episodeid;
@property int titleid;
@property bool setthemecolors;
@end

@implementation EpisodeDetailViewController

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ServiceChanged" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ThemeChanged" object:nil];
    _items = [NSMutableDictionary new];
    [self setThemeColors];
    _setthemecolors = true;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setThemeColors];
    _setthemecolors = true;
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"ServiceChanged"]) {
        // Leave Episode Detail
        self.navigationItem.hidesBackButton = NO;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else if ([notification.name isEqualToString:@"ThemeChanged"]) {
        [self setThemeColors];
        _setthemecolors = false;
    }
}

- (void)setThemeColors {
    if (!_setthemecolors) {
        bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
        ThemeManagerTheme *current = [ThemeManager sharedCurrentTheme];
        self.view.backgroundColor = darkmode ? current.viewAltBackgroundColor : current.viewBackgroundColor;
        self.tableView.backgroundColor = darkmode ? current.viewAltBackgroundColor : current.viewBackgroundColor;
        UITableViewCell *synopsis = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if ([synopsis isKindOfClass:[TitleInfoSynopsisTableViewCell class]]) {
            [(TitleInfoSynopsisTableViewCell*)synopsis fixTextColor];
        }
    }
}

- (void)retrieveEpisodeDetail:(int)episodeId withTitleId:(int)titleId {
    _episodeid = episodeId;
    _titleid = titleId;
    switch ([listservice getCurrentServiceID]) {
        case 2: {
            [Kitsu retrieveEpisodeDetails:episodeId completion:^(id responseObject) {
                [self populateData:responseObject];
            } error:^(NSError *error) {
                NSLog(@"%@",error);
                [self.navigationController popViewControllerAnimated:YES];
            }];
            break;
        }
        default: {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}

- (void)populateData:(NSDictionary *)responseData {
    // Generate Synopsis
    if (((NSString *)responseData[@"synopsis"]).length > 0) {
        _items[@"Synopsis"] = @[[[EntryCellInfo alloc] initCellWithTitle:@"Synopsis" withValue:responseData[@"synopsis"] withCellType:cellTypeSynopsis]];
    }
    NSMutableArray *details = [NSMutableArray new];
    [details addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Episode" withValue:((NSNumber *)responseData[@"episodeNumber"]).stringValue withCellType:cellTypeInfo]];
    [details addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Episode Length" withValue:((NSNumber *)responseData[@"episodeLength"]).stringValue withCellType:cellTypeInfo]];
    if (responseData[@"airDate"] != [NSNull null]) {
        [details addObject:[[EntryCellInfo alloc] initCellWithTitle:@"Air Date" withValue:responseData[@"airDate"] withCellType:cellTypeInfo]];
    }
    _items[@"Details"] = details;
    [self loadimage:responseData[@"thumbnail"]];
    self.navigationItem.title = responseData[@"episodeTitle"];
    if (_items[@"Synopsis"]) {
        _sections = @[@"Synopsis", @"Details"];
    }
    else {
        _sections = _items.allKeys;
    }
    [self.tableView reloadData];
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
    return 120;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellType = _sections[indexPath.section];
    EntryCellInfo *entry = _items[cellType][indexPath.row];
    
    // Configure the cell...
    switch (entry.type) {
        case cellTypeSynopsis: {
            TitleInfoSynopsisTableViewCell *synopsiscell = [tableView dequeueReusableCellWithIdentifier:@"synopsiscell" forIndexPath:indexPath];
            synopsiscell.valueText.attributedText = [(NSString *)entry.cellValue convertHTMLtoAttStr];
            [synopsiscell fixTextColor];
            return synopsiscell;
            break;
        }
        case cellTypeInfo: {
            TitleInfoBasicTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:@"titleinfocell" forIndexPath:indexPath];
            detailcell.textLabel.text = entry.cellTitle;
            detailcell.detailTextLabel.text = entry.cellValue;
            return detailcell;
            break;
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

#pragma mark helpers

- (void)loadimage:(NSString *)imageurl {
    if (imageurl.length > 0) {
        [_posterimage sd_setImageWithURL:[NSURL URLWithString:imageurl]];
    }
    else {
        _posterimage.image = [UIImage new];
    }
}
@end
