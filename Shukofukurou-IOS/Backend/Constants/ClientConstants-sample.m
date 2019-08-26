//
//  ClientConstants.m
//  MAL Library
//
//  Created by アナスタシア on 2017/09/09.
//  Copyright © 2017年 Atelier Shiori. All rights reserved.
//

#import "ClientConstants.h"

@implementation ClientConstants
    //
    // These constants specify the secret and client key for MyAnimeList
    // You can obtain them at
    //
    NSString *const kMALClient = @"";
    NSString *const kMALRedirectURL = @"hiyokoauth://malauth/";

    //
    // These constants specify the secret and client key for Kitsu
    // You can obtain them at
    //
    NSString *const kKitsuBaseURL = @"https://kitsu.io/api/";
    NSString *const kKitsuAuthURL = @"oauth/authorize";
    NSString *const kKitsuTokenURL = @"oauth/token";
    NSString *const kKitsusecretkey = @"";
    NSString *const kKitsuClient = @"";

    //
    // These constants specify the secret and client key for AniList
    // You can obtain them at https://anilist.co/settings/developer/client/
    //
    NSString *const kanilistsecretkey = @"";
    NSString *const kanlistclient =@"";
@end
