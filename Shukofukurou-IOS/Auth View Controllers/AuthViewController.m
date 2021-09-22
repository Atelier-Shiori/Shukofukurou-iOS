//
//  AuthViewController.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/09/04.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AuthViewController.h"
#import "ListService.h"
#import "AppDelegate.h"

@interface AuthViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loginbtn;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelbtn;
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@end

@implementation AuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        self.delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 2:
            self.navigationItem.title = @"Kitsu Login";
            break;
    }
    self.username.textContentType = UITextContentTypeUsername;
    self.password.textContentType = UITextContentTypePassword;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)login:(id)sender {
    if (_username.text.length == 0 || _password.text.length == 0) {
        [self showAlertMessage:@"Username and Password required." withExplaination:@"To log in, you need to specify a username or password"];
    }
    else {
        _loginbtn.enabled = false;
        _cancelbtn.enabled = false;
        [self performLogin];
    }
}
- (void)performLogin {
    [listservice.sharedInstance verifyAccountWithUsername:_username.text password:_password.text withServiceID:[listservice.sharedInstance getCurrentServiceID] completion:^(id responseObject) {
        // Callback
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 2:
                [NSUserDefaults.standardUserDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:259200] forKey:@"kitsu-userinformationrefresh"];
                break;
        }
        self.loginbtn.enabled = true;
        self.cancelbtn.enabled = true;
        [self.delegate authSuccessful:[listservice.sharedInstance getCurrentServiceID]];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } error:^(NSError *error) {
            if ([[error.userInfo valueForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: unauthorized (401)"]) {
                [self showAlertMessage:[NSString stringWithFormat:@"Unable to login to %@", [listservice.sharedInstance currentservicename]] withExplaination:@"Username or password is incorrect, please try again."];
            }
            else {
                [self showAlertMessage:[NSString stringWithFormat:@"Unable to login to %@ due to a unknown error.", [listservice.sharedInstance currentservicename]] withExplaination:error.localizedDescription];
            }
        self.loginbtn.enabled = true;
        self.cancelbtn.enabled = true;
    }];
}
- (IBAction)cancel:(id)sender {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)registeraccount:(id)sender {
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 2:
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://kitsu.io/"] options:@{} completionHandler:^(BOOL success) {}];
            break;
            
        default:
            break;
    }
}
- (void)showAlertMessage:(NSString *)message withExplaination:(NSString *)explaination {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:message message:explaination preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
