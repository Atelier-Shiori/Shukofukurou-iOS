//
//  MangaSearchRootViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/30.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "MangaSearchRootViewController.h"
#import "ViewControllerManager.h"
#import "SearchTabViewController.h"

@interface MangaSearchRootViewController ()

@end

@implementation MangaSearchRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    SearchTabViewController *searchtabvc = [vcm getSearchTabView];
    searchtabvc.mangasearchrootvc = self;
    _mangasearchvc = (SearchViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"SearchView"];
    _mangasearchvc.searchtype = MangaSearchType;
    [_mangasearchvc setTitle];
    self.viewControllers = @[_mangasearchvc];
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
