//
//  AtarashiiListCoreData.h
//  Shukofukurou
//
//  Created by 天々座理世 on 2018/07/24.
//  Copyright © 2018 Atelier Shiori. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AtarashiiListCoreData : NSObject
+ (bool)hasListEntriesWithUserID:(int)userid withService:(int)service withType:(int)type;
+ (NSDictionary *)retrieveEntriesForUserId:(int)userid withService:(int)service withType:(int)type;
+ (NSDictionary *)retrieveSingleEntryForTitleID:(int)titleid withService:(int)service withType:(int)type;
+ (NSArray *)retrieveEntriesForUserId:(int)userid withService:(int)service withType:(int)type withPredicate:(NSPredicate *)filterpredicate;
+ (void)insertorupdateentriesWithDictionary:(NSDictionary *)data withUserId:(int)userid withService:(int)service withType:(int)type;
+ (void)updateSingleEntry:(NSDictionary *)parameters withUserId:(int)userid withService:(int)service withType:(int)type withId:(int)Id withIdType:(int)idtype;
+ (void)removeSingleEntrywithUserId:(int)userid withService:(int)service withType:(int)type withId:(int)Id withIdType:(int)idtype;
+ (void)removeAllEntrieswithService:(int)service;
@end
