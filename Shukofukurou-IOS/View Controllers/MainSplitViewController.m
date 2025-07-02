//
//  MainSplitViewController.m
//  Shukofukurou-IOS
//
//  Created by 乃苺佳寿 on 7/2/25.
//  Copyright © 2025 MAL Updater OS X Group. All rights reserved.
//

#import "MainSplitViewController.h"
#import "AppDelegate.h"

@interface MainSplitViewController ()

@end

@implementation MainSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AppDelegate *del = (AppDelegate *)UIApplication.sharedApplication.delegate;
    del.msvc = self;
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
