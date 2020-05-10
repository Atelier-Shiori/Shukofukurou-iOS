//
//  TokenReauthManager.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 5/10/20.
//  Copyright © 2020 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TokenReauthManager.h"
#import "listservice.h"
#import "MainViewController.h"
#import "ViewControllerManager.h"

@implementation TokenReauthManager
+ (void)checkRefreshOrReauth {
    if ([listservice.sharedInstance checkAccountForCurrentService]) {
        int current = listservice.sharedInstance.getCurrentServiceID;
        switch (current) {
            case 1: {
                if (listservice.sharedInstance.myanimelistManager.tokenexpired) {
                    [listservice.sharedInstance.myanimelistManager refreshToken:^(bool success) {
                        if (!success) {
                            [TokenReauthManager showReAuthMessage];
                        }
                    }];
                }
                break;
            }
            case 3: {
                if (listservice.sharedInstance.anilistManager.tokenexpired) {
                    [TokenReauthManager showReAuthMessage];
                }
                break;
            }
            default:
                break;
        }
    }
}
+ (void)showReAuthMessage {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Token Refresh Failed" message:[NSString stringWithFormat:@"Do you want to reauthorize your %@ account? Note that you need to login using the same credentials of your currently logged in account", listservice.sharedInstance.currentservicename] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
        [vcm.mainsidebar performOAuthReauth];
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertcontroller addAction:noaction];
    [alertcontroller addAction:yesaction];
    [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}
@end
