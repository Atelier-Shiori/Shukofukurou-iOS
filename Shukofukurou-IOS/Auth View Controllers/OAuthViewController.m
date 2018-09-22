//
//  OAuthViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/15.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "OAuthViewController.h"
#import "listservice.h"
#import "AuthWebView.h"
#import "AppDelegate.h"
#import "OnePasswordExtension.h"

@interface OAuthViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelbtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *onepasswordSigninButton;
@property (strong)AuthWebView *authwebview;
@end

@implementation OAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    _authwebview = [AuthWebView new];
    __weak OAuthViewController *weakSelf = self;
    _authwebview.completion = ^(NSString *pin) {
        weakSelf.cancelbtn.enabled = false;
        [listservice verifyAccountWithUsername:@"" password:pin withServiceID:[listservice getCurrentServiceID] completion:^(id responseObject) {
            // Callback
            switch ([listservice getCurrentServiceID]) {
                case 3:
                    [NSUserDefaults.standardUserDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:259200] forKey:@"anilist-userinformationrefresh"];
                    break;
            }
            // Call delegate
            [weakSelf.delegate authSuccessful:[listservice getCurrentServiceID]];
            // Dismiss modal
            weakSelf.cancelbtn.enabled = true;
            [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } error:^(NSError *error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OAuth Failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                weakSelf.cancelbtn.enabled = true;
                [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }];
            [alert addAction:defaultAction];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }];
    };
    self.title = [NSString stringWithFormat:@"Authorize %@", [listservice currentservicename]];
    CGRect frame = _oauthviewcontainer.frame;
    frame.origin.y = 0;
    _authwebview.view.frame = frame;
    //[_authwebview.view setFrameOrigin:CGPointZero];
    [_oauthviewcontainer  addSubview:_authwebview.view];
    [self.onepasswordSigninButton setEnabled:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)cancel:(id)sender {
    [_authwebview resetWebView];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)fillUsing1Password:(id)sender {
    [[OnePasswordExtension sharedExtension] fillItemIntoWebView:self.authwebview.webView forViewController:self sender:sender showOnlyLogins:NO completion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Failed to fill into webview: <%@>", error);
        }
    }];
}

@end
