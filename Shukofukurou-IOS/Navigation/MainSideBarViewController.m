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
#import "UIImageView+Letters.h"
#import "ViewControllerManager.h"
#import "MainViewController.h"
#import "ListService.h"
#import "OAuthLogin.h"
#import "AuthViewController.h"
#import "AppDelegate.h"
#import "Keychain.h"
#import "AtarashiiListCoreData.h"
#import "StatsViewController.h"
#import "ThemeManager.h"
#import "ExportMainTableViewController.h"

@interface MainSideBarViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *optionsbuttonitem;
@property (strong) MainViewController *mainvc;
@property (strong, nonatomic) IBOutlet UIImageView *servicelogo;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@end

@implementation MainSideBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setLoggedinUser];
    if (@available(iOS 13, *)) { }
    else {
        _username.textColor = [ThemeManager sharedCurrentTheme].textColor;
        _toolbar.tintColor = [ThemeManager sharedCurrentTheme].tintColor;
    }
    // Register with view controller manager
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    vcm.mainsidebar = self;
    self.navigationController.toolbarHidden = NO;
    _delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveNotification:) name:@"ThemeChanged" object:nil];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)didReceiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"ThemeChanged"]) {
        if (@available(iOS 13, *)) { }
        else {
            _username.textColor = [ThemeManager sharedCurrentTheme].textColor;
            _toolbar.tintColor = [ThemeManager sharedCurrentTheme].tintColor;
        }
    }
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
    if ([listservice.sharedInstance checkAccountForCurrentService]) {
        _logintoolbarbtn.title = @"Logout";
        _optionsbuttonitem.enabled = YES;
        _username.text = [listservice.sharedInstance getCurrentServiceUsername];
        NSString *avatarurl = [listservice.sharedInstance getCurrentUserAvatar];
        if (avatarurl.length > 0) {
            [_avatar sd_setImageWithURL:[NSURL URLWithString:avatarurl]];
        }
        else {
            [_avatar setImageWithString:_username.text];
        }
        _avatar.layer.cornerRadius = _avatar.frame.size.width /2;
        _avatar.layer.masksToBounds = YES;
        _avatar.layer.borderWidth = 3.0f;
        _avatar.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    else {
        _logintoolbarbtn.title = @"Login";
        _username.text = @"Not logged in";
        _optionsbuttonitem.enabled = NO;
        _avatar.image = [UIImage new];
        _avatar.layer.masksToBounds = NO;
        _avatar.layer.borderWidth = 0;
    }
    _servicelogo.image = [UIImage imageNamed:[listservice.sharedInstance currentservicename].lowercaseString];
}

- (IBAction)accountaction:(id)sender {
    [self performLogin];
}

- (void)performLogin {
    [self hideLeftViewAnimated:self];
    [self setMainViewController];
    if ([_logintoolbarbtn.title isEqualToString:@"Login"]) {
        // Show Login Dialog
        switch ([listservice.sharedInstance getCurrentServiceID]) {
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
    UIAlertController *prompt = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Are you sure you want to logout of %@?", [listservice.sharedInstance currentservicename]] message:@"To use certain features, you need to login again." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        int currentservice = [listservice.sharedInstance getCurrentServiceID];
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
    bool accountexists = true;
    switch (service) {
        case 1:
            [Keychain removeaccount];
            accountexists = [Keychain checkaccount];
            break;
        case 2:
            [listservice.sharedInstance .kitsuManager removeAccount];
            accountexists = [listservice.sharedInstance .kitsuManager getFirstAccount];
            if (!accountexists) {
                [defaults setValue:@"" forKey:@"kitsu-username"];
                [defaults setInteger:0 forKey:@"kitsu-ratingsystem"];
                [defaults setValue:@(0) forKey:@"kitsu-userid"];
                [defaults setValue:@"" forKey:@"kitsu-avatar"];
            }
            break;
        case 3:
            [listservice.sharedInstance .anilistManager removeAccount];
            accountexists = [listservice.sharedInstance .anilistManager getFirstAccount];
            if (!accountexists) {
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
            }
            break;
        default:
            return;
    }
    if (!accountexists) {
        //Remove account from keychain and account data
        [AtarashiiListCoreData removeAllEntrieswithService:service];
        [self setLoggedinUser];
        [self.delegate accountRemovedForService:service];
    }
}

- (IBAction)switchservices:(id)sender {
    [self hideLeftViewAnimated:self];
    [self setMainViewController];
    [self showSwitchServicesPickerasPopover:YES withSender:sender];
}

- (void)showSwitchServicesPickerasPopover:(bool)showasPopover withSender:(nullable id)sender {
    [self hideLeftViewAnimated:self];
    [self setMainViewController];
    ServiceSwitcherRootViewController *serviceswitcher = [[ViewControllerManager getAppDelegateViewControllerManager] getServiceSwitcherRootViewController];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (_mainvc.view.bounds.size.width > _mainvc.view.bounds.size.height && showasPopover && sender) {
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

- (IBAction)showoptions:(id)sender {
    [self setMainViewController];
    UIAlertController *options = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    bool isloggedin = [listservice.sharedInstance checkAccountForCurrentService];
    __weak MainSideBarViewController *weakself = self;
    if (isloggedin) {
        [options addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"View List Stats"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UINavigationController *navcontroller = [UINavigationController new];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Stats" bundle:nil];
            StatsViewController *statsviewcontroller = (StatsViewController *)[storyboard instantiateInitialViewController];
            [navcontroller setViewControllers: @[statsviewcontroller]];
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                navcontroller.modalPresentationStyle = UIModalPresentationFormSheet;
            }
            [weakself.mainvc presentViewController:navcontroller animated:YES completion:nil];
            [weakself hideLeftViewAnimated:weakself];
        }]];
    }
    [options addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Export Lists"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UINavigationController *navcontroller = [UINavigationController new];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Export" bundle:nil];
        ExportMainTableViewController *exportviewcontroller = (ExportMainTableViewController *)[storyboard instantiateInitialViewController];
        [navcontroller setViewControllers: @[exportviewcontroller]];
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            navcontroller.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        [weakself.mainvc presentViewController:navcontroller animated:YES completion:nil];
        [weakself hideLeftViewAnimated:weakself];
    }]];
    [options addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        options.popoverPresentationController.barButtonItem = sender;
        options.popoverPresentationController.sourceView = self.view;
    }
    
    [self
     presentViewController:options
     animated:YES
     completion:nil];
}

- (void)setMainViewController {
    static dispatch_once_t sidebarToken;
    dispatch_once(&sidebarToken, ^{
        self.mainvc = (MainViewController *)self.sideMenuController;
    });
}
@end
