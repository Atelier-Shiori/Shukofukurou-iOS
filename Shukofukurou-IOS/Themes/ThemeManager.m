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
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "ThemeManager.h"
#import "DefaultTheme.h"
#import "DarkTheme.h"

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
    [UITableViewCell appearance].backgroundView.backgroundColor = _currentTheme.tableCellSelectionBackgroundColor;
    [UILabel appearance].textColor = _currentTheme.textColor;
    [UITextField appearance].textColor = _currentTheme.textColor;
    [UITextView appearance].textColor = _currentTheme.textColor;;
    [UITextView appearance].backgroundColor = UIColor.clearColor;
    del.window.tintColor = _currentTheme.tintColor;
    [UISwitch appearance].thumbTintColor = _currentTheme.thumbTintColor;
    [UISlider appearance].thumbTintColor = _currentTheme.thumbTintColor;
    [UIProgressView appearance].trackTintColor = _currentTheme.trackTintColor;
    [UINavigationBar appearance].barStyle = _currentTheme.navBarStyle;
    [UIToolbar appearance].barStyle = _currentTheme.navBarStyle;
    [del getvcmanager].mvc.leftViewBackgroundColor = _currentTheme.viewBackgroundColor;
    // Keyboard
    [[IQKeyboardManager sharedManager] setOverrideKeyboardAppearance:YES];
    [[IQKeyboardManager sharedManager] setKeyboardAppearance:_currentTheme.keyboardappearence];
    //[[UITextView appearance] setKeyboardAppearance:_currentTheme.keyboardappearence];
    //[UITextField appearance].keyboardAppearance = _currentTheme.keyboardappearence;
    //[UISearchBar appearance].keyboardAppearance = _currentTheme.keyboardappearence;
    [NSNotificationCenter.defaultCenter postNotificationName:@"ThemeChanged" object:nil];
}
@end
