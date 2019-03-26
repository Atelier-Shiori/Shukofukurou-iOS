//
//  MediaStreamParse.m
//  detectstream
//
//  Created by 高町なのは on 2015/02/09.
//  Copyright 2014-2018 Atelier Shiori, James Moy. All rights reserved. Code licensed under MIT License.
//

#import "MediaStreamParse.h"
#import "ezregex.h"

@implementation MediaStreamParse
+ (NSArray *)parse:(NSArray *)pages {
     NSMutableArray * final = [[NSMutableArray alloc] init];
    ezregex * ez = [[ezregex alloc] init];
    //Perform Regex and sanitize
    if (pages.count > 0) {
        for (NSDictionary *m in pages) {
            NSString * regextitle = [NSString stringWithFormat:@"%@",m[@"title"]];
            NSString * url = [NSString stringWithFormat:@"%@", m[@"url"]];
            NSString * site = [NSString stringWithFormat:@"%@", m[@"site"]];
            NSString * title = @"";
            NSString * tmpepisode = @"";
            NSString * tmpseason = @"";
            bool isManga = false;
            if ([site isEqualToString:@"crunchyroll"]) {
                //Add Regex Arguments Here
                if ([ez checkMatch:url pattern:@"[^/]+\\/episode-[0-9]+.*-[0-9]+"]||[ez checkMatch:url pattern:@"[^/]+\\/.*-movie-[0-9]+"]||[ez checkMatch:url pattern:@"[^/]+\\/.*-\\d+"]) {
                    //Perform Sanitation
                    regextitle = [ez searchreplace:regextitle pattern:@"Crunchyroll - Watch\\s"];
                    regextitle = [ez searchreplace:regextitle pattern:@"\\s-\\sMovie\\s-\\sMovie"];
                    tmpepisode = [ez findMatch:regextitle pattern:@"\\sEpisode (\\d+)" rangeatindex:0];
                    regextitle = [regextitle stringByReplacingOccurrencesOfString:tmpepisode withString:@""];
                    tmpepisode = [ez searchreplace:tmpepisode pattern:@"\\sEpisode"];
                    regextitle = [ez searchreplace:regextitle pattern:@"\\s-\\s*.*"];
                    title = regextitle;
                    if ([ez checkMatch:title pattern:@"Crunchyroll"]) {
                        continue;
                    }
                }
                else {
                      continue;
                }
            }
            else if ([site isEqualToString:@"hidive"]) {
                //Add Regex Arguments for hidive
                if ([ez checkMatch:url pattern:@"(stream\\/*.*\\/s\\d+e\\d+|stream\\/*.*\\/\\d+)"]) {
                    // Clean title
                    regextitle = [ez searchreplace:regextitle pattern:@"(Stream |\\sof| on HIDIVE)"];
                    if ([ez checkMatch:regextitle pattern:@"Episode \\d+"]) {
                        // Regular TV series
                        tmpseason = [ez findMatch:regextitle pattern:@"Season \\d+" rangeatindex:0];
                        regextitle = [regextitle stringByReplacingOccurrencesOfString:tmpseason withString:@""];
                        tmpseason = [tmpseason stringByReplacingOccurrencesOfString:@"Season " withString:@""];
                        tmpepisode = [ez findMatch:regextitle pattern:@"Episode \\d+" rangeatindex:0];
                        regextitle = [regextitle stringByReplacingOccurrencesOfString:tmpepisode withString:@""];
                        tmpepisode = [tmpepisode stringByReplacingOccurrencesOfString:@"Episode " withString:@""];
                        title = [regextitle stringByReplacingOccurrencesOfString:@"-" withString:@""];
                    }
                    else {
                        // Movie or OVA
                        tmpepisode = @"1";
                        tmpseason = @"1";
                        title = [ez searchreplace:regextitle pattern:@" - (OVA|Movie|Special)"];
                    }
                }
                else {
                    continue; // Invalid address
                }
            }
            else if ([site isEqualToString:@"vrv"]) {
                //Add Regex Arguments Here
                if ([ez checkMatch:url pattern:@"\\/watch\\/*.*\\/*.*"]) {
                    //Perform Sanitation
                    regextitle = [ez searchreplace:regextitle pattern:@" - Watch on VRV\\s"];
                    regextitle = [ez searchreplace:regextitle pattern:@"\\s-\\sMovie\\s-\\sMovie"];
                    tmpepisode = [ez findMatch:regextitle pattern:@"\\s(Episode) (\\d+)" rangeatindex:0];
                    regextitle = [regextitle stringByReplacingOccurrencesOfString:tmpepisode withString:@""];
                    tmpepisode = [ez searchreplace:tmpepisode pattern:@"\\s(Episode) "];
                    tmpseason  = [ez findMatch:regextitle pattern:@"Season (\\d+)" rangeatindex:0];
                    regextitle = [regextitle stringByReplacingOccurrencesOfString:tmpseason withString:@""];
                    tmpseason  = [ez searchreplace:tmpseason pattern:@"Season "];                    regextitle = [ez searchreplace:regextitle pattern:@"\\s-\\s*.*"];
                    title = regextitle;
                    if ([ez checkMatch:title pattern:@"VRV"]) {
                        continue;
                    }
                }
                else {
                    continue;
                }
            }
            else {
                continue;
            }
        
            NSNumber * episode;
            NSNumber * season;
            // Populate Season
            if (tmpseason.length == 0 && !isManga) {
                // Parse Season from title
                NSDictionary * seasondata = [MediaStreamParse checkSeason:title];
                if (seasondata != nil) {
                    season = (NSNumber *)seasondata[@"season"];
                    title = seasondata[@"title"];
                }
                else{
                   season = @(1);
                }
            }
            else {
                season = [[[NSNumberFormatter alloc] init] numberFromString:tmpseason];
            }
            //Trim Whitespace
            title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            tmpepisode = [tmpepisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            // Final Checks
            if ([tmpepisode length] ==0){
                episode = @(0);
            }
            else{
                episode = [[[NSNumberFormatter alloc] init] numberFromString:tmpepisode];
            }
            if (title.length == 0) {
                continue;
            }
            // Add to Final Array
            NSDictionary * frecord;
            if (!isManga) {
                frecord = @{@"title" :title, @"episode" : episode, @"season" : season, @"browser" : m[@"browser"], @"site" : site, @"type" : @"anime" };
            }
            else {
                 frecord = @{@"title" :title, @"chapter" : episode, @"browser" : m[@"browser"], @"site" : site, @"type" : @"manga" };
            }
            [final addObject:frecord];
        }
    }
    return final;
}
+ (NSDictionary *)checkSeason:(NSString *) title {
    // Parses season
    ezregex * ez = [ezregex new];
    NSString * tmpseason;
    NSDictionary * result;
    NSString * pattern = @"(\\d(st|nd|rd|th) season|season \\d|s\\d)";
    if ([ez checkMatch:title pattern:pattern]) {
        tmpseason = [ez findMatch:title pattern:pattern rangeatindex:0];
        title = [title stringByReplacingOccurrencesOfString:tmpseason withString:@""];
        tmpseason = [ez findMatch:tmpseason pattern:@"\\d+" rangeatindex:0];
        result = @{@"title": title, @"season": [[NSNumberFormatter alloc] numberFromString:tmpseason]};
        
    }
    pattern = @"(first|season|third|fourth|fifth) season";
    if ([ez checkMatch:title pattern:@"(first|season|third|fourth|fifth) season"] && tmpseason.length == 0) {
        tmpseason = [ez findMatch:title pattern:pattern rangeatindex:0];
        title = [title stringByReplacingOccurrencesOfString:tmpseason withString:@""];
        result = @{@"title": title, @"season": @([MediaStreamParse recognizeseason:tmpseason])};
    }
    return result;
}
+ (int)recognizeseason:(NSString *)season {
    if ([season caseInsensitiveCompare:@"second season"] == NSOrderedSame) {
        return 2;
    }
    else if ([season caseInsensitiveCompare:@"third season"] == NSOrderedSame) {
        return 3;
    }
    else if ([season caseInsensitiveCompare:@"fourth season"] == NSOrderedSame) {
        return 4;
    }
    else if ([season caseInsensitiveCompare:@"fifth season"] == NSOrderedSame) {
        return 5;
    }
    else {
        return 1;
    }
}

+ (NSArray *)generateCrunchyrollHistoryQueue:(NSString *)DOM {
    // Creates an array of titles and episodes from Crunchyroll history
    ezregex *regex = [ezregex new];
    NSString *tmpdom = [DOM stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSMutableArray *tmparray = [NSMutableArray new];
    NSArray *matches = [regex findMatches:tmpdom pattern:@"<li class=\"group-item hover-bubble\" id=\"media_group_\\d+\" group_id=\"media_group_\\d+\">(.*?)<\\/li>"];
    for (NSString *item in matches) {
        if ([regex checkMatch:item pattern:@"<span itemprop=\"name\" class=\"series-title block ellipsis\">(.*?)<\\/span>"]) {
            NSString *title = [regex findMatch:item pattern:@"<span itemprop=\"name\" class=\"series-title block ellipsis\">(.*?)<\\/span>" rangeatindex:0];
            title = [title stringByReplacingOccurrencesOfString:@"<span itemprop=\"name\" class=\"series-title block ellipsis\">" withString:@""];
            title = [title stringByReplacingOccurrencesOfString:@"</span>" withString:@""];
            NSString *episode = @"1";
            if ([regex checkMatch:item pattern:@"Episode \\d+"]) {
                episode = [regex findMatch:item pattern:@"Episode \\d+" rangeatindex:0];
                episode = [episode stringByReplacingOccurrencesOfString:@"Episode " withString:@""];
            }
            [tmparray addObject:@{@"title":title, @"episode":episode}];
        }
        else {
            continue;
        }
    }
    return tmparray;
    
}
@end
