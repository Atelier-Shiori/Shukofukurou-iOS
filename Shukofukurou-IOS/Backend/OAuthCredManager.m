//
//  OAuthCredManager.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 2/4/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "OAuthCredManager.h"
#import <AFNetworking/AFNetworking.h>
#import <SAMKeychain/SAMKeychain.h>

@implementation OAuthCredManager

#ifdef DEBUG
NSString *const kKitsuKeychainIdentifier = @"Shukofukurou - Kitsu DEBUG";
NSString *const kAniListKeychainIdentifier = @"Hiyoko - AniList DEBUG";
#else
NSString *const kKitsuKeychainIdentifier = @"Shukofukurou - Kitsu";
NSString *const kAniListKeychainIdentifier = @"Hiyoko - AniList";
#endif

+ (instancetype)sharedInstance {
    static OAuthCredManager *sharedManager = nil;
    static dispatch_once_t oauthcredmanagertoken;
    dispatch_once(&oauthcredmanagertoken, ^{
        sharedManager = [[OAuthCredManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    if ([super init]) {
        [self getFirstAccountForService:2];
        [self getFirstAccountForService:3];
    }
    return self;
}

- (AFOAuthCredential *)getFirstAccountForService:(int)service {
    NSString *keychainidentifier;
    switch (service) {
        case 2:
            if (_KitsuCredential) {
                return _KitsuCredential;
            }
            keychainidentifier = kKitsuKeychainIdentifier;
            break;
        case 3:
            if (_AniListCredential) {
                return _AniListCredential;
            }
            keychainidentifier = kAniListKeychainIdentifier;
            break;
        default:
            return [AFOAuthCredential new];
    }
    NSData *credData = [SAMKeychain passwordDataForService:@"Shukofukurou-IOS" account:keychainidentifier];
    AFOAuthCredential *cred = credData ? [self convertJsonDataToCredential:credData] : nil;
    //AFOAuthCredential *cred = [AFOAuthCredential retrieveCredentialWithIdentifier:keychainidentifier];
    if (cred) {
        switch (service) {
            case 2:
                _KitsuCredential = cred;
                return _KitsuCredential;
            case 3:
                _AniListCredential = cred;
                return _AniListCredential;
        }
    }
    return nil;
}

- (AFOAuthCredential *)saveCredentialForService:(int)service withCredential:(AFOAuthCredential *)cred {
    NSString *keychainidentifier;
    switch (service) {
        case 2:
            keychainidentifier = kKitsuKeychainIdentifier;
            break;
        case 3:
            keychainidentifier = kAniListKeychainIdentifier;
            break;
        default:
            return [AFOAuthCredential new];
    }
    [SAMKeychain setPasswordData:[self convertCredentialToJSONData:cred] forService:@"Shukofukurou-IOS" account:keychainidentifier];
    //[AFOAuthCredential storeCredential:cred withIdentifier:keychainidentifier];
    switch (service) {
        case 2:
            _KitsuCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:keychainidentifier];
            return _KitsuCredential;
        case 3:
            _AniListCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:keychainidentifier];
            return _AniListCredential;
    }
    return nil;
}

- (bool)removeCredentialForService:(int)service {
    NSString *keychainidentifier;
    switch (service) {
        case 2:
            keychainidentifier = kKitsuKeychainIdentifier;
            break;
        case 3:
            keychainidentifier = kAniListKeychainIdentifier;
            break;
        default:
            return false;
    }
    bool success = [SAMKeychain deletePasswordForService:@"Shukofukurou-IOS" account:keychainidentifier];
    //bool success = [AFOAuthCredential deleteCredentialWithIdentifier:keychainidentifier];
    switch (service) {
        case 2:
            _KitsuCredential = nil;
            break;
        case 3:
            _AniListCredential = nil;
            break;
    }
    return success;
}

- (NSData *)convertCredentialToJSONData:(AFOAuthCredential *)cred {
    NSMutableDictionary *userToken = [NSMutableDictionary new];
    userToken[@"access_token"] = cred.accessToken;
    userToken[@"refresh_token"] = cred.refreshToken;
    userToken[@"type"] = cred.tokenType;
    NSDate * expiration = [cred getExpirationDate];
    userToken[@"expiration"] = @(expiration.timeIntervalSince1970);
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userToken
                                                       options:(NSJSONWritingOptions)    (NSJSONWritingPrettyPrinted)
                                                         error:&error];
    if (!jsonData) {
        return nil;
    }
    return jsonData;
}

- (AFOAuthCredential *)convertJsonDataToCredential:(NSData *)jsonData {
    NSError *error;
    NSDictionary *userToken = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    AFOAuthCredential *cred = [[AFOAuthCredential alloc] initWithOAuthToken:userToken[@"access_token"] tokenType:userToken[@"type"]];
    NSDate *tokenExpireDate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)userToken[@"expiration"]).intValue];
    [cred setRefreshToken:userToken[@"refresh_token"] expiration:tokenExpireDate];
    return cred;
}
@end
