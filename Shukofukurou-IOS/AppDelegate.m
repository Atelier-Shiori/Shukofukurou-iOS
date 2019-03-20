//
//  AppDelegate.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AppDelegate.h"
#import "listservice.h"
#import "AutoRefreshTimer.h"
#import "StreamDataRetriever.h"
#import "AiringSchedule.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ThemeManager.h"
#import <Hakuchou_iOS/OAuthCredManager.h>
#import "ScrobbleManager.h"

@interface AppDelegate ()
@property (strong) AutoRefreshTimer *autorefresh;
@end

@implementation AppDelegate

+ (void)initialize {
    //Create a Dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    defaultValues[@"selectedmainview"] = @"anime-list";
    defaultValues[@"refreshlistonstart"] = @(0);
    defaultValues[@"refreshautomatically"] = @(1);
    defaultValues[@"donated"] = @(1);
    defaultValues[@"NSApplicationCrashOnExceptions"] = @YES;
    defaultValues[@"stream_region"] = @(0);
    defaultValues[@"currentservice"] = @(3);
    defaultValues[@"seasonselect"] = @"Winter";
    defaultValues[@"selectedsearchtype"] = @(0);
    defaultValues[@"cachetitleinfo"] = @YES;
    defaultValues[@"selectedtrendtype"] = @(0);
    defaultValues[@"airnotificationsenabled"] = @NO;
    defaultValues[@"airingnotification_service"] = @(3);
    defaultValues[@"darkmode"] = @NO;
    // Viewed List
    defaultValues[@"myanimelist-selectedanimelist"] = @"watching";
    defaultValues[@"myanimelist-selectedmangalist"] = @"reading";
    defaultValues[@"kitsu-selectedanimelist"] = @"watching";
    defaultValues[@"kitsu-selectedmangalist"] = @"reading";
    defaultValues[@"anilist-selectedanimelist"] = @"watching";
    defaultValues[@"anilist-selectedmangalist"] = @"reading";
    defaultValues[@"anilist-selectedlistcustomlistanime"] = @NO;
    defaultValues[@"anilist-selectedlistcustomlistmanga"] = @NO;
    // Library Sort
    defaultValues[@"anime-sortby"] = @"Title";
    defaultValues[@"anime-accending"] = @YES;
    defaultValues[@"manga-sortby"] = @"Title";
    defaultValues[@"manga-accending"] = @YES;
    [[NSUserDefaults standardUserDefaults]
     registerDefaults:defaultValues];
}


- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"Fetch Started");
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [AiringSchedule autofetchAiringScheduleWithCompletionHandler:^(bool success, bool refreshed) {
        if (success) {
            if ([NSUserDefaults.standardUserDefaults boolForKey:@"refreshautomatically"] && [listservice.sharedInstance checkAccountForCurrentService]) {
                if (![defaults valueForKey:@"nextlistrefresh"] || ((NSDate *)[defaults valueForKey:@"nextlistrefresh"]).timeIntervalSinceNow < 0) {
                    [[self.vcmanager getAnimeListRootViewController].lvc refreshListWithCompletionHandler:^(bool success) {
                        if (success) {
                            [[self.vcmanager getMangaListRootViewController].lvc refreshListWithCompletionHandler:^(bool success) {
                                if (success) {
                                    NSLog(@"New Data");
                                    [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*15] forKey:@"nextlistrefresh"];
                                    completionHandler(UIBackgroundFetchResultNewData);
                                }
                                else {
                                    NSLog(@"Fetch Failed");
                                    completionHandler(UIBackgroundFetchResultFailed);
                                }
                            }];
                        }
                        else {
                            NSLog(@"Fetch Failed");
                            completionHandler(UIBackgroundFetchResultFailed);
                        }
                    }];
                }
                else if (refreshed) {
                    NSLog(@"New Data");
                    completionHandler(UIBackgroundFetchResultNewData);
                }
                else {
                    NSLog(@"No Data");
                    completionHandler(UIBackgroundFetchResultNoData);
                }
            }
            else if (refreshed) {
                NSLog(@"New Data");
                completionHandler(UIBackgroundFetchResultNewData);
            }
            else {
                NSLog(@"No Data");
                completionHandler(UIBackgroundFetchResultNoData);
            }
        }
        else {
            NSLog(@"Fetch Failed");
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"FixKeychainItems"]) {
        [[OAuthCredManager sharedInstance] fixkeychainaccessability];
    }
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"LoadTheme" object:nil];
    // Override point for customization after application launch.
    [self checkaccountinformation];
    [self storeCurrentServicetoAppGroup];
    _autorefresh = [AutoRefreshTimer new];
    [StreamDataRetriever retrieveStreamData];
    _airingnotificationmanager = [AiringNotificationManager new];
    // Set Background Fetch
    [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    // Set Image Disk Cache Size
    SDImageCache.sharedImageCache.config.maxCacheSize = 1000000 * 96;
    return YES;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)loadtheme {
    if (!_tmanager) {
        _tmanager = [ThemeManager new];
    }
    [_tmanager setTheme];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"LoadTheme"]) {
        [self loadtheme];
    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    [_vcmanager.mvc hidetoolbarstate];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [_autorefresh pauseTimer];
    [_vcmanager.mvc hidetoolbarstate];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    [_autorefresh resumeTimer];
    [_vcmanager.mvc hidetoolbarstate];
    [_vcmanager.mvc showtoolbarstate];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [_vcmanager.mvc hidetoolbarstate];
    [_vcmanager.mvc showtoolbarstate];
    [ScrobbleManager.sharedInstance checkScrobble];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;
- (NSManagedObjectContext *)managedObjectContext {
    return self.persistentContainer.viewContext;
}
- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"Hiyoko"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

#pragma mark other
- (ViewControllerManager *)getvcmanager {
    if (!_vcmanager) {
        _vcmanager = [ViewControllerManager new];
    }
    return _vcmanager;
}

- (void)checkaccountinformation {
    // Retrieves updated user data
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    bool reloadeduserdata = false;
    if ([listservice.sharedInstance .kitsuManager getFirstAccount]) {
        bool refreshKitsu = (![defaults valueForKey:@"kitsu-userinformationrefresh"] || ((NSDate *)[defaults objectForKey:@"kitsu-userinformationrefresh"]).timeIntervalSinceNow < 0);
        if ((![defaults valueForKey:@"kitsu-username"] && ![defaults valueForKey:@"kitsu-userid"]) || ((NSString *)[defaults valueForKey:@"kitsu-username"]).length == 0 || refreshKitsu) {
            [listservice.sharedInstance .kitsuManager saveuserinfoforcurrenttoken];
            [NSUserDefaults.standardUserDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:259200] forKey:@"kitsu-userinformationrefresh"];
            reloadeduserdata = true;
        }
    }
    if ([listservice.sharedInstance .anilistManager getFirstAccount]) {
        bool refreshAniList = (![defaults valueForKey:@"anilist-userinformationrefresh"] || ((NSDate *)[defaults objectForKey:@"anilist-userinformationrefresh"]).timeIntervalSinceNow < 0);
        if ((![defaults valueForKey:@"anilist-username"] || ![defaults valueForKey:@"anilist-userid"]) || ((NSString *)[defaults valueForKey:@"anilist-username"]).length == 0 || refreshAniList) {
            [listservice.sharedInstance .anilistManager saveuserinfoforcurrenttoken];
            [NSUserDefaults.standardUserDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:259200] forKey:@"anilist-userinformationrefresh"];
             reloadeduserdata = true;
        }
    }
    if (reloadeduserdata) {
        // Reload user data on sidebar
        [_vcmanager.mainsidebar setLoggedinUser];
    }
}

#pragma mark AuthViewController Delegate
- (void)authSuccessful:(int)service {
    // Login Prep
    __weak AppDelegate *weakSelf = self;
    [_vcmanager.mainsidebar setLoggedinUser];
    [_vcmanager.getAnimeListRootViewController.lvc retrieveList:YES completion:^(bool success) {
        if (success) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"UserLoggedIn" object:weakSelf.vcmanager.getAnimeListRootViewController.lvc];
        }
    }];
    [_vcmanager.getMangaListRootViewController.lvc retrieveList:YES completion:^(bool success) {
        if (success) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"UserLoggedIn" object:weakSelf.vcmanager.getMangaListRootViewController.lvc];
        }
    }];
    [_vcmanager.mvc loadfromdefaults];
    [_vcmanager.mvc showtoolbarstate];
}
- (void)authCanceled {
    NSLog(@"Auth canceled!");
    [_vcmanager.mvc showtoolbarstate];
}

#pragma mark ServiceSwitcherView Delegate
- (void)listserviceDidChange:(int)oldservice newService:(int)newservice {
    NSLog(@"New Service: %i oldserivce: %i", newservice, oldservice);
    [_vcmanager.mainsidebar setLoggedinUser];
    [_vcmanager.mvc loadfromdefaults];
    [self storeCurrentServicetoAppGroup];
    [NSNotificationCenter.defaultCenter postNotificationName:@"ServiceChanged" object:nil];
}

#pragma mark MainSideBarView Delegate
- (void)accountRemovedForService:(int)service {
    NSLog(@"Logged out of: %i", service);
    if (service == 3) {
        // Reset Selected List for AniList
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        if ([defaults boolForKey:@"anilist-selectedlistcustomlistanime"]) {
            [defaults setValue:@"watching" forKey:@"anilist-selectedanimelist"];
            [defaults setBool:NO forKey:@"anilist-selectedlistcustomlistanime"];
        }
        if ([defaults boolForKey:@"anilist-selectedlistcustomlistmanga"]) {
            [defaults setValue:@"reading" forKey:@"anilist-selectedmangalist"];
            [defaults setBool:NO forKey:@"anilist-selectedlistcustomlistmanga"];
        }
    }
    [_vcmanager.getAnimeListRootViewController.lvc clearlists];
    [_vcmanager.getMangaListRootViewController.lvc clearlists];
    [_vcmanager.mvc loadfromdefaults];
    [self storeCurrentServicetoAppGroup];
    [NSNotificationCenter.defaultCenter postNotificationName:@"UserLoggedOut" object:nil];
}

- (void)storeCurrentServicetoAppGroup {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.moe.malupdaterosx.Shukofukurou-IOS.scrobbleextension"];
    [defaults setInteger:[listservice.sharedInstance getCurrentServiceID] forKey:@"currentservice"];
    [defaults setBool:[listservice.sharedInstance checkAccountForCurrentService] forKey:@"currentserviceloggedin"];
    [defaults synchronize];
}

@end
