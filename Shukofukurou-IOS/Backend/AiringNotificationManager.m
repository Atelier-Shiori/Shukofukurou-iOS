//
//  AiringNotificationManager.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/7/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AiringNotificationManager.h"
#import "TitleIdEnumerator.h"
#import "AppDelegate.h"
#import "AtarashiiListCoreData.h"
#import "listservice.h"
#import <Hakuchou_iOS/AniListConstants.h>
#import "Utility.h"
#import <AFNetworking/AFNetworking.h>

@import UserNotifications;

@interface AiringNotificationManager ()
@property (strong) UNUserNotificationCenter *notificationCenter;
@property (strong) NSMutableArray *schedulednotifications;
@end

@implementation AiringNotificationManager
+ (AiringNotificationManager *)sharedAiringNotificationManager {
    return ((AppDelegate *)UIApplication.sharedApplication.delegate).airingnotificationmanager;
}

+ (int)airingNotificationServiceSource {
    return (int)[NSUserDefaults.standardUserDefaults integerForKey:@"airingnotification_service"];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (instancetype) init {
    if (self = [super init]) {
        self.managedObjectContext = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
        self.notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"AirNotifyServiceChanged" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"AirNotifyToggled" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"UserLoggedOut" object:nil];
        self.schedulednotifications = [NSMutableArray new];
    }
    return self;
}

- (void)receiveNotification:(NSNotification *)notification {
    int service = [AiringNotificationManager airingNotificationServiceSource];
    if ([notification.name isEqualToString:@"AirNotifyServiceChanged"]) {
        [self clearNotifyList];
        [self checknotifications:^(bool success) {}];
    }
    else if ([notification.name isEqualToString:@"AirNotifyToggled"]) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"airnotificationsenabled"]) {
            [self checknotifications:^(bool success) {}];
        }
        else {
            [self clearNotifyList];
        }
    }
    else if ([notification.name isEqualToString:@"UserLoggedOut"]) {
        if (service == [listservice.sharedInstance getCurrentServiceID]) {
            [self clearNotifyList];
        }
    }
}

- (void)checknotifications:(void (^)(bool success))completionHandler {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"airnotificationsenabled"]) {
        [self checkListForAiringTitles:^(bool success) {
            if (success) {
                [self checkForNewNotifications:^(bool success) {
                    if (success) {
                        completionHandler(true);
                    }
                    else {
                        completionHandler(false);
                    }
                }];
            }
            else {
                completionHandler(false);
            }
        }];
    }
    else {
        completionHandler(true);
    }
}

- (void)checkListForAiringTitles:(void (^)(bool success))completionHandler {
    NSLog(@"Checking for new airing titles");
    __block int service = [AiringNotificationManager airingNotificationServiceSource];
    NSArray *list;
    switch (service) {
        case 1: {
            NSDictionary *uiddict = [listservice.sharedInstance getAllUserID];
            int uid = 0;
            if (uiddict[@"myanimelist"] != [NSNull null]) {
                uid = ((NSNumber *)uiddict[@"myanimelist"]).intValue;
            }
            else {
                return;
            }
            list = [AtarashiiListCoreData retrieveEntriesForUserId:uid withService:1 withType:0 withPredicate:[NSPredicate predicateWithFormat:@"status ==[c] %@ AND (watched_status ==[c] %@ OR watched_status ==[c] %@)", @"currently airing", @"watching", @"plan to watch"]];
            break;
        }
        case 2:
        case 3: {
            NSDictionary *uiddict = [listservice.sharedInstance getAllUserID];
            int uid = 0;
            switch (service) {
                case 2: {
                    if (uiddict[@"kitsu"] != [NSNull null]) {
                        uid = ((NSNumber *)uiddict[@"kitsu"]).intValue;
                        break;
                    }
                    return;
                }
                case 3: {
                    if (uiddict[@"anilist"] != [NSNull null]) {
                        uid = ((NSNumber *)uiddict[@"anilist"]).intValue;
                        break;
                    }
                    return;
                }
                default:
                    return;
            }
            list = [AtarashiiListCoreData retrieveEntriesForUserId:uid withService:service withType:0 withPredicate:[NSPredicate predicateWithFormat:@"status ==[c] %@ AND (watched_status ==[c] %@ OR watched_status ==[c] %@)", @"currently airing", @"watching", @"plan to watch"]];
            break;
        }
        default: {
            return;
        }
    }
    TitleIdEnumerator *tenum = [[TitleIdEnumerator alloc] initWithList:list withType:0 completion:^(TitleIdEnumerator * _Nonnull titleidenum) {
        NSLog(@"Adding New Entries");
        for (NSDictionary *entry in list) {
            int anilistid = [titleidenum findTargetIdFromSourceId:((NSNumber *)entry[@"id"]).intValue];
            if (![self retrieveNotificationItem:anilistid isAniListID:YES withService:service] && anilistid > 0) {
                    [self addNotifyingTitle:entry withAniListID:anilistid withService:service];
            }
            else if (![self retrieveIgnoredNotificationItem:((NSNumber *)entry[@"id"]).intValue withService:service] && anilistid == 0) {
                    [self addIgnoreNotifyingTitle:entry withService:service];
            }
        }
        completionHandler(true);
    }];
    [tenum generateTitleIdMappingList:service toService:3];
}

- (void)checkForNewNotifications:(void (^)(bool success))completionHandler {
    NSLog(@"Checking for new notifications");
    [self performNewNotificationCheck:[self getAllNotifications:YES] withPosition:0 completionHandler:completionHandler];
}

- (void)performNewNotificationCheck:(NSArray *)notificationList withPosition:(int)position completionHandler:(void (^)(bool success))completionHandler {
    if (notificationList.count == 0) {
        completionHandler(true);
        return;
    }
    AFHTTPSessionManager *sessionmanager = [Utility jsonmanager];
    __block NSManagedObjectContext *notifyobj = notificationList[position];
    if ([notifyobj valueForKey:@"nextairdate"] != [NSNull null] && [notifyobj valueForKey:@"nextairdate"]) {
        if ([(NSDate *)[notifyobj valueForKey:@"nextairdate"] timeIntervalSinceNow] > 0) {
            if (notificationList.count == position+1) {
                [self setNotifications];
                completionHandler(true);
            }
            else {
                int newPosition = position + 1;
                [self performNewNotificationCheck:notificationList withPosition:newPosition completionHandler:completionHandler];
            }
            return;
        }
    }
    if ([notifyobj valueForKey:@"anilistid"] == [NSNull null] || ![notifyobj valueForKey:@"anilistid"]) {
        if (notificationList.count == position+1) {
            [self setNotifications];
            completionHandler(true);
        }
        else {
            int newPosition = position + 1;
            [self performNewNotificationCheck:notificationList withPosition:newPosition completionHandler:completionHandler];
        }
        return;
    }
    NSDictionary *parameters = @{@"query" : kAniListNextEpisode, @"variables" : @{@"id": (NSNumber *)[notifyobj valueForKey:@"anilistid"]}};
    [sessionmanager POST:@"https://graphql.anilist.co/" parameters:parameters headers:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.managedObjectContext performBlockAndWait:^{
            NSDictionary *animeinfo = responseObject[@"data"][@"Media"];
            bool finished = [(NSString *)animeinfo[@"status"] isEqualToString:@"FINISHED"] || [(NSString *)animeinfo[@"status"] isEqualToString:@"CANCELLED"];
            [notifyobj setValue:@(finished) forKey:@"finished"];
            [notifyobj setValue:animeinfo[@"nextAiringEpisode"] != [NSNull null] ? [NSDate dateWithTimeIntervalSince1970:((NSNumber *)animeinfo[@"nextAiringEpisode"][@"airingAt"]).longValue] : nil forKey:@"nextairdate"];
            [notifyobj setValue:animeinfo[@"nextAiringEpisode"] != [NSNull null] ? animeinfo[@"nextAiringEpisode"][@"episode"] : @(0) forKey:@"nextepisode"];
            [self.managedObjectContext save:nil];
        }];
        if (notificationList.count == position+1) {
            [self setNotifications];
            completionHandler(true);
        }
        else {
            int newPosition = position + 1;
            [self performNewNotificationCheck:notificationList withPosition:newPosition completionHandler:completionHandler];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Unable to retrieve next airing date: %@", error);
        completionHandler(false);
    }];
}

- (void)setNotifications {
    NSArray *notifications = [self getAllNotifications:NO];
    [self generatePendingNotificationsList:^(bool success) {
        for (NSManagedObject *notifyobj in notifications) {
            bool hasAirDate = [notifyobj valueForKey:@"nextairdate"] != [NSNull null];
            bool scheduled = [self checkTitleIdIfPending:((NSNumber *)[notifyobj valueForKey:@"anilistid"]).intValue];
            if (hasAirDate && !scheduled) {
                [self setNotification:notifyobj];
            }
        }
        [self cleanupFinishedTitles];
    }];
}

- (void)setNotification:(NSManagedObject *)notificationobj {
    if ([notificationobj valueForKey:@"nextairdate"] != [NSNull null] && [notificationobj valueForKey:@"anilistid"] && [notificationobj valueForKey:@"servicetitleid"]) {
        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
        content.title = [notificationobj valueForKey:@"title"];
        content.body = [NSString stringWithFormat:@"Episode %@ has aired.", [notificationobj valueForKey:@"nextepisode"]];
        content.sound = [UNNotificationSound defaultSound];
        content.userInfo = @{@"anilistid" : [notificationobj valueForKey:@"anilistid"], @"servicetitleid" : [notificationobj valueForKey:@"servicetitleid"], @"service" : [notificationobj valueForKey:@"service"]};
        NSDate *airdate = (NSDate *)[notificationobj valueForKey:@"nextairdate"];
        if (airdate) {
            NSDateComponents *triggerDate = [[NSCalendar currentCalendar]
                                             components:NSCalendarUnitYear +
                                             NSCalendarUnitMonth + NSCalendarUnitDay +
                                             NSCalendarUnitHour + NSCalendarUnitMinute +
                                             NSCalendarUnitSecond fromDate:airdate];
            UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:triggerDate
                                                                                                              repeats:NO];
            NSString *identifier = [NSString stringWithFormat:@"airing-%@",[notificationobj valueForKey:@"anilistid"]];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                            content:content
                                                                                  trigger:trigger];
            [_notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error != nil) {
                    NSLog(@"Something went wrong: %@",error);
                }
                else {
                    NSLog(@"Successfully scheduled notification: %@", identifier);
                }
            }];
        }
        else {
            NSLog(@"Something went wrong: Invalid Air Date");
        }
    }
    else {
        NSLog(@"Skipping %@, No Air Date and Time", [notificationobj valueForKey:@"anilistid"]);
    }
    
}

- (void)removependingnotification:(int)anilistid {
    NSLog(@"Removed from Notification Queue: %i", anilistid);
    [_notificationCenter removePendingNotificationRequestsWithIdentifiers:@[[NSString stringWithFormat:@"airing-%i",anilistid]]];
}

- (void)addNotifyingTitle:(NSDictionary *)titleInfo withAniListID:(int)anilistid withService:(int)service {
    [_managedObjectContext performBlockAndWait:^{
        NSManagedObject *notifyobj = [self retrieveNotificationItem:anilistid isAniListID:YES withService:service];
        if (!notifyobj) {
            notifyobj = [NSEntityDescription insertNewObjectForEntityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        }
        [notifyobj setValue:@(anilistid) forKey:@"anilistid"];
        [notifyobj setValue:@(service) forKey:@"service"];
        [notifyobj setValue:titleInfo[@"id"] forKey:@"servicetitleid"];
        [notifyobj setValue:titleInfo[@"title"] forKey:@"title"];
        [notifyobj setValue:@YES forKey:@"enabled"];
        [notifyobj setValue:@NO forKey:@"finished"];
        [self.managedObjectContext save:nil];
    }];
}

- (void)addIgnoreNotifyingTitle:(NSDictionary *)titleInfo withService:(int)service {
    [_managedObjectContext performBlockAndWait:^{
        NSManagedObject *notifyiobj = [self retrieveIgnoredNotificationItem:((NSNumber *)titleInfo[@"id"]).intValue withService:service];
        if (!notifyiobj) {
            notifyiobj = [NSEntityDescription insertNewObjectForEntityForName:@"NotificationsIgnore" inManagedObjectContext:self.managedObjectContext];
        }
        [notifyiobj setValue:titleInfo[@"id"] forKey:@"id"];
        [notifyiobj setValue:@(service) forKey:@"service"];
        [notifyiobj setValue:titleInfo[@"title"] forKey:@"title"];
        [self.managedObjectContext save:nil];
    }];
}

- (void)removeNotifyingTitle:(int)titleid withService:(int)service {
    __block NSManagedObject *notifyobj = [self retrieveNotificationItem:titleid isAniListID:NO withService:service];
    if (notifyobj) {
        [_managedObjectContext performBlockAndWait:^{
            int anilistid = ((NSNumber *)[notifyobj valueForKey:@"anilistid"]).intValue;
            [self.managedObjectContext deleteObject:notifyobj];
            [self.managedObjectContext save:nil];
            [self removependingnotification:anilistid];
        }];
    }
}

- (void)removeIgnoreNotifyingTitle:(int)titleid withService:(int)service {
    __block NSManagedObject *notifyiobj = [self retrieveIgnoredNotificationItem:titleid withService:service];
    if (notifyiobj) {
        [_managedObjectContext performBlockAndWait:^{
            [self.managedObjectContext deleteObject:notifyiobj];
            [self.managedObjectContext save:nil];
        }];
    }
}

- (void)cleanupFinishedTitles {
    NSLog(@"Clearing Finished Titles from Notifications");
    [_managedObjectContext performBlockAndWait:^{
        NSArray *notifications;
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"finished == %i", 1];
        fetchRequest.predicate = predicate;
        NSError *error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *notifyobj in notifications) {
            [self.managedObjectContext deleteObject:notifyobj];
        }
        [self.managedObjectContext save:nil];
        NSLog(@"Removed: %li finished titles", notifications.count);
    }];
}

- (void)clearNotifyList {
    [_managedObjectContext performBlockAndWait:^{
        NSArray *notifications;
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        NSError *error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *notifyobj in notifications) {
            [self.managedObjectContext deleteObject:notifyobj];
        }
        fetchRequest.entity = [NSEntityDescription entityForName:@"NotificationsIgnore" inManagedObjectContext:self.managedObjectContext];
        error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *notifyobj in notifications) {
            [self.managedObjectContext deleteObject:notifyobj];
        }
        [self.managedObjectContext save:nil];
    }];
    [_notificationCenter removeAllPendingNotificationRequests];
}

- (NSManagedObject *)retrieveNotificationItem:(int)titleid isAniListID:(bool)isAniListID withService:(int)service {
    __block NSArray *notifications = @[];
    [_managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate;
        if (!isAniListID) {
        predicate = [NSPredicate predicateWithFormat:@"service == %i AND servicetitleid == %i", service, titleid];
        }
        else {
            predicate = [NSPredicate predicateWithFormat:@"service == %i AND anilistid == %i", service, titleid];
        }
        fetchRequest.predicate = predicate;
        NSError *error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    if (notifications.count > 0) {
        return notifications[0];
    }
    return nil;
}

- (NSManagedObject *)retrieveIgnoredNotificationItem:(int)titleid withService:(int)service {
    __block NSArray *notifications = @[];
    [_managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"NotificationsIgnore" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"service == %i AND id == %i", service, titleid];
        fetchRequest.predicate = predicate;
        NSError *error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    if (notifications.count > 0) {
        return notifications[0];
    }
    return nil;
}

- (NSArray *)getAllNotifications:(bool)includeall {
    __block NSArray *notifications = @[];
    [_managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = includeall ? [NSPredicate predicateWithFormat:@"finished == %i", 0] : [NSPredicate predicateWithFormat:@"enabled == %i AND finished == %i", 1, 0];
        fetchRequest.predicate = predicate;
        NSError *error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    return notifications;
}

#pragma mark helpers
- (void)generatePendingNotificationsList:(void (^)(bool success))completionHandler {
    [_schedulednotifications removeAllObjects];
    __weak AiringNotificationManager *weakSelf = self;
    [_notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        for (UNNotificationRequest *request in requests) {
            [weakSelf.schedulednotifications addObject:@([request.identifier stringByReplacingOccurrencesOfString:@"airing-" withString:@""].intValue)];
        }
        completionHandler(true);
    }];
}
- (bool)checkTitleIdIfPending:(int)titleid {
    for (NSNumber *pendingid in _schedulednotifications) {
        if (pendingid.intValue == titleid) {
            return true;
        }
    }
    return false;
}
@end
