//
//  ScrobbleManager.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/19/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "ScrobbleManager.h"
#import "TitleSearch.h"
#import <MBProgressHUDFramework/MBProgressHUD.h>
#import "ViewControllerManager.h"
#import "TitleInfoCache.h"
#import "listservice.h"
#import "AtarashiiListCoreData.h"
#import "Utility.h"
#import "AnimeRelations.h"
#import "AppDelegate.h"
#import "ThemeManager.h"

@interface ScrobbleManager ()
@property (strong) MBProgressHUD *hud;
@property (strong) TitleSearch *search;
@property int titleid;
@property int episode;
@property (strong) NSDictionary *titleinformation;
@property (strong) UINavigationController *hudcontainingview;
@end

@implementation ScrobbleManager
+ (instancetype)sharedInstance {
    static ScrobbleManager *sharedManager = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        sharedManager = [ScrobbleManager new];
    });
    return sharedManager;
}
- (void)checkScrobble {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.moe.malupdaterosx.Shukofukurou-IOS.scrobbleextension"];
    NSDictionary *streamdata = [defaults valueForKey:@"streamdata"];
    if (streamdata) {
        NSLog(@"Scrobbling %@ - %@", streamdata[@"title"], streamdata[@"episode"]);
        [self showloadingview:YES withText:@"Scrobbling..."];
        [self performScrobble];
    }
}
- (void)performScrobble {
    _search = [TitleSearch new];
    [_search processScrobble:^(int titleid, int episode, bool success) {
        if (success) {
            [self getTitleInformation:titleid withCompletionHandler:^(NSDictionary *titleinfo, bool success) {
                if (success) {
                    self.titleid = titleid;
                    self.episode = episode;
                    self.titleinformation = titleinfo;
                    [self scrobbleConfirm];
                }
                else {
                    [self scrobbleFailed];
                }
            }];
        }
        else {
            [self scrobbleFailed];
        }
    }];
}

- (void)getTitleInformation:(int)titleid withCompletionHandler:(void (^)(NSDictionary *titleinfo, bool success)) completionHandler {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"]) {
        NSDictionary *titleinfo = [TitleInfoCache getTitleInfoWithTitleID:titleid withServiceID:[listservice.sharedInstance getCurrentServiceID] withType:0 ignoreLastUpdated:NO];
        if (titleinfo) {
            completionHandler(titleinfo, true);
            return;
        }
    }
    [listservice.sharedInstance retrieveTitleInfo:titleid withType:0 useAccount:NO completion:^(id responseObject) {
            if ([NSUserDefaults.standardUserDefaults boolForKey:@"cachetitleinfo"]) {
                [TitleInfoCache saveTitleInfoWithTitleID:titleid withServiceID:[listservice.sharedInstance getCurrentServiceID] withType:0 withResponseObject:responseObject];
            }
             completionHandler(responseObject,true);
    } error:^(NSError *error) {
        completionHandler(nil, false);
    }];
}

- (void)scrobbleConfirm {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Confirm Scrobble" message:[NSString stringWithFormat:@"Do you want to scrobble %@ Episode %i?", _titleinformation[@"title"], _episode] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performListUpdate];
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self clearScrobble];
    }];
    [alertcontroller addAction:noaction];
    [alertcontroller addAction:yesaction];
    [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)performListUpdate {
    // Retrieve Entry
    NSDictionary *entry = [AtarashiiListCoreData retrieveSingleEntryForTitleID:_titleid withService:[listservice.sharedInstance getCurrentServiceID] withType:0];
    bool exists = false;
    bool rewatching = false;
    int entryid = 0;
    NSString *watchstatus;
    NSString *airingstatus = _titleinformation[@"status"];
    bool selectedaircompleted;
    bool selectedaired;
    int score = 0;
    if ([airingstatus isEqualToString:@"finished airing"]) {
        selectedaircompleted = true;
    }
    else {
        selectedaircompleted = false;
    }
    if ([airingstatus isEqualToString:@"finished airing"]||[airingstatus isEqualToString:@"currently airing"]) {
        selectedaired = true;
    }
    else {
        selectedaired = false;
    }
    int totalepisodes = ((NSNumber *)_titleinformation[@"episodes"]).intValue;
    if (entry) {
        exists = true;
        entryid = ((NSNumber *)entry[@"entryid"]).intValue;
        watchstatus = entry[@"watched_status"];
        rewatching = ((NSNumber *)entry[@"rewatching"]).boolValue;
        score =((NSNumber *)entry[@"score"]).intValue;
        if (((NSNumber *)entry[@"watched_episodes"]).intValue == self.episode) {
            [self scrobbleSameEpisode];
            return;
        }
    }
    else {
        watchstatus = @"watching";
    }
    if (![watchstatus isEqual:@"completed"] && (_episode == totalepisodes && totalepisodes > 0)) {
        watchstatus = @"completed";
        rewatching = false;
    }
    if (_episode == totalepisodes && totalepisodes != 0 && selectedaircompleted && selectedaired) {
        watchstatus = @"completed";
        _episode = totalepisodes;
    }
    if (exists) {
        [self updateEntryWithEntryID:entryid withStatus:watchstatus withRewatch:rewatching withScore:score];
    }
    else {
        [self addEntrywithStatus:watchstatus];
    }
}
- (void)addEntrywithStatus:(NSString *)status {
    [listservice.sharedInstance addAnimeTitleToList:_titleid withEpisode:_episode withStatus:status withScore:0 completion:^(id responseObject) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"AnimeRefreshList" object:nil];
        [self scrobbleSuccessful];
    } error:^(NSError *error) {
        [self scrobbleUpdateFailed];
    }];
}

- (void)updateEntryWithEntryID:(int)entryid withStatus:(NSString *)status withRewatch:(bool)rewatching withScore:(int)score {
    NSDictionary * extraparameters = @{};
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 2:
        case 3: {
            extraparameters = @{@"reconsuming" : @(rewatching)};
            break;
        }
        default:
            break;
    }
    [listservice.sharedInstance updateAnimeTitleOnList:entryid withEpisode:_episode withStatus:status withScore:score withExtraFields:extraparameters completion:^(id responseObject) {
        NSDictionary *updatedfields = @{@"watched_episodes" : @(self.episode), @"watched_status" : status, @"score" : @(score), @"rewatching" : @(rewatching), @"last_updated" : [Utility getLastUpdatedDateWithResponseObject:responseObject withService:[listservice.sharedInstance getCurrentServiceID]]};
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserName:[listservice.sharedInstance getCurrentServiceUsername] withService:[listservice.sharedInstance getCurrentServiceID] withType:0 withId:self.titleid withIdType:0];
                break;
            case 2:
            case 3:
                [AtarashiiListCoreData updateSingleEntry:updatedfields withUserId:[listservice.sharedInstance getCurrentUserID] withService:[listservice.sharedInstance getCurrentServiceID] withType:0 withId:entryid withIdType:1];
                break;
        }
        [NSNotificationCenter.defaultCenter postNotificationName:@"AnimeReloadList" object:nil];
        [NSNotificationCenter.defaultCenter postNotificationName:@"EntryUpdated" object:@{@"type" : @(0), @"id": @(self.titleid)}];
        [self scrobbleSuccessful];
    } error:^(NSError *error) {
        [self scrobbleUpdateFailed];
    }];
}
- (void)scrobbleFailed {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Scrobble Failed." message:@"Could not find a match." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self clearScrobble];
    }];
    [alertcontroller addAction:okaction];
    [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)scrobbleSameEpisode {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Same Episode." message:@"Episode progress is the same, thus the entry was not updated." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self clearScrobble];
    }];
    [alertcontroller addAction:okaction];
    [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)scrobbleUpdateFailed {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Scrobble Failed." message:@"Could not update list. Try again later" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       [MBProgressHUD hideHUDForView:[ViewControllerManager getAppDelegateViewControllerManager].mvc.rootViewContainer animated:YES];
    }];
    [alertcontroller addAction:okaction];
    [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)scrobbleSuccessful {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Scrobble Successful." message:[NSString stringWithFormat:@"Scrobble of %@ Episode %i was successful.", _titleinformation[@"title"], _episode] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self clearScrobble];
    }];
    [alertcontroller addAction:okaction];
    [[ViewControllerManager getAppDelegateViewControllerManager].mvc presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)showloadingview:(bool)show withText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (show) {
            self.hudcontainingview = [[ViewControllerManager getAppDelegateViewControllerManager].mvc currentRootView];
            if (self.hudcontainingview) {
                self.hud = [MBProgressHUD showHUDAddedTo:self.hudcontainingview.view animated:YES];
                self.hud.label.text = text;
                self.hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
                self.hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
            }
        }
        else {
            if (self.hudcontainingview) {
                [self.hud hideAnimated:YES];
                [MBProgressHUD hideHUDForView:self.hudcontainingview.view animated:YES];
                self.hudcontainingview = nil;
            }
        }
    });
}

- (void)clearScrobble {
    [self showloadingview:NO withText:@""];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.moe.malupdaterosx.Shukofukurou-IOS.scrobbleextension"];
    [defaults setValue:nil forKey:@"streamdata"];
    [defaults synchronize];
}

- (void)clearScrobbleCache {
    NSManagedObjectContext *moc = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
    [moc performBlockAndWait:^{
        NSFetchRequest *allCaches = [[NSFetchRequest alloc] init];
        allCaches.entity = [NSEntityDescription entityForName:@"ScrobbleCache" inManagedObjectContext:moc];
        NSError *error = nil;
        NSArray *cache = [moc executeFetchRequest:allCaches error:&error];
        for (NSManagedObject *obj in cache) {
            [moc deleteObject:obj];
        }
        [moc save:&error];
    }];
}
@end
