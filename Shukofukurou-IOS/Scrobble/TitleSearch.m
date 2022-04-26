//
//  TitleSearch.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/18/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "AnimeRelations.h"
#import "TitleSearch.h"
#import "listservice.h"
#import "AppDelegate.h"
#import "string_score.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>

@interface TitleSearch ()
typedef NS_ENUM(unsigned int, matchtype) {
    NoMatch = 0,
    PrimaryTitleMatch = 1,
    AlternateTitleMatch = 2
};
@property (strong) NSString *DetectedTitle;
@property (strong) NSString *DetectedEpisode;
@property int DetectedSeason;
@property bool DetectedTitleisMovie;
@property bool DetectedTitleisEpisodeZero;
@property (strong) NSString *finaltitle;
@property NSString *titleid;
@property (strong) NSManagedObjectContext *moc;
@end

@implementation TitleSearch

- (instancetype)init {
    if (self = [super init]) {
        [self populateinfo];
        _moc = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
    }
    return self;
}

- (void)processScrobble:(void (^)(int titleid, int episode, bool success)) completionHandler {
    [self checkCache];
    if (_titleid.length > 0) {
        completionHandler(_titleid.intValue, _DetectedEpisode.intValue, true);
    }
    [listservice.sharedInstance searchTitle:_DetectedTitle withType:0 withSearchOptions:nil completion:^(id responseObject, int nextoffset, bool hasnextpage) {
        self.titleid = [self findaniid:responseObject searchterm:self.DetectedTitle];
        if (self.titleid.length > 0) {
            [self checkCache];
            completionHandler(self.titleid.intValue, self.DetectedEpisode.intValue, true);
        }
        else {
            completionHandler(0,0,false);
        }
    } error:^(NSError *error) {
        completionHandler(0,0,false);
    }];
}

- (void)populateinfo {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.moe.malupdaterosx.Shukofukurou-IOS.scrobbleextension"];
    NSDictionary *streamdata = [defaults valueForKey:@"streamdata"];
    if (streamdata) {
        _DetectedTitle = streamdata[@"title"];
        _DetectedEpisode = ((NSNumber *)streamdata[@"episode"]).stringValue;
        _DetectedSeason = ((NSNumber *)streamdata[@"season"]).intValue;
    }
    _DetectedTitleisMovie = _DetectedEpisode.length == 0 || [_DetectedTitle localizedCaseInsensitiveContainsString:@"movie"];
    _DetectedTitleisEpisodeZero = _DetectedEpisode.intValue == 0;
}

- (int)checkAnimeRelations:(int)titleid {
    int currentservice = [listservice.sharedInstance getCurrentServiceID];
    NSArray *relations = [AnimeRelations.sharedInstance retrieveRelationsEntriesForTitleID:titleid withService:currentservice];
    for (NSManagedObject *relation in relations) {
        @autoreleasepool {
            NSNumber *sourcefromepisode = [relation valueForKey:@"source_ep_from"];
            NSNumber *sourcetoepisode = [relation valueForKey:@"source_ep_to"];
            NSNumber *targetfromepisode = [relation valueForKey:@"target_ep_from"];
            NSNumber *targettoepisode = [relation valueForKey:@"target_ep_to"];
            NSNumber *iszeroepisode = [relation valueForKey:@"is_zeroepisode"];
            NSNumber *targetid;
            switch (currentservice) {
                case 0:
                    targetid = [relation valueForKey:@"target_kitsuid"];
                    break;
                case 1:
                    targetid = [relation valueForKey:@"target_anilistid"];
                    break;
                default:
                    break;
            }
            
            if (self.DetectedEpisode.intValue < sourcefromepisode.intValue && self.DetectedEpisode.intValue > sourcetoepisode.intValue) {
                continue;
            }
            int tmpep = self.DetectedEpisode.intValue - (sourcefromepisode.intValue-1);
            if (tmpep > 0 && tmpep <= targettoepisode.intValue) {
                self.DetectedEpisode = @(tmpep).stringValue;
                return targetid.intValue;
            }
            else if (self.DetectedTitleisEpisodeZero && iszeroepisode.boolValue) {
                self.DetectedEpisode = targetfromepisode.stringValue;
                return targetid.intValue;
            }
            else if (self.DetectedTitleisMovie && targetfromepisode.intValue == targettoepisode.intValue) {
                self.DetectedEpisode = targetfromepisode.stringValue;
                return targetid.intValue;
            }
        }
    }
    return -1;
}

- (bool)checkAnimeRelationsForExisting:(int)titleid {
    int currentservice = [listservice.sharedInstance getCurrentServiceID];
    NSArray *relations = [AnimeRelations.sharedInstance retrieveTargetRelationsEntriesForTitleID:titleid withService:currentservice];
    for (NSManagedObject *relation in relations) {
        @autoreleasepool {
            NSNumber *sourcefromepisode = [relation valueForKey:@"source_ep_from"];
            NSNumber *sourcetoepisode = [relation valueForKey:@"source_ep_to"];
            NSNumber *targetfromepisode = [relation valueForKey:@"target_ep_from"];
            NSNumber *targettoepisode = [relation valueForKey:@"target_ep_to"];
            NSNumber *iszeroepisode = [relation valueForKey:@"is_zeroepisode"];
            NSNumber *targetid;
            switch (currentservice) {
                case 0:
                    targetid = [relation valueForKey:@"target_kitsuid"];
                    break;
                case 1:
                    targetid = [relation valueForKey:@"target_anilistid"];
                    break;
                case 2:
                    targetid = [relation valueForKey:@"target_malid"];
                    break;
                default:
                    break;
            }
                    
            if (self.DetectedEpisode.intValue < sourcefromepisode.intValue && self.DetectedEpisode.intValue > sourcetoepisode.intValue) {
                continue;
            }
            int tmpep = self.DetectedEpisode.intValue - (sourcefromepisode.intValue-1);
            if (tmpep > 0 && tmpep <= targettoepisode.intValue) {
                self.DetectedEpisode = @(tmpep).stringValue;
                return YES;
            }
            else if (self.DetectedTitleisEpisodeZero && iszeroepisode.boolValue) {
                self.DetectedEpisode = targetfromepisode.stringValue;
                return YES;
            }
            else if (self.DetectedTitleisMovie && targetfromepisode.intValue == targettoepisode.intValue) {
                self.DetectedEpisode = targetfromepisode.stringValue;
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark Title Id
- (NSString *)findaniid:(id)responseObject searchterm:(NSString *) term {
    //Initalize NSString to dump the title temporarily
    NSString *theshowtitle = @"";
    NSString *alttitle = @"";
    // Remove Colons
    term = [term stringByReplacingOccurrencesOfString:@":" withString:@""];
    term = [term stringByReplacingOccurrencesOfString:@" - " withString:@" "];
    term = [term stringByReplacingOccurrencesOfString:@" -" withString:@" "];
    term = [term stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    term = [term stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //Create Regular Expression
    OnigRegexp   *regex;
    NSLog(@"%@", self.DetectedTitleisMovie ? @"Title is a movie" : @"Title is not a movie.");
    // Populate Sorted Array
    NSArray * sortedArray = [self filterArray:responseObject];
    // Used for String Comparison
    NSDictionary * titlematch1;
    NSDictionary * titlematch2;
    int mstatus = 0;
    // Search
    for (int i = 1; i < 3; i++) {
        switch (i) {
            case 1:
                if ([term containsString:@"`"]) {
                    regex = [OnigRegexp compile:[NSString stringWithFormat:@"(%@|%@)",term, [term stringByReplacingOccurrencesOfString:@"`" withString:@"'"]] options:OnigOptionIgnorecase];
                }
                else {
                    regex = [OnigRegexp compile:[NSString stringWithFormat:@"(%@)",term] options:OnigOptionIgnorecase];
                }
                break;
            case 2:
                if ([term containsString:@"`"]) {
                    regex = [OnigRegexp compile:[[NSString stringWithFormat:@"(%@|%@)",term, [term stringByReplacingOccurrencesOfString:@"`" withString:@"'"]] stringByReplacingOccurrencesOfString:@" " withString:@"|"] options:OnigOptionIgnorecase];
                }
                else {
                    regex = [OnigRegexp compile:[[NSString stringWithFormat:@"(%@)",term] stringByReplacingOccurrencesOfString:@" " withString:@"|"] options:OnigOptionIgnorecase];
                }
                break;
            default:
                break;
        }
        
        // Check TV, ONA, Special, OVA, Other
        for (NSDictionary *searchentry in sortedArray) {
            // Populate titles
            theshowtitle = [NSString stringWithFormat:@"%@",searchentry[@"title"]];
            NSMutableArray *tmptitles = [NSMutableArray new];
            if (((NSArray *)searchentry[@"other_titles"][@"english"]).count > 0) {
                [tmptitles addObjectsFromArray:searchentry[@"other_titles"][@"english"]];
            }
            if (((NSArray *)searchentry[@"other_titles"][@"japanese"]).count > 0) {
                [tmptitles addObjectsFromArray:searchentry[@"other_titles"][@"japanese"]];
            }
            int matchstatus = 0;
            // Remove colons as they are invalid characters for filenames and to improve accuracy
            theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@":" withString:@""];
            theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@" - " withString:@" "];
            theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@" -" withString:@" "];
            theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@"-" withString:@" "];
            theshowtitle = [theshowtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            // Perform Recognition
            NSDictionary * matchstatusdict = [self checkMatch:theshowtitle alttitles:tmptitles regex:regex option:i];
            matchstatus = ((NSNumber *)matchstatusdict[@"matchstatus"]).intValue;
            if (matchstatus == AlternateTitleMatch) {
                alttitle = matchstatusdict[@"matchedtitle"];
            }
            if (matchstatus == NoMatch) {
                if ([term caseInsensitiveCompare:theshowtitle] == NSOrderedSame) {
                    matchstatus =  PrimaryTitleMatch;
                }
                else {
                    for (NSString *atitle in tmptitles) {
                        NSString *atmptitle = [atitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                        atmptitle = [atmptitle stringByReplacingOccurrencesOfString:@" - " withString:@" "];
                        atmptitle = [atmptitle stringByReplacingOccurrencesOfString:@" -" withString:@" "];
                        atmptitle = [atmptitle stringByReplacingOccurrencesOfString:@"-" withString:@" "];
                        atmptitle = [atmptitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if ([term caseInsensitiveCompare:atitle] == NSOrderedSame) {
                            alttitle = atmptitle;
                            matchstatus = AlternateTitleMatch;
                            break;
                        }
                    }
                }
            }
            if (matchstatus == PrimaryTitleMatch || matchstatus == AlternateTitleMatch) {
                    if (self.DetectedTitleisMovie) {
                        self.DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                        if ([[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"Special"]) {
                            self.DetectedTitleisMovie = false;
                        }
                    }
                    else {
                        if ([[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"TV"]||[[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"ONA"]) { // Check Seasons if the title is a TV show type
                            // Used for Season Checking
                            if (self.DetectedSeason != ((NSNumber *)searchentry[@"parsed_season"]).intValue && self.DetectedSeason >= 2) { // Season detected, check to see if there is a match. If not, continue.
                                continue;
                            }
                        }
                    }
            }
            else if (matchstatus == NoMatch) {
                continue;
            }
            //Return titleid if episode is valid
            int episodes = !searchentry[@"episodes"] ? 0 : ((NSNumber *)searchentry[@"episodes"]).intValue;
            if (episodes == 0 || ((episodes >= self.DetectedEpisode.intValue) && self.DetectedEpisode.intValue > 0)) {
                bool matchestitle = matchstatus == PrimaryTitleMatch ? [term caseInsensitiveCompare:theshowtitle] == NSOrderedSame : [term caseInsensitiveCompare:alttitle] == NSOrderedSame;
                if (((NSNumber *)searchentry[@"parsed_season"]).intValue >= 2 && ((NSNumber *)searchentry[@"parsed_season"]).intValue != self.DetectedSeason && !matchestitle) {
                    continue;
                }
                NSLog(@"Valid Episode Count");
                if (sortedArray.count == 1 || self.DetectedSeason >= 2) {
                    // Only Result, return
                    return [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                }
                else if (episodes >= self.DetectedEpisode.intValue && !titlematch1 && sortedArray.count > 1 && ((term.length < theshowtitle.length+1)||(term.length< alttitle.length+1 && alttitle.length > 0 && matchstatus == AlternateTitleMatch))) {
                    mstatus = matchstatus;
                    titlematch1 = searchentry;
                    continue;
                }
                else if (titlematch1 && (episodes >= self.DetectedEpisode.intValue || episodes == 0)) {
                    titlematch2 = searchentry;
                    return titlematch1 != titlematch2 ? [self comparetitle:term match1:titlematch1 match2:titlematch2 mstatus:mstatus mstatus2:matchstatus] : [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
                }
                else {
                    if ([NSUserDefaults.standardUserDefaults boolForKey:@"UseAnimeRelations"]) {
                        int newid = [self checkAnimeRelations:((NSNumber *)searchentry[@"id"]).intValue];
                        if (newid > 0) {
                            [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                            return @(newid).stringValue;
                        }
                    }
                    // Only Result, return
                    return [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                }
            }
            else if ((episodes < self.DetectedEpisode.intValue) && self.DetectedEpisode.intValue > 0) {
                // Check Relations
                if ([NSUserDefaults.standardUserDefaults boolForKey:@"UseAnimeRelations"]) {
                    int newid = [self checkAnimeRelations:((NSNumber *)searchentry[@"id"]).intValue];
                    if (newid > 0) {
                        [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                        return @(newid).stringValue;
                    }
                    else {
                        if ([self checkAnimeRelationsForExisting:((NSNumber *)searchentry[@"id"]).intValue]) {
                            [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                            return @(newid).stringValue;
                        }
                        else {
                            continue;
                        }
                    }
                }
            }
            else {
                // Detected episodes exceed total episodes
                continue;
            }
            
        }
    }
    // If one match is found and not null, then return the id.
    return titlematch1 ? [self foundtitle:[NSString stringWithFormat:@"%@",titlematch1[@"id"]] info:titlematch1] : @"";
    // Nothing found, return empty string
    return @"";
}
- (NSArray *)filterArray:(NSArray *)searchdata {
    NSMutableArray * sortedArray;
    // Filter array based on if the title is a movie or if there is a season detected
    if (self.DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)" , @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
    }
    else if (self.DetectedTitleisEpisodeZero) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(title CONTAINS %@) AND (type ==[c] %@)" , @"Episode 0", @"TV"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
    }
    else {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV Short"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
        if (self.DetectedSeason == 1 | self.DetectedSeason == 0) {
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
        }
    }
    return sortedArray;
}
- (NSString *)comparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b {
    // Perform string score between two titles to see if one is the correct match or not
    float score1, score2, ascore1, ascore2;
    double fuzziness = 0.3;
    int season1 = ((NSNumber *)match1[@"parsed_season"]).intValue;
    int season2 = ((NSNumber *)match2[@"parsed_season"]).intValue;
    //Score first title
    score1 = string_fuzzy_score([NSString stringWithFormat:@"%@",match1[@"title"]].UTF8String, title.UTF8String, fuzziness);
    ascore1 = string_fuzzy_score([NSString stringWithFormat:@"%@", ((NSArray *)match1[@"other_titles"][@"english"]).count > 0 ? match1[@"other_titles"][@"english"][0] : ((NSArray *)match1[@"other_titles"][@"japanese"]).count ? match1[@"other_titles"][@"japanese"][0] : @""].UTF8String, title.UTF8String, fuzziness);
    // Check for NaN. If Nan, use a negative number
    ascore1 = isnan(ascore1) ? -1 : ascore1;
    NSLog(@"match 1: %@ - %f alt: %f", match1[@"title"], score1, ascore1 );
    //Score Second Title
    score2 = string_fuzzy_score([NSString stringWithFormat:@"%@",match2[@"title"]].UTF8String, title.UTF8String, fuzziness);
    ascore2 = string_fuzzy_score([NSString stringWithFormat:@"%@", ((NSArray *)match2[@"other_titles"][@"english"]).count > 0 ? match2[@"other_titles"][@"english"][0] : ((NSArray *)match2[@"other_titles"][@"japanese"]).count ? match2[@"other_titles"][@"japanese"][0] : @""].UTF8String, title.UTF8String, fuzziness);
    // Check for NaN. If Nan, use a negative number
    ascore2 = isnan(ascore2) ? -1 : ascore2;
    NSLog(@"match 2: %@ - %f alt: %f", match2[@"title"], score2, ascore2 );
    //First Season Score Bonus
    if (self.DetectedSeason == 0 || self.DetectedSeason == 1) {
        if ([(NSString *)match1[@"title"] rangeOfString:@"First"].location != NSNotFound || [(NSString *)match1[@"title"] rangeOfString:@"1st"].location != NSNotFound) {
            score1 = score1 + .25;
            ascore1 = ascore1 + .25;
        }
        else if ([(NSString *)match2[@"title"] rangeOfString:@"First"].location != NSNotFound || [(NSString *)match2[@"title"] rangeOfString:@"1st"].location != NSNotFound) {
            score2 = score2 + .25;
            ascore2 = ascore2 + .25;
        }
    }
    //Season Scoring Calculation
    if (season1 != self.DetectedSeason) {
        ascore1 = ascore1 - .5;
        score1 = score1 - .5;
    }
    if (season2 != self.DetectedSeason) {
        ascore2 = ascore2 - .5;
        score2 = score2 - .5;
    }
    
    // Take the highest of both matches scores
    float finalscore1 = score1 > ascore1 ? score1 : ascore1;
    float finalscore2 = score2 > ascore2 ? score2 : ascore2;
    // Compare Scores
    if (finalscore1 == finalscore2 || finalscore1 == INFINITY) {
        //Scores can't be reliably compared, just return the first match
        return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"id"]] info:match1];
    }
    else if(finalscore1 > finalscore2)
    {
        //Return first title as it has a higher score
        return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"id"]] info:match1];
    }
    else {
        // Return second title since it has a higher score
        return [self foundtitle:[NSString stringWithFormat:@"%@",match2[@"id"]] info:match2];
    }
}
- (NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found {
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    //Save AniID
    NSNumber * totalepisodes;
    totalepisodes = found[@"episodes"] ? (NSNumber *)found[@"episodes"] : @(0);
    [self addtoCache:self.DetectedTitle actualtitle:(NSString *)found[@"title"] showid:titleid detectedSeason:self.DetectedSeason totalepisodes: totalepisodes.intValue withService:[listservice.sharedInstance getCurrentServiceID]];
    //Return the AniID
    return titleid;
}
- (NSDictionary *)checkMatch:(NSString *)title
                   alttitles:(NSArray *)atitles
                      regex:(OnigRegexp *)regex
                     option:(int)i{
              //Checks for matches
              if ([regex search:title].strings.count > 0) {
                  return @{@"matchstatus" : @(PrimaryTitleMatch), @"matchedtitle" : title};
              }
              else if (i==1) {
                  for (NSString *atitle in atitles) {
                      NSString *atmptitle = [atitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                      atmptitle = [atmptitle stringByReplacingOccurrencesOfString:@" - " withString:@" "];
                      atmptitle = [atmptitle stringByReplacingOccurrencesOfString:@" -" withString:@" "];
                      atmptitle = [atmptitle stringByReplacingOccurrencesOfString:@"-" withString:@" "];
                      atmptitle = [atmptitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                      if ([regex search:atmptitle].strings.count > 0) {
                          return @{@"matchstatus" : @(AlternateTitleMatch), @"matchedtitle" : atmptitle};
                      }
                  }
              }
              return @{@"matchstatus" : @(NoMatch)};
}

- (void)addtoCache:(NSString *)title actualtitle:(NSString *)atitle showid:(NSString *)showid detectedSeason:(int)season totalepisodes:(int)totalEpisodes withService:(int)service {
    [_moc performBlockAndWait:^{
        //Adds ID to cache
        // Add to Cache in Core Data
        NSManagedObject *obj = [NSEntityDescription
                                insertNewObjectForEntityForName :@"ScrobbleCache"
                                inManagedObjectContext: self.moc];
        // Set values in the new record
        [obj setValue:atitle forKey:@"actualtitle"];
        [obj setValue:title forKey:@"title"];
        [obj setValue:@(showid.intValue) forKey:@"titleid"];
        [obj setValue:@(totalEpisodes) forKey:@"totalEpisodes"];
        [obj setValue:@(season) forKey:@"season"];
        [obj setValue:@(service) forKey:@"service"];
        NSError *error = nil;
        // Save
        [self.moc save:&error];
    }];
}

- (void)checkCache {
    [_moc performBlockAndWait:^{
        NSFetchRequest *allCaches = [[NSFetchRequest alloc] init];
        allCaches.entity = [NSEntityDescription entityForName:@"ScrobbleCache" inManagedObjectContext:self.moc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title == %@  AND service == %i", self.DetectedTitle, [listservice.sharedInstance getCurrentServiceID]];
        allCaches.predicate = predicate;
        NSError *error = nil;
        NSArray *cache = [self.moc executeFetchRequest:allCaches error:&error];
        if (cache.count > 0) {
            for (NSManagedObject *cacheentry in cache) {
                NSString *title = [cacheentry valueForKey:@"title"];
                NSNumber *season = [cacheentry valueForKey:@"season"];
                if ([title isEqualToString:self.DetectedTitle] && self.DetectedSeason == season.intValue) {
                    NSLog(@"%@", season.intValue > 1 ? [NSString stringWithFormat:@"%@ Season %i is found in cache.", title, season.intValue] : [NSString stringWithFormat:@"%@ is found in cache.", title]);
                    // Total Episode check
                    NSNumber *totalepisodes = [cacheentry valueForKey:@"totalEpisodes"];
                    if ( self.DetectedEpisode.intValue <= totalepisodes.intValue || totalepisodes.intValue == 0 ) {
                        self.titleid = ((NSNumber *)[cacheentry valueForKey:@"titleid"]).stringValue;
                        return;
                    }
                    else {
                        // Check Anime Relations
                        int newid = [self checkAnimeRelations:((NSNumber *)[cacheentry valueForKey:@"titleid"]).intValue];
                        if (newid > 0) {
                            NSLog(@"Using Anime Relations mapping id...");
                            self.titleid =  @(newid).stringValue;
                            return;
                        }
                    }
                }
            }
        }
    }];
}

@end
