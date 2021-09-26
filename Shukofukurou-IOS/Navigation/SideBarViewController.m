//
//  SideBarViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SideBarViewController.h"
#import "SideBarCell.h"
#import "MainViewController.h"
#import "ViewController.h"
#import <LGSideMenuController/UIViewController+LGSideMenuController.h>
#import "ViewControllerManager.h"
#import "UIViewThemed.h"

@interface SideBarViewController ()

//@property (strong, nonatomic) NSArray *sidebarItems;
@property (strong) NSDictionary *items;
@property (strong) NSArray *sections;
@property (strong) ViewControllerManager *vcm;
@end

@implementation SideBarViewController
struct {
    unsigned int sidebarItemDidChange:1;
} delegateRespondsTo;

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self generateSideBarItems];
    
    _vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    _vcm.sidebarvc = self;
    self.clearsSelectionOnViewWillAppear = NO;
    
    NSString *selectedrow = [NSUserDefaults.standardUserDefaults valueForKey:@"selectedmainview"];
    [self.tableView selectRowAtIndexPath:[self getSidebarItemIndexForIdentifier:selectedrow] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self setselectedcellbackground];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveNotification:) name:@"SideBarSelectionChanged" object:nil];
}

- (void)didReceiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"SideBarSelectionChanged"]) {
        [self.tableView selectRowAtIndexPath:[self getSidebarItemIndexForIdentifier:notification.object] animated:NO scrollPosition:UITableViewScrollPositionNone];
        [NSUserDefaults.standardUserDefaults setValue:notification.object forKey:@"selectedmainview"];
        [self setselectedcellbackground];
    }
}

- (void)generateSideBarItems {
    // Load sidebar items
    NSMutableArray *listitems = [NSMutableArray new];
    NSMutableArray *discoveritems = [NSMutableArray new];
    NSMutableArray *otheritems = [NSMutableArray new];
    [listitems addObject:@{@"image" : @"tv" , @"title" : @"Anime", @"identifier" : @"anime-list", @"type" : @"cell"}];
    [listitems addObject:@{@"image" : @"book" , @"title" : @"Manga", @"identifier" : @"manga-list", @"type" : @"cell"}];
    [listitems addObject:@{@"image" : @"clock" , @"title" : @"History", @"identifier" : @"history", @"type" : @"cell"}];
    [discoveritems addObject:@{@"image" : @"magnifyingglass" , @"title" : @"Search", @"identifier" : @"search", @"type" : @"cell"}];
    [discoveritems addObject:@{@"image" : @"calendar" , @"title" : @"Seasons", @"identifier" : @"seasons", @"type" : @"cell"}];
    [discoveritems addObject:@{@"image" : @"calendar.badge.clock" , @"title" : @"Airing", @"identifier" : @"airing", @"type" : @"cell"}];
    [discoveritems addObject:@{@"image" : @"star" , @"title" : @"Trending", @"identifier" : @"trending", @"type" : @"cell"}];
    //[items addObject:@{@"image" : @"profilebrowser" , @"title" : @"Profile Browser", @"identifier" : @"profiles", @"type" : @"cell"}];
    [otheritems addObject:@{@"image" : @"gearshape" , @"title" : @"Settings", @"identifier" : @"settings", @"type" : @"cell"}];
#if defined(OSS)
#else
    [otheritems addObject:@{@"image" : @"heart" , @"title" : @"Tip Jar", @"identifier" : @"tipjar", @"type" : @"cell"}];
#endif
    _items = @{@"" : listitems, @"Discover" : discoveritems, @"Other" : otheritems };
    _sections = @[@"", @"Discover", @"Other"];
}

#pragma mark - UITableViewDataSource

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    return tableView.sectionHeaderHeight;
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

#pragma mark - UITableView Delegate
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    UIViewGroupHeader *view = [[UIViewGroupHeader alloc] initIsSidebar:true isFirstSection:false];
    view.label.text = sectionTitle.uppercaseString;
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellType = _sections[indexPath.section];
    NSString *type = _items[cellType][indexPath.row][@"type"];
    UITableViewCell *cell;
    NSDictionary *cellinfo = _items[cellType][indexPath.row];
    if ([type isEqualToString:@"cell"]) {
        cell = [self generateNormalCell:cellinfo cellForRowAtIndexPath:indexPath withTableView:tableView];
    }
    else {
        cell = [UITableViewCell new];
    }
    return cell;
    
}

- (UITableViewCell *)generateNormalCell:(NSDictionary *)cellInfo cellForRowAtIndexPath:(NSIndexPath *)indexPath  withTableView:(UITableView *)tableView {
    SideBarCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    cell.titleLabel.text = cellInfo[@"title"];
    cell.imageView.image = cellInfo[@"image"] ? [UIImage systemImageNamed:cellInfo[@"image"]] : [UIImage new];
    //cell.separatorView.hidden = (indexPath.row <= 3 || indexPath.row == self.sidebarItems.count-1);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0; //(indexPath.row == 1 || indexPath.row == 3) ? 22.0 : 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setMainViewController];
    NSString *cellType = _sections[indexPath.section];
    NSDictionary *selecteditem = _items[cellType][indexPath.row];
    [_delegate sidebarItemDidChange:(NSString *)selecteditem[@"identifier"]];
    [NSUserDefaults.standardUserDefaults setValue:selecteditem[@"identifier"] forKey:@"selectedmainview"];
    [self setselectedcellbackground];
    [self hideLeftViewAnimated:self];
}

- (void)setDelegate:(id <SideBarMenuDelegate>)aDelegate {
    if (_delegate != aDelegate) {
        _delegate = aDelegate;
        delegateRespondsTo.sidebarItemDidChange = [_delegate respondsToSelector:@selector(sidebarItemDidChange:)];
    }
}

- (void)setMainViewController {
        static dispatch_once_t sidebarToken;
        dispatch_once(&sidebarToken, ^{
            MainViewController *mainViewController = _vcm.mvc;
            [self setDelegate:mainViewController];
        });
}

- (NSIndexPath *)getSidebarItemIndexForIdentifier:(NSString *)identifier {
    int tmpsectionindex = -1;
    for (NSString *section in _sections) {
        tmpsectionindex++;
        int tmpindex = -1;
        for (NSDictionary *cell in _items[section]) {
            tmpindex++;
            if (cell[@"identifier"] && [identifier isEqualToString:cell[@"identifier"]]) {
                return [NSIndexPath indexPathForRow:tmpindex inSection:tmpsectionindex];
            }
        }
    }
    return nil;
}

- (void)setselectedcellbackground {
    // This brings back the behavior of the cell background for selected cell from iOS 12 and earlier
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        cell.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    }
    NSString *selectedrow = [NSUserDefaults.standardUserDefaults valueForKey:@"selectedmainview"];
    UITableViewCell *selectedcell = [self.tableView cellForRowAtIndexPath:[self getSidebarItemIndexForIdentifier:selectedrow]];
    selectedcell.backgroundColor = [UIColor systemGray5Color];
}

@end
