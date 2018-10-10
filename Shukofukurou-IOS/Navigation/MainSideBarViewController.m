//
//  MainSideBarViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "MainSideBarViewController.h"
#import <LGSideMenuController/UIViewController+LGSideMenuController.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "ViewControllerManager.h"
#import "MainViewController.h"
#import "ListService.h"
#import "OAuthLogin.h"
#import "AuthViewController.h"
#import "AppDelegate.h"
#import "Keychain.h"
#import "AtarashiiListCoreData.h"

@interface MainSideBarViewController ()
@property (strong) MainViewController *mainvc;
@end

@implementation MainSideBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setLoggedinUser];
    // Register with view controller manager
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    vcm.mainsidebar = self;
    _delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setLoggedinUser {
    if ([listservice checkAccountForCurrentService]) {
        _logintoolbarbtn.title = @"Logout";
        _username.text = [listservice getCurrentServiceUsername];
        NSString *avatarurl = [listservice getCurrentUserAvatar];
        if (avatarurl.length > 0) {
            [_avatar sd_setImageWithURL:[NSURL URLWithString:avatarurl]];
        }
        else {
            _avatar.image = [UIImage new];
        }
    }
    else {
        _logintoolbarbtn.title = @"Login";
        _username.text = @"Not logged in";
        _avatar.image = [UIImage new];
    }
    _servicename.text = [listservice currentservicename];
}

- (IBAction)accountaction:(id)sender {
    [self performLogin];
}

- (void)performLogin {
    [self hideLeftViewAnimated:self];
    [self setMainViewController];
    if ([_logintoolbarbtn.title isEqualToString:@"Login"]) {
        // Show Login Dialog
        switch ([listservice getCurrentServiceID]) {
            case 1:
            case 2:
                [self performusernamepassLogin];
                break;
            case 3:
                [self performOAuthLogin];
                break;
            default:
                break;
        }
    }
    else {
        // Prompt Logout
        [self performlogout];
    }
}

- (void)performusernamepassLogin {
    UINavigationController *navcontroller = [UINavigationController new];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Auth" bundle:nil];
    AuthViewController *authvc = (AuthViewController *)[storyboard instantiateViewControllerWithIdentifier:@"AuthViewController"];
    [navcontroller setViewControllers:@[authvc]];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navcontroller.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [_mainvc presentViewController:navcontroller animated:YES completion:nil];
}

- (void)performOAuthLogin {
    OAuthLogin *login = [OAuthLogin new];
    [login startAniListOAuthSession];
}

- (void)performlogout {
    __weak MainSideBarViewController *weakself = self;
    UIAlertController *prompt = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Are you sure you want to logout of %@?", [listservice currentservicename]] message:@"To use certain features, you need to login again." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        int currentservice = [listservice getCurrentServiceID];
        [weakself removeAccount:currentservice];
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    [prompt addAction:yesaction];
    [prompt addAction:noaction];
    [_mainvc presentViewController:prompt animated:YES completion:nil];
}

- (void)removeAccount:(int)service {
    // Clears user data for logged in account
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    //Remove account from keychain and account data
    [AtarashiiListCoreData removeAllEntrieswithService:service];
    switch (service) {
        case 1:
            [Keychain removeaccount];
            break;
        case 2:
            [Kitsu removeAccount];
            [defaults setValue:@"" forKey:@"kitsu-username"];
            [defaults setInteger:0 forKey:@"kitsu-ratingsystem"];
            [defaults setValue:@(0) forKey:@"kitsu-userid"];
            [defaults setValue:@"" forKey:@"kitsu-avatar"];
            break;
        case 3:
            [AniList removeAccount];
            [defaults setValue:@(0) forKey:@"anilist-userid"];
            [defaults setValue:@"" forKey:@"anilist-username"];
            [defaults setValue:@"" forKey:@"anilist-scoreformat"];
            [defaults setValue:@"" forKey:@"anilist-avatar"];
            if ([defaults boolForKey:@"anilist-selectedlistcustomlistanime"]) {
                [defaults setValue:@"watching" forKey:@"anilist-selectedanimelist"];
                [defaults setBool:NO forKey:@"anilist-selectedlistcustomlistanime"];
            }
            if ([defaults boolForKey:@"anilist-selectedlistcustomlistmanga"]) {
                [defaults setValue:@"reading" forKey:@"anilist-selectedmangalist"];
                [defaults setBool:NO forKey:@"anilist-selectedlistcustomlistmanga"];
            }
        default:
            break;
    }
    [self setLoggedinUser];
    [self.delegate accountRemovedForService:service];
}

- (IBAction)switchservices:(id)sender {
    [self hideLeftViewAnimated:self];
    [self setMainViewController];
    ServiceSwitcherRootViewController *serviceswitcher = [[ViewControllerManager getAppDelegateViewControllerManager] getServiceSwitcherRootViewController];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (_mainvc.view.bounds.size.width > _mainvc.view.bounds.size.height) {
            serviceswitcher.modalPresentationStyle = UIModalPresentationPopover;
            serviceswitcher.popoverPresentationController.barButtonItem = sender;
            serviceswitcher.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
        }
        else {
            serviceswitcher.modalPresentationStyle = UIModalPresentationFormSheet;
        }
    }
    [_mainvc presentViewController:serviceswitcher animated:YES completion:nil];
}

- (void)setMainViewController {
    static dispatch_once_t sidebarToken;
    dispatch_once(&sidebarToken, ^{
        self.mainvc = (MainViewController *)self.sideMenuController;
    });
}


@end
