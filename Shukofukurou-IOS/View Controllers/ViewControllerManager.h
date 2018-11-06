//
//  ViewControllerManager.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainSideBarViewController.h"
#import "SideBarViewController.h"
#import "SettingsRootViewController.h"
#import "SettingsViewController.h"
#import "ListRootViewController.h"
#import "ListViewController.h"
#import "SearchRootViewController.h"
#import "SeasonsRootViewController.h"
#import "AiringRootViewController.h"
#import "AiringViewController.h"
#import "ServiceSwitcherRootViewController.h"
#import "TrendingViewController.h"
#import "MainViewController.h"
#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ViewControllerManager : NSObject
@property (strong) MainSideBarViewController *mainsidebar;
@property (strong) SideBarViewController *sidebarvc;
@property (strong) MainViewController *mvc;

+ (instancetype)getAppDelegateViewControllerManager;
- (SettingsRootViewController *)getSettingsRootViewController;
- (ListRootViewController *)getAnimeListRootViewController;
- (ListRootViewController *)getMangaListRootViewController;
- (SearchRootViewController *)getSearchView;
- (SeasonsRootViewController *)getSeasonRootViewController;
- (AiringRootViewController *)getAiringRootViewController;
- (TrendingViewController *)getTrendingRootViewController;
- (ServiceSwitcherRootViewController *)getServiceSwitcherRootViewController;
- (ViewController *)getViewController;
@end

NS_ASSUME_NONNULL_END
