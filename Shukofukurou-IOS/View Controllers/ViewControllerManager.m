//
//  ViewControllerManager.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ViewControllerManager.h"
#import "AppDelegate.h"

@interface ViewControllerManager ()
@property (strong) SettingsRootViewController *rsettingsvc;
@property (strong) SettingsViewController *settingsvc;
@property (strong) ListViewController *animelistview;
@property (strong) ListRootViewController *animelistrootview;
@property (strong) ListViewController *mangalistview;
@property (strong) ListRootViewController *mangalistrootview;
@property (strong) SearchRootViewController *searchvc;
@property (strong) SeasonsRootViewController *seasonsrootview;
@property (strong) AiringRootViewController *airingrootview;
@property (strong) ServiceSwitcherRootViewController *serviceswitcherrootvc;
@property (strong) ViewController *vc;
@end


@implementation ViewControllerManager
+ (instancetype)getAppDelegateViewControllerManager {
    return [((AppDelegate *)UIApplication.sharedApplication.delegate) getvcmanager];
}

- (instancetype)init {
    if (self = [super init]) {
        if ([self getAnimeListRootViewController] && [self getMangaListRootViewController]) {
            NSLog(@"Initalized List Controllers");
        }
    }
    return self;
}

- (SettingsRootViewController *)getSettingsRootViewController {
    if (!_rsettingsvc) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
        _rsettingsvc = (SettingsRootViewController *)[storyboard instantiateViewControllerWithIdentifier:@"SettingsRootViewController"];
    }
    return _rsettingsvc;
}

- (ListRootViewController *)getAnimeListRootViewController {
    if (!_animelistrootview) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Lists" bundle:nil];
        _animelistrootview = (ListRootViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ListViewRoot"];
        [_animelistrootview setListType:Anime];
    }
    return _animelistrootview;
}

- (ListRootViewController *)getMangaListRootViewController {
    if (!_mangalistrootview) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Lists" bundle:nil];
        _mangalistrootview = (ListRootViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ListViewRoot"];
        [_mangalistrootview setListType:Manga];
    }
    return _mangalistrootview;
}

- (SearchRootViewController *)getSearchView {
    if (!_searchvc) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Search" bundle:nil];
        _searchvc = (SearchRootViewController *)[storyboard instantiateViewControllerWithIdentifier:@"searchroot"];
    }
    return _searchvc;
}

- (SeasonsRootViewController *)getSeasonRootViewController {
    if (!_seasonsrootview) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Seasons" bundle:nil];
        _seasonsrootview = (SeasonsRootViewController *)[storyboard instantiateViewControllerWithIdentifier:@"SeasonsRootView"];
    }
    return _seasonsrootview;
}

- (AiringRootViewController *)getAiringRootViewController {
    if (!_airingrootview) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Airing" bundle:nil];
        _airingrootview = (AiringRootViewController *)[storyboard instantiateViewControllerWithIdentifier:@"AiringRootView"];
    }
    return _airingrootview;
}

- (ServiceSwitcherRootViewController *)getServiceSwitcherRootViewController {
    if (!_serviceswitcherrootvc) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ServiceSwitcher" bundle:nil];
        _serviceswitcherrootvc = (ServiceSwitcherRootViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ServiceSelectorNav"];
    }
    return _serviceswitcherrootvc;
}

- (ViewController *)getViewController {
    if (!_vc) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _vc = (ViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    }
    return _vc;
}
@end
