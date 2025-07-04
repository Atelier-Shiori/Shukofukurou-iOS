//
//  MainViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <LGSideMenuController/LGSideMenuController.h>
#import "SideBarMenuDelegate.h"


@interface MainViewController : LGSideMenuController <SideBarMenuDelegate>

@property (strong) UINavigationController *mainnavcontroller;
@property (readonly) bool shouldHideMenuButton;
- (void)loadfromdefaults;
- (void)hidetoolbarstate;
- (void)showtoolbarstate;
- (void)toggleView:(id)sender;
- (void)refresh:(id)sender;
- (void)goBack:(id)sender;
- (void)showWhatsNew:(bool)showatlaunch;
- (UINavigationController *)currentRootView;
@end
