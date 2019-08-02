//
//  MainViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "SettingsRootViewController.h"
#import "ViewControllerManager.h"
#import "listservice.h"
#import "TitleInfoViewController.h"
#import "ScrobbleManager.h"
#if defined(OSS)
#else
#import "TipJar.h"
#endif

@interface MainViewController ()
@property (strong) ViewControllerManager *vcm;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    _vcm.mvc = self;
    [self setsidebar:self.view.bounds.size];
    AppDelegate *del = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [del loadtheme];
#if defined(OSS)
    [self showopensourcemessage];
#endif
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self setsidebar:size];
}

- (void)setsidebar:(CGSize)size {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        // Always Shows Sidebar if in Landscape orientation
        if (size.width/size.height >= .75) {
            self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnPadLandscape;
        }
        else {
            self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnNone;
        }
        
        if ((size.height == 1024 && size.width <= 768) || size.height == 1112 || size.height == 1194 || size.height == 1366|| self.leftViewAlwaysVisibleOptions == LGSideMenuAlwaysVisibleOnNone) {
            _shouldHideMenuButton = NO;
        }
        else {
            _shouldHideMenuButton = YES;
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
- (void)hidetoolbarstate {
    self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnNone;
}
- (void)showtoolbarstate {
    [self setsidebar:self.view.bounds.size];
}
- (void)loadfromdefaults {
    NSString *selectedrow = [NSUserDefaults.standardUserDefaults valueForKey:@"selectedmainview"];
    [self sidebarItemDidChange:selectedrow];
}

- (UINavigationController *)currentRootView {
    NSString *identifier = [NSUserDefaults.standardUserDefaults valueForKey:@"selectedmainview"];
    if ([identifier isEqualToString:@"anime-list"]) {
        if ([listservice.sharedInstance checkAccountForCurrentService]) {
            return (UINavigationController *)[_vcm getAnimeListRootViewController];
        }
        else {
            return nil;
        }
    }
    else if ([identifier isEqualToString:@"manga-list"]) {
        if ([listservice.sharedInstance checkAccountForCurrentService]) {
            return (UINavigationController *)[_vcm getMangaListRootViewController];
        }
        else {
            return nil;
        }
    }
    else if ([identifier isEqualToString:@"search"]) {
        return (UINavigationController *)[_vcm getSearchView];
    }
    else if ([identifier isEqualToString:@"seasons"]) {
        return (UINavigationController *)[_vcm getSeasonRootViewController];
    }
    else if ([identifier isEqualToString:@"airing"]) {
        return (UINavigationController *)[_vcm getAiringRootViewController];
    }
    else if ([identifier isEqualToString:@"trending"]) {
        return (UINavigationController *)[_vcm getTrendingRootViewController];
    }
    else if ([identifier isEqualToString:@"settings"]) {
        return (UINavigationController *)[_vcm getSettingsRootViewController];
    }
#if defined(OSS)
#else
    else if ([identifier isEqualToString:@"tipjar"]) {
        return nil;
    }
#endif
    return nil;
}

- (void)sidebarItemDidChange:(NSString *)identifier {
    if ([identifier isEqualToString:@"anime-list"]) {
        if ([listservice.sharedInstance checkAccountForCurrentService]) {
            [self showAnimeListViewController];
        }
        else {
            [self showNotLoggedIn];
        }
    }
    else if ([identifier isEqualToString:@"manga-list"]) {
        if ([listservice.sharedInstance checkAccountForCurrentService]) {
            [self showMangaListViewController];
        }
        else {
            [self showNotLoggedIn];
        }
    }
    else if ([identifier isEqualToString:@"history"]) {
        if ([listservice.sharedInstance checkAccountForCurrentService]) {
            [self showHistoryViewController];
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
    else if ([identifier isEqualToString:@"trending"]) {
        [self showTrendingViewController];
    }
    else if ([identifier isEqualToString:@"settings"]) {
        [self showSettingsViewController];
    }
#if defined(OSS)
#else
    else if ([identifier isEqualToString:@"tipjar"]) {
        [self showTipJar];
    }
#endif
}

- (void)showAnimeListViewController {
    self.rootViewController = [_vcm getAnimeListRootViewController];
}

- (void)showMangaListViewController {
    self.rootViewController = [_vcm getMangaListRootViewController];
}

- (void)showHistoryViewController {
    self.rootViewController = [_vcm getHistoryRootViewController];
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

- (void)showTrendingViewController {
    self.rootViewController = [_vcm getTrendingRootViewController];
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
#if defined(OSS)
#else
- (void)showTipJar {
    UINavigationController *navcontroller = [UINavigationController new];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"TipJar" bundle:nil];
    TipJar *tipjarController = (TipJar *)[storyboard instantiateInitialViewController];
    navcontroller.viewControllers = @[tipjarController];
    self.rootViewController = navcontroller;
}
#endif
#pragma mark keyboard commands

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    return @[[UIKeyCommand keyCommandWithInput:@"1" modifierFlags:UIKeyModifierCommand action:@selector(toggleView:) discoverabilityTitle:@"Anime List"],
             [UIKeyCommand keyCommandWithInput:@"2" modifierFlags:UIKeyModifierCommand action:@selector(toggleView:) discoverabilityTitle:@"Manga List"],[UIKeyCommand keyCommandWithInput:@"3" modifierFlags:UIKeyModifierCommand action:@selector(toggleView:) discoverabilityTitle:@"Search"],[UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand action:@selector(toggleView:) discoverabilityTitle:@"Seasons"],[UIKeyCommand keyCommandWithInput:@"5" modifierFlags:UIKeyModifierCommand action:@selector(toggleView:) discoverabilityTitle:@"Airing"],[UIKeyCommand keyCommandWithInput:@"6" modifierFlags:UIKeyModifierCommand action:@selector(toggleView:) discoverabilityTitle:@"Trending"],[UIKeyCommand keyCommandWithInput:@"R" modifierFlags:UIKeyModifierCommand action:@selector(refresh:) discoverabilityTitle:@"Refresh"],[UIKeyCommand keyCommandWithInput:@"B" modifierFlags:UIKeyModifierCommand action:@selector(goBack:) discoverabilityTitle:@"Back"]];
}

- (void)toggleView:(id)sender {
    if (!self.presentedViewController) {
        UIKeyCommand *command = (UIKeyCommand *)sender;
        NSString *viewname;
        if ([command.discoverabilityTitle isEqualToString:@"Anime List"]) {
            viewname = @"anime-list";
        }
        else if ([command.discoverabilityTitle isEqualToString:@"Manga List"]) {
            viewname = @"manga-list";
        }
        else if ([command.discoverabilityTitle isEqualToString:@"Search"]) {
            viewname = @"search";
        }
        else if ([command.discoverabilityTitle isEqualToString:@"Seasons"]) {
            viewname = @"seasons";
        }
        else if ([command.discoverabilityTitle isEqualToString:@"Airing"]) {
            viewname = @"airing";
        }
        else if ([command.discoverabilityTitle isEqualToString:@"Trending"]) {
            viewname = @"trending";
        }
        [NSNotificationCenter.defaultCenter postNotificationName:@"SideBarSelectionChanged" object:viewname];
        [self sidebarItemDidChange:viewname];
    }
}

- (void)refresh:(id)sender {
    if (!self.presentedViewController) {
        UIViewController *visibleController;
        if ([self.rootViewController isEqual: [_vcm getAnimeListRootViewController]]) {
            ListRootViewController *listrootvc = (ListRootViewController *)self.rootViewController;
            visibleController = listrootvc.topViewController;
        }
        else if ([self.rootViewController isEqual: [_vcm getMangaListRootViewController]]) {
            ListRootViewController *listrootvc = (ListRootViewController *)self.rootViewController;
            visibleController = listrootvc.topViewController;
        }
        if ([self.rootViewController isEqual: [_vcm getSearchView]]) {
            SearchRootViewController *listrootvc = (SearchRootViewController *)self.rootViewController;
            visibleController = listrootvc.topViewController;
        }
        else if ([self.rootViewController isEqual: [_vcm getSeasonRootViewController]]) {
            SeasonsRootViewController *listrootvc = (SeasonsRootViewController *)self.rootViewController;
            visibleController = listrootvc.topViewController;
        }
        else if ([self.rootViewController isEqual: [_vcm getAiringRootViewController]]) {
            AiringRootViewController *listrootvc = (AiringRootViewController *)self.rootViewController;
            visibleController = listrootvc.topViewController;
        }
        else if ([self.rootViewController isEqual: [_vcm getTrendingRootViewController]]) {
            TrendingViewController *listrootvc = (TrendingViewController *)self.rootViewController;
            visibleController = listrootvc.topViewController;
        }
        if (visibleController) {
            NSLog(@"%@", NSStringFromClass(visibleController.class));
            if ([visibleController isKindOfClass:[ListViewController class]]) {
                ((ListViewController *)visibleController).initalload = NO;
                [(ListViewController *)visibleController refreshListWithCompletionHandler:^(bool success) {
                }];
                return;
            }
            else if ([visibleController isKindOfClass:[TitleInfoViewController class]]) {
                [(TitleInfoViewController *)visibleController refreshTitleInfo];
            }
            else if ([visibleController isKindOfClass:[SeasonsViewController class]]) {
                [(SeasonsViewController *)visibleController reloadData:YES];
            }
            else if ([visibleController isKindOfClass:[TrendingCollectionViewController class]]) {
                [(TrendingCollectionViewController *)visibleController loadretrieving];
            }
            else if ([visibleController isKindOfClass:[AiringViewController class]]) {
                [(AiringViewController *)visibleController performrefresh];
            }
        }
    }
}

- (void)goBack:(id)sender {
    if (!self.presentedViewController) {
        UINavigationController *navController = (UINavigationController *)self.rootViewController;
        if (navController.viewControllers.count > 1 && !navController.navigationItem.hidesBackButton && [navController.viewControllers[navController.viewControllers.count-1] isKindOfClass:[TitleInfoViewController class]]) {
            TitleInfoViewController *titleviewcontroller = (TitleInfoViewController *)navController.viewControllers[navController.viewControllers.count-1];
            [titleviewcontroller checkUnsavedChangesWithBlock:^{
                 [navController popViewControllerAnimated:YES];
            }];
            return;
        }
        if (navController.viewControllers.count > 1 && !navController.navigationItem.hidesBackButton) {
            [navController popViewControllerAnimated:YES];
        }
    }
}

- (void)showopensourcemessage {
#if defined(OSS)
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"You are using the community version." message:@"This is the community version, which provides you no support or warranty. If you are using a free Apple Developer Account, this app must be reinstalled every 7 days to continue fuctioning. This alert will appear on every launch. To remove this message, use the official App Store version." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertcontroller addAction:okaction];
        [self presentViewController:alertcontroller animated:YES completion:nil];
    });
#else
#endif
}

@end
