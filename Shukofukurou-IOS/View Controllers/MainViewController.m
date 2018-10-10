//
//  MainViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "MainViewController.h"
#import "SettingsRootViewController.h"
#import "ViewControllerManager.h"
#import "listservice.h"

@interface MainViewController ()
@property (strong) ViewControllerManager *vcm;
@end

@implementation MainViewController

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    _vcm.mvc = self;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self setsidebar:self.view.bounds.size];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self setsidebar:size];
}

- (void)setsidebar:(CGSize)size {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        // Always Shows Sidebar if in Landscape orientation
        if (size.width/size.height >= 1) {
            self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnPadLandscape;
            _shouldHideMenuButton = YES;
        }
        else {
            self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnNone;
            _shouldHideMenuButton = NO;
        }
        [NSNotificationCenter.defaultCenter postNotificationName:@"sidebarStateDidChange" object:@(_shouldHideMenuButton)];
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        // Fixes Sidebar Width when in landscape on X models
        int iPhoneHeight = (int)[[UIScreen mainScreen] nativeBounds].size.height;
        bool isiPhoneXModel = (iPhoneHeight == 2436 || iPhoneHeight == 2688 || iPhoneHeight == 1792);
        if (!isiPhoneXModel) {
            return;
        }
        if (size.width/size.height >= 1) {
            self.leftViewWidth = 295;
        }
        else {
            self.leftViewWidth = 250;
        }
    }
}
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnNone;
    [super viewWillLayoutSubviews];
    
}
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self setsidebar:self.view.bounds.size];
    [super viewDidLayoutSubviews];
}
- (void)loadfromdefaults {
    NSString *selectedrow = [NSUserDefaults.standardUserDefaults valueForKey:@"selectedmainview"];
    [self sidebarItemDidChange:selectedrow];
}

- (void)sidebarItemDidChange:(NSString *)identifier {
    if ([identifier isEqualToString:@"anime-list"]) {
        if ([listservice checkAccountForCurrentService]) {
            [self showAnimeListViewController];
        }
        else {
            [self showNotLoggedIn];
        }
    }
    else if ([identifier isEqualToString:@"manga-list"]) {
        if ([listservice checkAccountForCurrentService]) {
            [self showMangaListViewController];
        }
        else {
            [self showNotLoggedIn];
        }
    }
    else if ([identifier isEqualToString:@"search"]) {
        [self showSearchViewController];
    }
    else if ([identifier isEqualToString:@"seasons"]) {
        [self showSeasonViewController];
    }
    else if ([identifier isEqualToString:@"airing"]) {
        [self showAiringViewController];
    }
    else if ([identifier isEqualToString:@"settings"]) {
        [self showSettingsViewController];
    }
}

- (void)showAnimeListViewController {
    self.rootViewController = [_vcm getAnimeListRootViewController];
}

- (void)showMangaListViewController {
    self.rootViewController = [_vcm getMangaListRootViewController];
}

- (void)showSearchViewController {
    self.rootViewController = [_vcm getSearchView];
}

- (void)showSeasonViewController {
    self.rootViewController = [_vcm getSeasonRootViewController];
}

- (void)showAiringViewController {
    self.rootViewController = [_vcm getAiringRootViewController];
}

- (void)showSettingsViewController {
    self.rootViewController = [_vcm getSettingsRootViewController];
    [NSNotificationCenter.defaultCenter postNotificationName:@"SettingsViewLoaded" object:nil];
}

- (void)showNotLoggedIn {
    UINavigationController *navcontroller = [UINavigationController new];
    navcontroller.viewControllers = @[[_vcm getViewController]];
    self.rootViewController = navcontroller;
}

@end
