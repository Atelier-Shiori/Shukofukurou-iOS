//
//  LoadViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/09/04.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "LoadViewController.h"
#import "ViewControllerManager.h"

@interface LoadViewController ()

@end

@implementation LoadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Load the last viewed view controller
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    [vcm.mvc loadfromdefaults];
}


@end
