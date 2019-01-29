//
//  ViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ViewController.h"
#import "ViewControllerManager.h"
#import "ThemeManager.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sidebarShowAlwaysNotification:) name:@"sidebarStateDidChange" object:nil];
    [self hidemenubtn];
    [self setTheme];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setTheme];
}

- (void)sidebarShowAlwaysNotification:(NSNotification *)notification {
    [self hidemenubtn];
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
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender {
    ViewControllerManager *vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    [vcm.mainsidebar performLogin];
}

- (void)setTheme {
    ThemeManagerTheme *theme = [ThemeManager sharedCurrentTheme];
    bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
    self.view.backgroundColor = darkmode ? theme.viewAltBackgroundColor : theme.viewBackgroundColor;
}

@end
