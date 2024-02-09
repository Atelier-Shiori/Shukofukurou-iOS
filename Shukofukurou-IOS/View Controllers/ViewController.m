//
//  ViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ViewController.h"
#import "ViewControllerManager.h"
#import <MBProgressHudFramework/MBProgressHUD.h>
#import "listservice.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;
@property (strong, nonatomic) IBOutlet UITableViewCell *logincell;
@property (strong) MBProgressHUD *hud;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"firstload"]) {
        [self showloadingview:YES];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [NSThread sleepForTimeInterval:2];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showloadingview:NO];
                [defaults setBool:YES forKey:@"firstload"];
            });
        });
    }
    // Do any additional setup after loading the view, typically from a nib.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sidebarShowAlwaysNotification:) name:@"sidebarStateDidChange" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(serviceChangedNotification:) name:@"ServiceChanged" object:nil];
    [self hidemenubtn];
    [self setLoginLabel];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)sidebarShowAlwaysNotification:(NSNotification *)notification {
    [self hidemenubtn];
}

- (void)serviceChangedNotification:(NSNotification *)notification {
    [self setLoginLabel];
}


- (void)setLoginLabel {
    _logincell.textLabel.text = [NSString stringWithFormat:@"Log into %@", [listservice.sharedInstance currentservicename]];
}

- (void)hidemenubtn {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if ([ViewControllerManager getAppDelegateViewControllerManager].mvc.shouldHideMenuButton) {
            [self.menubtn setEnabled:NO];
            [self.menubtn setTintColor: [UIColor clearColor]];
        }
        else {
            [self.menubtn setEnabled:YES];
            [self.menubtn setTintColor:nil];
        }
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomVision) {
        [self.menubtn setEnabled:NO];
        [self.menubtn setTintColor: [UIColor clearColor]];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showloadingview:(bool)show {
    if (show) {
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = @"Please Wait";
    }
    else {
        [_hud hideAnimated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    switch (cell.tag) {
        case 1: {
            ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
            [vcm.mainsidebar performLogin];
            [cell setSelected:NO animated:YES];
            break;
        }
        case 2: {
            [self openWebBrowserView:[NSURL URLWithString:@"https://help.malupdaterosx.moe/shukofukurou-for-ios/"]];
            [cell setSelected:NO animated:YES];
            break;
        }
        case 3: {
            [self openWebBrowserView:[NSURL URLWithString:@"https://help.malupdaterosx.moe/shukofukurou-for-ios/scrobble-manual/"]];
            [cell setSelected:NO animated:YES];
            break;
        }
        case 4: {
            ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
            [vcm.mainsidebar showSwitchServicesPickerasPopover:NO withSender:nil];
            break;
        }
        default:
            break;
    }
    
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)openWebBrowserView:(NSURL *)url {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomVision) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {}];
    }
    else {
        SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:url];
        [self presentViewController:svc animated:YES completion:^{
        }];
    }
}
@end
