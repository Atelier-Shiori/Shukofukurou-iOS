//
//  HistoryManager.m
//  Shukofukurou-IOS
//
//  Created by 天々座理世 on 7/30/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "HistoryManager.h"
#import "AppDelegate.h"
#import "listservice.h"
#import <CloudKit/CloudKit.h>

@interface HistoryManager ()
@property (strong) NSManagedObjectContext *moc;
@end

@implementation HistoryManager
+ (instancetype)sharedInstance {
    static HistoryManager *sharedManager = nil;
    static dispatch_once_t historytoken;
    dispatch_once(&historytoken, ^{
        sharedManager = [HistoryManager new];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _moc = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
    }
    return self;
}

- (void)insertHistoryRecord:(int)titleid
                  withTitle:(NSString *)title
      withHistoryActionType:(HistoryActionType)historyActionType
                withSegment:(int)segment
              withMediaType:(int)mediatype
                withService:(int)service
             insertToiCloud:(bool)icloudinsert {
    [_moc performBlockAndWait:^{
        NSManagedObject *historyobj = [NSEntityDescription insertNewObjectForEntityForName:@"UpdateHistory" inManagedObjectContext:_moc];
        NSDate *updatedate = [NSDate date];
        NSString *useridentifier = [listservice.sharedInstance getCurrentServiceID] == 1 ? [listservice.sharedInstance getCurrentServiceUsername] : @([listservice.sharedInstance getCurrentUserID]).stringValue;
        [historyobj setValue:@(updatedate.timeIntervalSince1970) forKey:@"historyactiondate"];
        [historyobj setValue:@(historyActionType) forKey:@"historyactiontype"];
        [historyobj setValue:[NSString stringWithFormat:@"%@|%i|%f|%i", useridentifier, titleid, updatedate.timeIntervalSince1970, historyActionType] forKey:@"historyid"];
        [historyobj setValue:@(mediatype) forKey:@"mediatype"];
        [historyobj setValue:@(segment) forKey:@"segment"];
        [historyobj setValue:@(listservice.sharedInstance.getCurrentServiceID) forKey:@"service"];
        [historyobj setValue:title forKey:@"title"];
        [historyobj setValue:@(titleid) forKey:@"titleid"];
        [historyobj setValue:useridentifier forKey:@"user"];
        [_moc save:nil];
        if (icloudinsert) {
            [self inserticloudrecord:historyobj];
        }
    }];
}

- (void)insertHistoryRecordWithCKRecord:(CKRecord *)record {
    [_moc performBlockAndWait:^{
        NSManagedObject *historyobj = [NSEntityDescription insertNewObjectForEntityForName:@"UpdateHistory" inManagedObjectContext:_moc];
        [historyobj setValue:record[@"historyactiondate"] forKey:@"historyactiondate"];
        [historyobj setValue:record[@"historyactiontype"] forKey:@"historyactiontype"];
        [historyobj setValue:record[@"historyid"] forKey:@"historyid"];
        [historyobj setValue:record[@"mediatype"] forKey:@"mediatype"];
        [historyobj setValue:record[@"segment"] forKey:@"segment"];
        [historyobj setValue:record[@"service"] forKey:@"service"];
        [historyobj setValue:record[@"title"] forKey:@"title"];
        [historyobj setValue:record[@"titleid"] forKey:@"titleid"];
        [historyobj setValue:record[@"user"] forKey:@"user"];
        [_moc save:nil];
    }];
}

- (void)deleteHistoryRecord:(NSManagedObject *)obj {
    [_moc performBlockAndWait:^{
        [_moc deleteObject:obj];
        [_moc save:nil];
    }];
}

- (void)inserticloudrecord:(NSManagedObject *)object {
    CKRecord *record = [[CKRecord alloc] initWithRecordType:@"historyRecord"];
        record[@"historyactiondate"] = [object valueForKey:@"historyactiondate"];
        record[@"historyactiontype"] = [object valueForKey:@"historyactiontype"];
        record[@"historyid"] = [object valueForKey:@"historyid"];
        record[@"mediatype"] = [object valueForKey:@"mediatype"];
        record[@"segment"] = [object valueForKey:@"segment"];
        record[@"service"] = [object valueForKey:@"service"];
        record[@"title"] = [object valueForKey:@"title"];
        record[@"titleid"] = [object valueForKey:@"titleid"];
        record[@"user"] = [object valueForKey:@"user"];
    [CKContainer.defaultContainer.privateCloudDatabase saveRecord:record completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
        
    }];
    
}

- (void)deleteticloudrecord:(NSString *)historyEntryRecordID {
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:historyEntryRecordID];
    [[CKContainer defaultContainer].privateCloudDatabase deleteRecordWithID:recordID completionHandler:^(CKRecordID * _Nullable recordID, NSError * _Nullable error) {
    }];
}


- (void)synchistory:(void (^)(NSArray *history)) completionHandler  {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    long syncdate = [defaults integerForKey:@"historysyncdate"] ? [defaults integerForKey:@"historysyncdate"] : 0;
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"historyRecord" predicate:predicate];
    [CKContainer.defaultContainer.privateCloudDatabase performQuery:query inZoneWithID:nil completionHandler:^(NSArray<CKRecord *> * _Nullable results, NSError * _Nullable error) {
        if (error) {
            completionHandler([self retrieveHistoryList]);
            return;
        }
        // Check Local Entries
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"UpdateHistory" inManagedObjectContext:self.moc];
        NSArray *entries = [self.moc executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *obj in entries) {
            if (((NSNumber *)[obj valueForKey:@"historyactiondate"]).longValue > syncdate && ![self checkicloudentryexists:[obj valueForKey:@"historyid"] withArray:results]) {
                [self inserticloudrecord:obj];
            }
            else {
                if (![self checkicloudentryexists:[obj valueForKey:@"historyid"] withArray:results]) {
                    [self deleteHistoryRecord:obj];
                }
            }
        }
        [self.moc save:nil];
        [CKContainer.defaultContainer.privateCloudDatabase performQuery:query inZoneWithID:nil completionHandler:^(NSArray<CKRecord *> * _Nullable nresults, NSError * _Nullable error) {
            if (error) {
                completionHandler([self retrieveHistoryList]);
                return;
            }
            // Sync From iCloud to local database
            for (CKRecord *record in nresults) {
                if (((NSNumber *)record[@"historyactiondate"]).longValue > syncdate && ![self historyentryexists:record[@"historyid"]]) {
                    // Insert Record
                    [self insertHistoryRecordWithCKRecord:record];
                }
                else {
                    if (![self historyentryexists:record[@"historyid"]]) {
                        // Delete entry, does not exist on device and is before sync date.
                        [self deleteticloudrecord:record.recordID.recordName];
                        continue;
                    }
                }
            }
            [defaults setInteger:[NSDate date].timeIntervalSince1970 forKey:@"historysyncdate"];
            [self pruneLocalHistory];
                [self pruneicloudHistory:^{
                    completionHandler([self retrieveHistoryList]);
                }];
        }];
        
    }];
}

- (bool)historyentryexists:(NSString *)historyEntryID {
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"UpdateHistory" inManagedObjectContext:_moc];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"historyid ==[c] %@", historyEntryID];
    NSError *error = nil;
    NSArray *entries = [_moc executeFetchRequest:fetchRequest error:&error];
    return entries.count > 0;
}

- (bool)checkicloudentryexists:(NSString *)historyEntryID withArray:(NSArray *)array {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"historyid ==[c] %@", historyEntryID];
    NSArray *filteredArray = [array filteredArrayUsingPredicate:predicate];
    return filteredArray.count > 0;
}

- (NSArray *)retrieveHistoryList {
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSString *useridentifier = [listservice.sharedInstance getCurrentServiceID] == 1 ? [listservice.sharedInstance getCurrentServiceUsername] : @([listservice.sharedInstance getCurrentUserID]).stringValue;
    fetchRequest.entity = [NSEntityDescription entityForName:@"UpdateHistory" inManagedObjectContext:self.moc];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user ==[c] %@ AND service == %i", useridentifier, listservice.sharedInstance.getCurrentServiceID];
    NSMutableArray *tmplist = [NSMutableArray new];
    NSArray *entries = [self.moc executeFetchRequest:fetchRequest error:nil];
    for (NSManagedObject *obj in entries) {
         NSArray *keys = obj.entity.attributesByName.allKeys;
        [tmplist addObject:[obj dictionaryWithValuesForKeys:keys]];
    }
    NSArray *hentries = tmplist.copy;
    return hentries;
}

- (void)pruneLocalHistory {
    [_moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"UpdateHistory" inManagedObjectContext:self.moc];
        NSArray *entries = [self.moc executeFetchRequest:fetchRequest error:nil];
        for (NSManagedObject *obj in entries) {
            long historytimestamp = ((NSNumber *)[obj valueForKey:@"historyactiondate"]).longValue;
            long limitedtimestamp = [NSDate dateWithTimeIntervalSince1970:historytimestamp+([NSUserDefaults.standardUserDefaults integerForKey:@"historyprunedate"]*24*60*60)].timeIntervalSince1970;
            if (NSDate.date.timeIntervalSince1970 - limitedtimestamp > 0) {
                // Prune
                [_moc deleteObject:obj];
            }
        }
        [_moc save:nil];
    }];
}

- (void)pruneicloudHistory:(void (^)(void)) completionHandler {
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"historyRecord" predicate:predicate];
        
    [[CKContainer defaultContainer].publicCloudDatabase performQuery:query
                                                        inZoneWithID:nil
                                                    completionHandler:^(NSArray *results, NSError *error) {
        for (CKRecord *record in results) {
            long historytimestamp = ((NSNumber *)record[@"historyactiondate"]).longValue;
            long limitedtimestamp = [NSDate dateWithTimeIntervalSince1970:historytimestamp+([NSUserDefaults.standardUserDefaults integerForKey:@"historyprunedate"]*24*60*60)].timeIntervalSince1970;
            if (NSDate.date.timeIntervalSince1970 - limitedtimestamp > 0) {
                // Prune
                [self deleteticloudrecord:record.recordID.recordName];
            }
            completionHandler();
        }
    }];
}

- (void)removeAllHistoryRecords {
    [_moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"UpdateHistory" inManagedObjectContext:self.moc];
        NSArray *entries = [self.moc executeFetchRequest:fetchRequest error:nil];
        for (NSManagedObject *obj in entries) {
            [_moc deleteObject:obj];
        }
        [_moc save:nil];
    }];
}

- (void)removeAlliCloudHistoryRecords:(void (^)(void)) completionHandler {
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"historyRecord" predicate:predicate];
        
    [[CKContainer defaultContainer].publicCloudDatabase performQuery:query
                                                        inZoneWithID:nil
                                                    completionHandler:^(NSArray *results, NSError *error) {
        if (error) {
            completionHandler();
            return;
        }
        for (CKRecord *record in results) {
            [self deleteticloudrecord:record.recordID.recordName];
        }
        [NSUserDefaults.standardUserDefaults setInteger:0 forKey:@"historysyncdate"];
        completionHandler();
    }];
}

@end
