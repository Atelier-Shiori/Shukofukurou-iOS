//
//  ThemeManager.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 1/26/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import <LGSideMenuController/LGSideMenuController.h>
#import "ThemeManager.h"
#import "DefaultTheme.h"
#import "DarkTheme.h"
#import "AnimeEntryTableViewCell.h"
#import "MangaEntryTableViewCell.h"
#import "SearchTableViewCell.h"
#import "TitleInfoTableViewCell.h"
#import "ReviewTableViewCell.h"
#import "SideBarCell.h"
#import "SeasonCollectionViewCell.h"
#import "TrendingCollectionHeaderView.h"
#import "UIViewThemed.h"
#import <MBProgressHudFramework/MBProgressHUD.h>
#import "TableViewCellBackgroundView.h"
#import "UITableViewCellSelBackground.h"
#import "TitleInfoViewController.h"

@interface ThemeManager ()
@property ThemeManagerTheme *lightTheme;
@property ThemeManagerTheme *darkTheme;
@end

@implementation ThemeManager

+ (ThemeManagerTheme *)sharedCurrentTheme {
    AppDelegate *del = (AppDelegate *)UIApplication.sharedApplication.delegate;
    return del.tmanager.currentTheme;
}

- (id)init {
    if (self = [super init]) {
        _lightTheme = [DefaultTheme new];
        _darkTheme = [DarkTheme new];
        [self setTheme];
    }
    return self;
}
- (void)setTheme {
    if (@available (iOS 13, *)) {
        // iOS13 Theme fixes
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[UISwipeCellNoBackground class]]].tintColor = [UIColor whiteColor];
        [HighLightView appearanceWhenContainedInInstancesOfClasses:@[[MangaEntryTableViewCell class]]].tintColor = [UIColor colorNamed:@"IconImageColor"];
        [HighLightView appearanceWhenContainedInInstancesOfClasses:@[[AnimeEntryTableViewCell class]]].tintColor = [UIColor colorNamed:@"IconImageColor"];
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[SearchTableViewCell class]]].tintColor = [UIColor colorNamed:@"IconImageColor"];
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[TitleInfoViewControllerView class]]].tintColor = [UIColor colorNamed:@"IconImageColor"];
        return;
    }
    else {
        // Set Theme Appearence
        bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"]) {
            _currentTheme = _darkTheme;
            NSLog(@"Using Dark Theme.");
        }
        else {
            _currentTheme = _lightTheme;
            NSLog(@"Using Light Theme.");
        }
        AppDelegate *del = (AppDelegate *)UIApplication.sharedApplication.delegate;
        del.window.backgroundColor = _currentTheme.viewBackgroundColor;
        [UITableView appearance].backgroundColor = darkmode ? _currentTheme.viewBackgroundColor : _currentTheme.viewAltBackgroundColor;
        [UICollectionView appearance].backgroundColor = _currentTheme.viewBackgroundColor;
        [UITableViewCell appearance].backgroundColor = darkmode ? _currentTheme.viewAltBackgroundColor : _currentTheme.viewBackgroundColor;
        [UITableViewCell appearance].selectionStyle = UITableViewCellSelectionStyleDefault;
        [TableViewCellBackgroundView appearance].backgroundColor = _currentTheme.tableCellSelectionBackgroundColor;
        [UISegmentedControl appearance].tintColor = _currentTheme.tintColor;
        [UIToolbar appearance].tintColor = _currentTheme.tintColor;
        [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewHeaderFooterView class]]].textColor = _currentTheme.groupHeaderTextColor;
        [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]].textColor = _currentTheme.textColor;
        [UILabel appearanceWhenContainedInInstancesOfClasses:@[[SeasonCollectionViewCell class]]].textColor = _currentTheme.textColor;
        [UILabel appearanceWhenContainedInInstancesOfClasses:@[[TrendingCollectionHeaderView class]]].textColor = _currentTheme.textColor;
        [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UIViewThemed class]]].textColor = _currentTheme.textColor;
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[SideBarCell class]]].tintColor = _currentTheme.tintColor;
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[AnimeEntryTableViewCell class]]].tintColor = _currentTheme.tablecellImageTintColor;
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[MangaEntryTableViewCell class]]].tintColor =  _currentTheme.tablecellImageTintColor;
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[AnimeEntryTableViewCell class]]].tintColor = _currentTheme.tablecellImageTintColor;
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[SearchTableViewCell class]]].tintColor = _currentTheme.tablecellImageTintColor;
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[ReactionTableViewCell class]]].tintColor = _currentTheme.tablecellImageTintColor;
        [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[UISwipeCellNoBackground class]]].tintColor = _currentTheme.tablecellImageTintColor;
        [UITableViewHeaderFooterView appearance].tintColor = _currentTheme.tableHeaderBackgroundColor;
        [UINavigationBar appearance].tintColor = _currentTheme.tintColor;
        [UITableViewCell  appearance].tintColor = _currentTheme.tintColor;
        [UITextField appearance].textColor = _currentTheme.textColor;
        [UITextView appearance].textColor = _currentTheme.textColor;;
        [UITextView appearance].backgroundColor = UIColor.clearColor;
        del.window.tintColor = _currentTheme.tintColor;
        [UISwitch appearance].thumbTintColor = _currentTheme.thumbTintColor;
        [UISlider appearance].thumbTintColor = _currentTheme.thumbTintColor;
        [UIProgressView appearance].trackTintColor = _currentTheme.trackTintColor;
        [UINavigationBar appearance].barStyle = _currentTheme.navBarStyle;
        [UIToolbar appearance].barStyle = _currentTheme.navBarStyle;
        [del getvcmanager].mvc.leftViewBackgroundColor = _currentTheme.viewAltBackgroundColor;
        // Keyboard
        [UITextField appearance].keyboardAppearance = _currentTheme.keyboardappearence;
        [UISearchBar appearance].keyboardAppearance = _currentTheme.keyboardappearence;
        [NSNotificationCenter.defaultCenter postNotificationName:@"ThemeChanged" object:nil];
    }
}
+ (void)fixTableView:(UITableView *)tableView {
    // Fixes Dark Mode under iOS 12
    if (@available(iOS 13, *)) {}
    else {
        bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
        [tableView setBackgroundView:nil];
        tableView.backgroundColor = darkmode ? ThemeManager.sharedCurrentTheme.viewBackgroundColor : ThemeManager.sharedCurrentTheme.viewAltBackgroundColor;
    }
}
@end

@implementation HighLightView

@end
