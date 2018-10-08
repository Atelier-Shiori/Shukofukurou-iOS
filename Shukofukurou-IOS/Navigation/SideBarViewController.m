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

@interface SideBarViewController ()

@property (strong, nonatomic) NSArray *sidebarItems;
@property (strong) ViewControllerManager *vcm;
@end

@implementation SideBarViewController
struct {
    unsigned int sidebarItemDidChange:1;
} delegateRespondsTo;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sidebarItems = [self generateSideBarItems];
    
    _vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    _vcm.sidebarvc = self;
    self.clearsSelectionOnViewWillAppear = NO;
    
    NSString *selectedrow = [NSUserDefaults.standardUserDefaults valueForKey:@"selectedmainview"];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[self getSidebarItemIndexForIdentifier:selectedrow] inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (NSArray *)generateSideBarItems {
    // Load sidebar items
    NSMutableArray *items = [NSMutableArray new];
    [items addObject:@{@"image" : @"anime" , @"title" : @"Anime", @"identifier" : @"anime-list", @"type" : @"cell"}];
    [items addObject:@{@"image" : @"manga" , @"title" : @"Manga", @"identifier" : @"manga-list", @"type" : @"cell"}];
    //[items addObject:@{@"image" : @"stats" , @"title" : @"Statistics", @"identifier" : @"stats", @"type" : @"cell"}];
    [items addObject:@{@"image" : @"search" , @"title" : @"Search", @"identifier" : @"search", @"type" : @"cell"}];
    [items addObject:@{@"image" : @"seasons" , @"title" : @"Seasons", @"identifier" : @"seasons", @"type" : @"cell"}];
    [items addObject:@{@"image" : @"airing" , @"title" : @"Airing", @"identifier" : @"airing", @"type" : @"cell"}];
    //[items addObject:@{@"image" : @"profilebrowser" , @"title" : @"Profile Browser", @"identifier" : @"profiles", @"type" : @"cell"}];
    //[items addObject:@{@"image" : @"export" , @"title" : @"Export List", @"identifier" : @"export", @"type" : @"cell"}];
    [items addObject:@{@"image" : @"settings" , @"title" : @"Settings", @"identifier" : @"settings", @"type" : @"cell"}];
    return items;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sidebarItems.count;
}

#pragma mark - UITableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *type = self.sidebarItems[indexPath.row][@"type"];
    UITableViewCell *cell;
    NSDictionary *cellinfo = self.sidebarItems[indexPath.row];
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
    cell.imageView.image = cellInfo[@"image"] ? [UIImage imageNamed:self.sidebarItems[indexPath.row][@"image"]] : [UIImage new];
    //cell.separatorView.hidden = (indexPath.row <= 3 || indexPath.row == self.sidebarItems.count-1);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0; //(indexPath.row == 1 || indexPath.row == 3) ? 22.0 : 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setMainViewController];
    NSDictionary *selecteditem = _sidebarItems[indexPath.row];
    [_delegate sidebarItemDidChange:(NSString *)selecteditem[@"identifier"]];
    [NSUserDefaults.standardUserDefaults setValue:selecteditem[@"identifier"] forKey:@"selectedmainview"];
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
            MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
            [self setDelegate:mainViewController];
        });
}

- (int)getSidebarItemIndexForIdentifier:(NSString *)identifier {
    int tmpindex = -1;
    for (NSDictionary *cell in _sidebarItems) {
        tmpindex++;
        if (cell[@"identifier"] && [identifier isEqualToString:cell[@"identifier"]]) {
            return tmpindex;
        }
    }
    return -1;
}

@end
