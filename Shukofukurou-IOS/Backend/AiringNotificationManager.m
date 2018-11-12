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
#import "AniListConstants.h"
#import "Utility.h"
#import <AFNetworking/AFNetworking.h>

@import UserNotifications;

@interface AiringNotificationManager ()
@property (strong) UNUserNotificationCenter *notificationCenter;
@end

@implementation AiringNotificationManager
- (instancetype) init {
    if (self = [super init]) {
        self.managedObjectContext = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
        self.notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    }
    return self;
}

- (void)checkListForAiringTitles:(void (^)(bool success))completionHandler {
    __block int service = (int)[NSUserDefaults.standardUserDefaults integerForKey:@"airingnotification_service"];
    NSArray *list = @[];
    switch (service) {
        case 1: {
            NSDictionary *udict = [listservice getAllUserNames];
            if (udict[@"myanimelist"] != [NSNull null]) {
                list = [AtarashiiListCoreData retrieveEntriesForUserName:udict[@"myanimelist"] withService:1 withType:0 withPredicate:[NSPredicate predicateWithFormat:@"status ==[c] %@ AND (watched_status ==[c] %@ OR watched_status ==[c] %@)", @"currently airing", @"watching", @"plan to watch"]];
                break;
            }
            return;
        }
        case 2:
        case 3: {
            NSDictionary *uiddict = [listservice getAllUserID];
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
            break;
        }
        default: {
            return;
        }
    }
    TitleIdEnumerator *tenum = [[TitleIdEnumerator alloc] initWithList:list withType:0 completion:^(TitleIdEnumerator * _Nonnull titleidenum) {
        for (NSDictionary *entry in list) {
            int anilistid = [titleidenum findTargetIdFromSourceId:((NSNumber *)entry[@"id"]).intValue];
            if (![self retrieveNotificationItem:anilistid withService:service] || ![self retrieveIgnoredNotificationItem:((NSNumber *)entry[@"id"]).intValue withService:service]) {
                if (anilistid > 0) {
                    [self addNotifyingTitle:entry withAniListID:anilistid withService:service];
                }
                else {
                    [self addIgnoreNotifyingTitle:entry withService:service];
                }
            }
        }
        completionHandler(true);
    }];
    [tenum generateTitleIdMappingList:service toService:3];
}

- (void)checkForNewNotifications:(void (^)(bool success))completionHandler {
    [self performNewNotificationCheck:[self getAllNotifications] withPosition:0 completionHandler:completionHandler];
}

- (void)performNewNotificationCheck:(NSArray *)notificationList withPosition:(int)position completionHandler:(void (^)(bool success))completionHandler {
    AFHTTPSessionManager *sessionmanager = [Utility jsonmanager];
    __block NSManagedObjectContext *notifyobj = notificationList[position];
    [sessionmanager POST:@"https://graphql.anilist.co/" parameters:@{@"query" : kAniListNextEpisode, @"variables" : @{@"id": [notifyobj valueForKey:@"anilistid"]}} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.managedObjectContext performBlockAndWait:^{
            NSDictionary *animeinfo = responseObject[@"data"];
            bool finished = [(NSString *)animeinfo[@"status"] isEqualToString:@"FINISHED"] || [(NSString *)animeinfo[@"status"] isEqualToString:@"CANCELLED"];
            [notifyobj setValue:@(finished) forKey:@"finished"];
            [notifyobj setValue:animeinfo[@"nextAiringEpisode"] != [NSNull null] ? [NSDate dateWithTimeIntervalSince1970:((NSNumber *)animeinfo[@"nextAiringEpisode"][@"airingAt"]).intValue] : [NSNull null] forKey:@"nextairdate"];
            [notifyobj setValue:animeinfo[@"nextAiringEpisode"] != [NSNull null] ? animeinfo[@"nextAiringEpisode"][@"nextepisode"] : @(0) forKey:@"nextairdate"];
            [self.managedObjectContext save:nil];
        }];
        if (notificationList.count == position) {
            completionHandler(true);
        }
        else {
            int newPosition = position + 1;
            [self performNewNotificationCheck:notificationList withPosition:newPosition completionHandler:completionHandler];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completionHandler(false);
    }];
}

- (void)setNotification:(NSManagedObject *)notificationobj {
    if ([notificationobj valueForKey:@"nextairdate"] != [NSNull null]) {
        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
        content.title = [notificationobj valueForKey:@"title"];
        content.body = [NSString stringWithFormat:@"Episode %@ has aired.", [notificationobj valueForKey:@"nextepisode"]];
        content.sound = [UNNotificationSound defaultSound];
        content.userInfo = @{@"anilistid" : [notificationobj valueForKey:@"anilistid"], @"servicetitleid" : [notificationobj valueForKey:@"servicetitleid"], @"service" : [notificationobj valueForKey:@"service"]};
        NSDateComponents *triggerDate = [[NSCalendar currentCalendar]
                                         components:NSCalendarUnitYear +
                                         NSCalendarUnitMonth + NSCalendarUnitDay +
                                         NSCalendarUnitHour + NSCalendarUnitMinute +
                                         NSCalendarUnitSecond fromDate:(NSDate *)[notificationobj valueForKey:@"nextairdate"]];
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
        }];
    }
}

- (void)removependingnotification:(int)anilistid {
    [_notificationCenter removePendingNotificationRequestsWithIdentifiers:@[[NSString stringWithFormat:@"airing-%i",anilistid]]];
}

- (void)addNotifyingTitle:(NSDictionary *)titleInfo withAniListID:(int)anilistid withService:(int)service {
    [_managedObjectContext performBlockAndWait:^{
        NSManagedObject *notifyobj = [self retrieveNotificationItem:anilistid withService:service];
        if (!notifyobj) {
            notifyobj = [NSEntityDescription insertNewObjectForEntityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        }
        [notifyobj setValue:@(anilistid) forKey:@"anilistid"];
        [notifyobj setValue:@(service) forKey:@"service"];
        [notifyobj setValue:titleInfo[@"id"] forKey:@"servicetitleid"];
        [notifyobj setValue:titleInfo[@"title"] forKey:@"title"];
        [notifyobj setValue:@(YES) forKey:@"enabled"];
        [notifyobj setValue:@(NO) forKey:@"finished"];
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
    __block NSManagedObject *notifyobj = [self retrieveNotificationItem:titleid withService:service];
    [_managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:notifyobj];
        [self.managedObjectContext save:nil];
    }];
}

- (void)removeIgnoreNotifyingTitle:(int)titleid withService:(int)service {
    __block NSManagedObject *notifyiobj = [self retrieveIgnoredNotificationItem:titleid withService:service];
    [_managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:notifyiobj];
        [self.managedObjectContext save:nil];
    }];
}

- (void)cleanupFinishedTitles {
    [_managedObjectContext performBlockAndWait:^{
        NSArray *notifications = @[];
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
    }];
}

- (void)clearNotifyList {
    [_managedObjectContext performBlockAndWait:^{
        NSArray *notifications = @[];
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        NSError *error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *notifyobj in notifications) {
            [self.managedObjectContext deleteObject:notifyobj];
        }
        fetchRequest.entity = [NSEntityDescription entityForName:@"NotificationsIgnored" inManagedObjectContext:self.managedObjectContext];
        error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *notifyobj in notifications) {
            [self.managedObjectContext deleteObject:notifyobj];
        }
        [self.managedObjectContext save:nil];
    }];
}

- (NSManagedObject *)retrieveNotificationItem:(int)titleid withService:(int)service {
    __block NSArray *notifications = @[];
    [_managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"service == %i AND anilistid == %i", service, titleid];
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

- (NSArray *)getAllNotifications {
    __block NSArray *notifications = @[];
    [_managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Notifications" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"enabled == %i AND finished == %i", 1, 0];
        fetchRequest.predicate = predicate;
        NSError *error = nil;
        notifications = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    return notifications;
}
@end
