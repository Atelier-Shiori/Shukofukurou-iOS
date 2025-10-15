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
#import <Shukofukurou_IOS-Swift.h>
#if defined(OSS)
#else
#import "TipJar.h"
#endif

@import WhatsNewKit;

@interface MainViewController ()
@property (strong) ViewControllerManager *vcm;
@property (strong) UISplitViewController *svcontroller;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    _vcm.mvc = self;
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomVision) {
        [self setsidebar:self.view.bounds.size];
    }
    else {
        self.leftViewBackgroundColor = [UIColor systemBackgroundColor];
    }
#if defined(OSS)
    [self showopensourcemessage];
#endif
}

- (void)showWhatsNew:(bool)showatlaunch {
    SWhatsNew *wn = [SWhatsNew new];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"WhatsNew" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    [wn showWhatsNewWithWitems:json[@"items"] vc:self showAtLaunch:showatlaunch];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self setsidebar:size];
}


- (void)setsidebar:(CGSize)size {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnNone;
        _shouldHideMenuButton = YES;
        AppDelegate *del = (AppDelegate *)UIApplication.sharedApplication.delegate;
        [del.msvc setPrimaryBackgroundStyle:UISplitViewControllerBackgroundStyleSidebar];
    }
#if TARGET_OS_VISION
    self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnNone;
    self.leftViewWidth = 300;
    _shouldHideMenuButton = YES;
#else
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
#endif
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
    int currentservice = listservice.sharedInstance.getCurrentServiceID;
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
        if (currentservice == 1 && ![listservice.sharedInstance checkAccountForCurrentService]) {
            return nil;
        }
        return (UINavigationController *)[_vcm getSearchView];
    }
    else if ([identifier isEqualToString:@"seasons"]) {
        if (currentservice == 1 && ![listservice.sharedInstance checkAccountForCurrentService]) {
            return nil;
        }
        return (UINavigationController *)[_vcm getSeasonRootViewController];
    }
    else if ([identifier isEqualToString:@"airing"]) {
        if (currentservice == 1 && ![listservice.sharedInstance checkAccountForCurrentService]) {
            return nil;
        }
        return (UINavigationController *)[_vcm getAiringRootViewController];
    }
    else if ([identifier isEqualToString:@"trending"]) {
        if (currentservice == 1 && ![listservice.sharedInstance checkAccountForCurrentService]) {
            return nil;
        }
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
    int currentservice = listservice.sharedInstance.getCurrentServiceID;
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
    AppDelegate *del = (AppDelegate *)UIApplication.sharedApplication.delegate;
    UISplitViewController *svc = del.msvc;
    NSLog(@"Main: width: %f height: %f", self.view.frame.size.width, self.view.frame.size.height);
    NSLog(@"Root: width: %f height: %f", self.rootViewContainer.frame.size.width, self.view.frame.size.height);
    NSLog(@"Main: width: %f height: %f", svc.view.frame.size.width, svc.view.frame.size.height);
    [self.rootViewContainer setFrame:CGRectMake(0, 0, del.window.frame.size.width, self.rootViewContainer.frame.size.height)];
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
#if TARGET_OS_VISION
    return @[];
#else
    return @[];
#endif
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
