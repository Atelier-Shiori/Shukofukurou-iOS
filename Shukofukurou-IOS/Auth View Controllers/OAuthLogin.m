//
//  OAuthLogin.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/8/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AppDelegate.h"
#import "OAuthLogin.h"
#import "ClientConstants.h"
#import "listservice.h"
#import "ViewControllerManager.h"
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_12_0
#import <AuthenticationServices/AuthenticationServices.h>
#endif
#import <SafariServices/SafariServices.h>
@interface OAuthLogin ()
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_12_0
@property (nonatomic) ASWebAuthenticationSession *session;
#else
@property (nonatomic) SFAuthenticationSession *session;
#endif
@end

@implementation OAuthLogin
- (instancetype)init {
    if (self = [super init]) {
        self.delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    }
    return self;
}

- (void)startAniListOAuthSession {
    if (@available (iOS 12, *)) {
        self.session = [[ASWebAuthenticationSession alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://anilist.co/api/v2/oauth/authorize?client_id=%@&response_type=code",kanilistclient]] callbackURLScheme:@"hiyokoauth://" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
            if (!error) {
                [self performAniListOAuthWithCallBackURL:callbackURL];
            }
            else {
                if (error.code == ASWebAuthenticationSessionErrorCodeCanceledLogin) {
                    [self.delegate authCanceled];
                }
            }
        }];
    }
    else {
        self.session = [[SFAuthenticationSession alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://anilist.co/api/v2/oauth/authorize?client_id=%@&response_type=code",kanilistclient]] callbackURLScheme:@"hiyokoauth://" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
            if (!error) {
                [self performAniListOAuthWithCallBackURL:callbackURL];
            }
            else {
                if (error.code == SFAuthenticationErrorCanceledLogin) {
                    [self.delegate authCanceled];
                }
            }
            }];
    }
    [self.session start];
}

- (void)performAniListOAuthWithCallBackURL:(NSURL *)callbackURL {
    NSString *pin = [callbackURL.absoluteString stringByReplacingOccurrencesOfString:@"hiyokoauth://anilistauth/?code=" withString:@""];
    [listservice.sharedInstance verifyAccountWithUsername:@"" password:pin withServiceID:[listservice.sharedInstance getCurrentServiceID] completion:^(id responseObject) {
        // Callback
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 3:
                [NSUserDefaults.standardUserDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:259200] forKey:@"anilist-userinformationrefresh"];
                break;
        }
        // Call delegate
        [self.delegate authSuccessful:[listservice.sharedInstance getCurrentServiceID]];
    } error:^(NSError *error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OAuth Failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:defaultAction];
        [ViewControllerManager.getAppDelegateViewControllerManager.mvc presentViewController:alert animated:YES completion:nil];
    }];
}
@end
