//
//  AiringSchedule.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AppDelegate.h"
#import "AiringSchedule.h"
#import "TitleIDMapper.h"
#import <AFNetworking/AFNetworking.h>
#import <Hakuchou_iOS/AniListConstants.h>
#import <Hakuchou_iOS/AtarashiiAPIListFormatAniList.h>
#import "Utility.h"

@implementation AiringSchedule
+ (NSManagedObjectContext *)managedObjectContext {
    return ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
}

+ (NSArray *)retrieveAiringDataForDay:(NSString *)day {
    return [self retrieveFromCoreData:[NSPredicate predicateWithFormat:@"day ==[c] %@", day]];
}

+ (NSArray *)retrieveAllAiringData {
    return [self retrieveFromCoreData:nil];
}

+ (void)autofetchAiringScheduleWithCompletionHandler: (void (^)(bool success, bool refreshed))completionHandler {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults valueForKey:@"airschedulerefreshdate"] || ((NSDate *)[defaults valueForKey:@"airschedulerefreshdate"]).timeIntervalSinceNow < 0) {
        [self retrieveAiringScheduleShouldRefresh:true completionhandler:^(bool success, bool refreshed) {
            if (success && refreshed) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*60*2] forKey:@"airschedulerefreshdate"];
                [NSNotificationCenter.defaultCenter postNotificationName:@"airDataRefreshed" object:nil];
            }
            completionHandler(success, refreshed);
        }];
    }
    else {
        completionHandler(true, false);
    }
}

+ (void)retrieveAiringScheduleShouldRefresh:(bool)refresh completionhandler: (void (^)(bool success, bool refreshed))completionHandler {
    bool shouldrefresh = refresh || [self retrieveFromCoreData:nil].count == 0;
    if (shouldrefresh) {
        [self retrieveAiringSchedule:^(id responseobject) {
            [self processAiringData:responseobject];
            completionHandler(true , true);
            [NSNotificationCenter.defaultCenter postNotificationName:@"airDataRefreshed" object:nil];
        } error:^(NSError *error) {
            completionHandler(false, false);
        }];
    }
    else {
        completionHandler(true, false);
    }
}

+ (void)retrieveAiringSchedule:(void (^)(id responseobject))completionHandler error:(void (^)(NSError *error))errorHandler {
    NSMutableArray *tmparray = [NSMutableArray new];
    [self doRetrieveAiringSchedule:1 withArray:tmparray completion:completionHandler error:errorHandler];
}

+ (void)doRetrieveAiringSchedule: (int)page withArray:(NSMutableArray *)array completion:(void (^)(id responseobject))completionHandler error:(void (^)(NSError *error))errorHandler{
    AFHTTPSessionManager *manager = [Utility jsonmanager];
    
    NSDictionary *parameters = @{@"query" : kAniListAiring, @"variables" : @{@"page" : @(page)}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters headers:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject[@"data"] != [NSNull null]) {
            NSDictionary *dpage = responseObject[@"data"][@"Page"];
            [array addObjectsFromArray:dpage[@"media"]];
            if (((NSNumber *)dpage[@"pageInfo"][@"hasNextPage"]).boolValue) {
                int newpage = page + 1;
                [self doRetrieveAiringSchedule:newpage withArray:array completion:completionHandler error:errorHandler];
            }
            else {
                completionHandler([AtarashiiAPIListFormatAniList normalizeAiringData:array.copy]);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

+ (void)processAiringData: (NSArray *)airingdata {
    @autoreleasepool {
        // Save new data
        for (NSDictionary *entry in airingdata) {
            [self saveToCoreData:entry];
        }
        // Delete nonexisting entries that was retrieved
        NSArray *existingairingdata = [self retrieveFromCoreData:nil];
        for (NSDictionary *airingentry in existingairingdata) {
            NSArray *filteredarray = [airingdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id == %i", ((NSNumber *)airingentry[@"id"]).intValue]];
            if (filteredarray.count == 0 || ((NSNumber *)airingentry[@"idMal"]).intValue == 0) {
                [self deleteFromCoreData:((NSNumber *)airingentry[@"id"]).intValue];
            }
        }
        [[self managedObjectContext] save:nil];
    }
}

+ (void)saveToCoreData:(NSDictionary *)airingdata {
    [[TitleIDMapper sharedInstance] retrieveTitleIdForService:3 withTitleId:((NSNumber *)airingdata[@"id"]).stringValue withTargetServiceId:2 withType:0 completionHandler:^(id  _Nonnull titleid, bool success) {
        if ((NSNumber *)airingdata[@"idMal"] == 0) {
            return;
        }
        NSManagedObject *aentry = [self retrieveExistingEntry:((NSNumber *)airingdata[@"id"]).intValue];
        if (!aentry) {
            aentry = [NSEntityDescription insertNewObjectForEntityForName:@"Airing" inManagedObjectContext:[self managedObjectContext]];
        }
        [aentry setValue:airingdata[@"id"] forKey:@"id"];
        [aentry setValue:airingdata[@"idMal"] forKey:@"idMal"];
        if (success && titleid != [NSNull null]) {
            [aentry setValue:titleid forKey:@"idKitsu"];
        }
        [aentry setValue:airingdata[@"title"] forKey:@"title"];
        NSString *othertitlejson = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:airingdata[@"other_titles"] options:NSJSONWritingSortedKeys error:nil] encoding:NSUTF8StringEncoding];
        [aentry setValue:othertitlejson forKey:@"other_titles"];
        [aentry setValue:airingdata[@"episodes"] forKey:@"episodes"];
        [aentry setValue:airingdata[@"image_url"] forKey:@"image_url"];
        [aentry setValue:airingdata[@"status"] forKey:@"status"];
        [aentry setValue:airingdata[@"type"] forKey:@"type"];
        [aentry setValue:airingdata[@"day"] forKey:@"day"];
        [aentry setValue:airingdata[@"nextairdate"] != 0 ? [NSDate dateWithTimeIntervalSince1970:((NSNumber *)airingdata[@"nextairdate"]).longValue] : nil forKey:@"nextairdate"];
        [aentry setValue:airingdata[@"nextepisode"] forKey:@"nextepisode"];
    }];
}

+ (void)deleteFromCoreData:(int)titleid {
    NSManagedObject *airingentry = [self retrieveExistingEntry:titleid];
    [[self managedObjectContext] deleteObject:airingentry];
}

+ (NSArray *)retrieveFromCoreData:(NSPredicate *)filteringpredicate {
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Airing" inManagedObjectContext:moc];
    if (filteringpredicate) {
        fetchRequest.predicate = filteringpredicate;
    }
    NSError *error = nil;
    NSArray *airingentries = [moc executeFetchRequest:fetchRequest error:&error];
    return [self transformCoreDataAiringData:airingentries];
}

+ (NSArray *)transformCoreDataAiringData:(NSArray *)airingdata {
    NSMutableArray *finalarray = [NSMutableArray new];
    @autoreleasepool {
        for (NSManagedObject *airingobj in airingdata) {
            NSArray *keys = airingobj.entity.attributesByName.allKeys;
            NSMutableDictionary *newdict = [[NSMutableDictionary alloc] initWithDictionary:[airingobj dictionaryWithValuesForKeys:keys]];
            // Deserialize other_titles JSON object
            NSError *error;
            NSDictionary *jsondata = [NSJSONSerialization JSONObjectWithData:[(NSString *)newdict[@"other_titles"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            if (jsondata) {
                newdict[@"other_titles"] = jsondata;
            }
            else {
                newdict[@"other_titles"] =  @{@"synonyms" : @[]  , @"english" : @[], @"japanese" : @[] };
            }
            [finalarray addObject:newdict.copy];
        }
    }
    return finalarray.copy;
}

+ (NSManagedObject *)retrieveExistingEntry:(int)titleid {
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Airing" inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %i",titleid];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *airingentries = [moc executeFetchRequest:fetchRequest error:&error];
    if (airingentries.count > 0) {
        return airingentries[0];
    }
    return nil;
}
@end
