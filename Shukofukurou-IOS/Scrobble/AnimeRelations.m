//
//  AnimeRelations.m
//  Shukofukurou-IOS
//
//  Created by 小鳥遊六花 on 5/7/18.
//

#import "AnimeRelations.h"
#import <AFNetworking/AFNetworking.h>
#import "AppDelegate.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>

@interface AnimeRelations ()
@property (strong) NSManagedObjectContext *moc;
@property (strong) AFHTTPSessionManager *manager;
@end

@implementation AnimeRelations

+ (instancetype)sharedInstance {
    static AnimeRelations *sharedManager = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        sharedManager = [AnimeRelations new];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _moc = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
        _manager = [AFHTTPSessionManager manager];
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return self;
}

- (void)autoupdateRelations:(void (^)(bool success)) completionHandler {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDate *nextupdatedate = [defaults valueForKey:@"AnimeRelationsUpdateDate"];
    if (!nextupdatedate || [nextupdatedate timeIntervalSinceNow] < -604800) {
        [self updateRelations:completionHandler];
    }
    else {
        completionHandler(true);
    }
}

- (void)updateRelations:(void (^)(bool success)) completionHandler {
    [_manager GET:@"https://github.com/erengy/anime-relations/raw/master/anime-relations.txt" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"Updating Anime Relations!");
        [self processAnimeRelations:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"AnimeRelationsUpdateDate"];
        completionHandler(true);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Anime Relations Update Failed!");
        completionHandler(false);
    }];
}

- (void)processAnimeRelations:(NSString *)data {
    NSArray *rules = [self seperaterules:data];
    for (NSString *rulestr in rules) {
        @autoreleasepool {
            //Split Rules
            OnigRegexp *regex = [OnigRegexp compile:@"\\d+\\|(\\d+|\\?)\\|(\\d+|\\?):(\\d+-(\\d+|\\?)|\\d+) "];
            NSArray *strings = [regex search:rulestr].strings;
            NSString *sourcerule = strings[0] ? strings[0] : @"";
            regex = [OnigRegexp compile:@"-> (~\\|~\\|~:(\\d+-(\\d+|\\?)|\\d+)|\\d+\\|(\\d+|\\?)\\|(\\d+|\\?):(\\d+-(\\d+|\\?)|\\d+))(|!|~|\\?)"];
            strings = [regex search:rulestr].strings;
            NSString *targetrule = strings[0] ? strings[0] : @"";
            targetrule = [targetrule stringByReplacingOccurrencesOfString:@"-> " withString:@""];
            // Check rules split
            if (sourcerule.length == 0 && targetrule.length == 0) {
                continue;
            }
            //Parse source rule
            regex = [OnigRegexp compile:@"\\d+\\|(\\d+|\\?)\\|(\\d+|\\?)"];
            strings = [regex search:sourcerule].strings;
            NSString *tmpsourceids = strings[0] ? strings[0] : @"";
            NSArray *titleids = [tmpsourceids componentsSeparatedByString:@"|"];
            NSDictionary *sourcetitleids = @{@"source_malid" : @(((NSString *)titleids[0]).intValue), @"source_kitsuid" : [(NSString *)titleids[1] isEqualToString:@"~"] ? @(0) : @(((NSString *)titleids[1]).intValue), @"source_anilistid" : [(NSString *)titleids[2] isEqualToString:@"~"] ? @(0) : @(((NSString *)titleids[2]).intValue)};
            regex = [OnigRegexp compile:@":(\\d+-(\\d+|\\?)|\\d+)"];
            strings = [regex search:sourcerule].strings;
            NSString *tmpepisodestr = strings[0] ? strings[0] : @"";
            tmpepisodestr = [tmpepisodestr stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSNumber *sourcefromep;
            NSNumber *sourcetoep;
            bool iszeroepisode = false;
            if ([tmpepisodestr rangeOfString:@"-"].location == NSNotFound) {
                sourcefromep = @(tmpepisodestr.intValue);
                sourcetoep = sourcefromep;
            }
            else {
                sourcefromep = @([tmpepisodestr replaceByRegexp:[OnigRegexp compile:@"-\\d+"] with:@""].intValue);
                sourcetoep = @([tmpepisodestr replaceByRegexp:[OnigRegexp compile:@"\\d+-"] with:@""].intValue);
            }
            
            if (sourcefromep.intValue == 0) {
                iszeroepisode = true;
            }
            
            //Parse target rule
            regex =  [OnigRegexp compile:@"(~\\|~\\|~|\\d+\\|(\\d+|\\?)\\|(\\d+|\\?))"];
            strings = [regex search:targetrule].strings;
            NSString *tmptargetmalid = strings[0] ? strings[0] : @"";
            titleids = [tmptargetmalid componentsSeparatedByString:@"|"];
            NSDictionary *targetids =  @{@"target_malid" : @(((NSString *)titleids[0]).intValue), @"target_kitsuid" : [(NSString *)titleids[1] isEqualToString:@"~"] ? @(0) : @(((NSString *)titleids[1]).intValue), @"target_anilistid" : [(NSString *)titleids[2] isEqualToString:@"~"] ? @(0) : @(((NSString *)titleids[2]).intValue)};
            regex = [OnigRegexp compile:@":(\\d+-(\\d+|\\?)|\\d+)(|!|~|\\?)"];
            strings = [regex search:targetrule].strings;
            tmpepisodestr = strings[0] ? strings[0] : @"";
            tmpepisodestr = [tmpepisodestr stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSNumber *targetfromep;
            NSNumber *targettoep;
            NSString *targeteptype = [tmpepisodestr replaceByRegexp:[OnigRegexp compile:@":(\\d+-(\\d+|\\?)|\\d+)"] with:@""];
            tmpepisodestr = [tmpepisodestr stringByReplacingOccurrencesOfString:targetrule withString:@""];
            if ([tmpepisodestr rangeOfString:@"-"].location == NSNotFound) {
                targetfromep = @(tmpepisodestr.intValue);
                targettoep = targetfromep;
            }
            else {
                targetfromep = @([tmpepisodestr replaceByRegexp:[OnigRegexp compile:@"-\\d+"] with:@""].intValue);
                targettoep = @([tmpepisodestr replaceByRegexp:[OnigRegexp compile:@"\\d+-"] with:@""].intValue);
            }
            // Save Anime Relation
            NSMutableDictionary *tmprule = [[NSMutableDictionary alloc] initWithDictionary:@{@"is_zeroepisode" : @(iszeroepisode), @"source_ep_from" : sourcefromep, @"source_ep_to" : sourcetoep, @"target_ep_from" : targetfromep, @"target_ep_to" : targettoep, @"target_episode_type" : targeteptype}];
            [tmprule addEntriesFromDictionary:targetids];
            [tmprule addEntriesFromDictionary:sourcetitleids];
            [self saveRuleEntry:tmprule];
        }
    }
}

- (NSArray *)seperaterules:(NSString *)data {
    NSArray *tmparray = [data componentsSeparatedByString:@"\n"];
    OnigRegexp *titlematch = [OnigRegexp compile:@"- \\d+\\|(\\d+|\\?)\\|(\\d+|\\?):(\\d+-(\\d+|\\?)|\\d+) -> (~\\|~\\|~:(\\d+-(\\d+|\\?)|\\d+)|\\d+\\|(\\d+|\\?)\\|(\\d+|\\?):(\\d+-(\\d+|\\?)|\\d+))(!|~|\\?|)" options:OnigOptionIgnorecase];
    NSMutableArray *result = [NSMutableArray new];
    for (NSString *line in tmparray) {
        @autoreleasepool {
            if ([titlematch match:line]) {
                [result addObject:line.copy];
            }
        }
    }
    return result;
}

- (void)saveRuleEntry:(NSDictionary *)rules {
    [_moc performBlockAndWait:^{
        NSError *error;
        NSManagedObject *obj = [self retrieveRelationsEntryForSourceTitleID:((NSNumber *)rules[@"source_malid"]).intValue withTargetId:((NSNumber *)rules[@"target_malid"]).intValue];
        if (obj) {
            // Update Entry
            [obj setValue:rules[@"source_kitsuid"] forKey:@"source_kitsuid"];
            [obj setValue:rules[@"target_kitsuid"] forKey:@"target_kitsuid"];
            [obj setValue:rules[@"source_anilistid"] forKey:@"source_anilistid"];
            [obj setValue:rules[@"target_anilistid"] forKey:@"target_anilistid"];
            [obj setValue:rules[@"is_zeroepisode"] forKey:@"is_zeroepisode"];
            [obj setValue:rules[@"source_ep_from"] forKey:@"source_ep_from"];
            [obj setValue:rules[@"source_ep_to"] forKey:@"source_ep_to"];
            [obj setValue:rules[@"target_ep_from"] forKey:@"target_ep_from"];
            [obj setValue:rules[@"target_ep_to"] forKey:@"target_ep_to"];
            [obj setValue:rules[@"target_episode_type"] forKey:@"target_episode_type"];
        }
        else {
            // Add Entry to Anime Relations Entity
            obj = [NSEntityDescription
                   insertNewObjectForEntityForName:@"AnimeRelationsE"
                   inManagedObjectContext: self.moc];
            // Set values in the new record
            // Update Entry
            [obj setValue:rules[@"source_malid"] forKey:@"source_malid"];
            [obj setValue:rules[@"target_malid"] forKey:@"target_malid"];
            [obj setValue:rules[@"source_kitsuid"] forKey:@"source_kitsuid"];
            [obj setValue:rules[@"target_kitsuid"] forKey:@"target_kitsuid"];
            [obj setValue:rules[@"source_anilistid"] forKey:@"source_anilistid"];
            [obj setValue:rules[@"target_anilistid"] forKey:@"target_anilistid"];
            [obj setValue:rules[@"is_zeroepisode"] forKey:@"is_zeroepisode"];
            [obj setValue:rules[@"source_ep_from"] forKey:@"source_ep_from"];
            [obj setValue:rules[@"source_ep_to"] forKey:@"source_ep_to"];
            [obj setValue:rules[@"target_ep_from"] forKey:@"target_ep_from"];
            [obj setValue:rules[@"target_ep_to"] forKey:@"target_ep_to"];
            [obj setValue:rules[@"target_episode_type"] forKey:@"target_episode_type"];
        }
        //Save
        [self.moc save:&error];
    }];
}

- (NSManagedObject *)retrieveRelationsEntryForSourceTitleID:(int)sourceid withTargetId:(int)targetid {
    // Return existing Anime Relations rule
    __block NSArray *relations;
    [_moc performBlockAndWait:^{
        NSError *error;
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(source_malid == %i) AND (target_malid == %i)", sourceid,targetid];
        NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
        fetch.entity = [NSEntityDescription entityForName:@"AnimeRelationsE" inManagedObjectContext:self.moc];
        fetch.predicate = predicate;
        relations = [self.moc executeFetchRequest:fetch error:&error];
    }];
    if (relations.count > 0) {
        return (NSManagedObject *)relations[0];
    }
    return nil;
}

- (NSArray *)retrieveRelationsEntriesForTitleID:(int)titleid withService:(int)service {
    // Return relations for Kitsu ID
    __block NSArray *relations;
    [_moc performBlockAndWait:^{
        NSError *error;
        NSPredicate *predicate;
        switch (service) {
            case 1:
                predicate = [NSPredicate predicateWithFormat: @"(source_kitsuid == %i)", titleid];
                break;
            case 2:
                predicate = [NSPredicate predicateWithFormat: @"(source_anilistid == %i)", titleid];
                break;
            default:
                break;
        }
        NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
        fetch.entity = [NSEntityDescription entityForName:@"AnimeRelationsE" inManagedObjectContext:self.moc];
        fetch.predicate = predicate;
        relations = [self.moc executeFetchRequest:fetch error:&error];
    }];
    return relations;
}

- (void)clearAnimeRelations {
    // Clears Anime Relations data
    [_moc performBlockAndWait:^{
        NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
        fetch.entity = [NSEntityDescription entityForName:@"AnimeRelationsE" inManagedObjectContext:self.moc];
        
        NSError *error = nil;
        NSArray *relations = [self.moc executeFetchRequest:fetch error:&error];
        for (NSManagedObject *relation in relations) {
            [self.moc deleteObject:relation];
        }
        error = nil;
        [self.moc save:&error];
    }];
}

@end
