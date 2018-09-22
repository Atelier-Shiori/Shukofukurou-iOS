//
//  AnimeSearchRootViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/30.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AnimeSearchRootViewController.h"
#import "ViewControllerManager.h"
#import "SearchTabViewController.h"

@interface AnimeSearchRootViewController ()

@end

@implementation AnimeSearchRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Register with Search Tab View
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    SearchTabViewController *searchtabvc = [vcm getSearchTabView];
    searchtabvc.animesearchrootvc = self;
    _animesearchvc = (SearchViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"SearchView"];
    _animesearchvc.searchtype = AnimeSearchType;
    [_animesearchvc setTitle];
    self.viewControllers = @[_animesearchvc];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
