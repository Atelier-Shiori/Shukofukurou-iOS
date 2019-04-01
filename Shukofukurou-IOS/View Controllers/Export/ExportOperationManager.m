//
//  ExportOperationManager.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/27/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "ExportOperationManager.h"
#import "TitleIDMapper.h"
#import "listservice.h"
#import "AtarashiiListCoreData.h"
#import "RatingTwentyConvert.h"
#import <MBProgressHudFramework/MBProgressHUD.h>

@interface ExportOperationManager ()
@property (strong) NSArray *tmplist;
@property (strong) NSMutableArray *finallist;
@property int arrayposition;
@property int mediatype;
@property (strong) TitleIDMapper *mapper;
@property (strong) listservice *lservice;
@property bool paused;
@property bool active;
@end

@implementation ExportOperationManager
- (instancetype)init {
    if (self = [super init]) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(wentToBackground:) name:@"enteredBackground" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(becameActive:) name:@"becameActive" object:nil];
        _mapper = [TitleIDMapper new];
        _lservice = listservice.sharedInstance;
        _failedtitles = [NSMutableArray new];
        _finallist = [NSMutableArray new];
        _active = false;
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)wentToBackground:(NSNotification *)notification {
    NSLog(@"Paused");
    _paused = true;
}

- (void)becameActive:(NSNotification *)notification {
    NSLog(@"Active");
    _paused = false;
    if (_active) {
        NSLog(@"Resume building of MAL List entries.");
        [self performBuildMappings];
    }
}

- (void)beginTitleIdBuildingForType:(int)mediatype {
    _active = true;
    _mediatype = mediatype;
    switch (_lservice.getCurrentServiceID) {
        case 2:
        case 3:
            _tmplist = [AtarashiiListCoreData retrieveEntriesForUserId:_lservice.getCurrentUserID withService:_lservice.getCurrentServiceID withType:mediatype][mediatype == 0 ? @"anime" : @"manga"];
            break;
    }
    [self performBuildMappings];
}

- (void)performBuildMappings {
    if (_paused) {
        return;
    }
    self.hud.label.text = [NSString stringWithFormat:@"Retrieving Mappings: %i/%lu", _arrayposition+1, (unsigned long)_tmplist.count];
    [_mapper retrieveTitleIdForService:_lservice.getCurrentServiceID withTitleId:_tmplist[_arrayposition][@"id"] withTargetServiceId:1 withType:_mediatype completionHandler:^(id  _Nonnull titleid, bool success) {
        if (!success) {
            [self.failedtitles addObject:self.tmplist[self.arrayposition]];
        }
        else {
            switch (self.lservice.getCurrentServiceID) {
                case 2:
                    [self convertKitsuEntryToMALWithTitleID:((NSNumber *)titleid).intValue];
                    break;
                case 3:
                    [self convertAniListEntryToMALWithTitleID:((NSNumber *)titleid).intValue];
                    break;
                default:
                    break;
            }
        }
        self.arrayposition++;
        if (self.arrayposition == self.tmplist.count) {
            NSLog(@"Conversion complete. Generating XML.");
            self.hud.label.text = @"Generating XML...";
            NSString *xmlstring = self.mediatype == 0 ? [self generateAnimeListXML:self.finallist] : [self generateMangaListXML:self.finallist];
            self.completion(self.failedtitles, xmlstring);
            self.active = false;
        }
        else {
            [self performBuildMappings];
        }
    }];
}

- (void)convertKitsuEntryToMALWithTitleID:(int)maltitleid {
    NSMutableDictionary *currententry = [self.tmplist[self.arrayposition] mutableCopy];
    currententry[@"id"] = @(maltitleid);
    currententry[@"score"] = @([RatingTwentyConvert translateKitsuTwentyScoreToMAL:((NSNumber *)currententry[@"score"]).intValue]);
    [self.finallist addObject:[self convertToMALXMLDictionary:currententry]];
}

- (void)convertAniListEntryToMALWithTitleID:(int)maltitleid {
    NSMutableDictionary *currententry = [self.tmplist[self.arrayposition] mutableCopy];
    currententry[@"id"] = @(maltitleid);
    currententry[@"score"] = @((((NSNumber *)currententry[@"score"]).intValue)/10);
    [self.finallist addObject:[self convertToMALXMLDictionary:currententry]];
}

- (NSString *)generateAnimeListXML:(NSArray *)a {
    NSString *headerstring = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n\t<!--\n\tCreated by Shukofukurou for iOS\n\tProgrammed by MAL Updater OS X Group Software (James Moy), a division of Moy IT Solutions \n\tNote that not all values are exposed by the API and not all fields will be exported.\n\t--> \n\n\t<myanimelist>";
    NSString *footerstring = @"\n\n\t</myanimelist>";
    NSString *animepretag = @"\n\n\t\t<anime>";
    NSString *animeendtag = @"\n\t\t</anime>";
    NSString *tabformatting = @"\n\t\t\t";
    NSMutableString *output = [NSMutableString new];
    [output appendString:headerstring];
    [output appendString:@"\n\n\t<myinfo>"];
    switch ([_lservice getCurrentServiceID]) {
        case 2:
        case 3:
            [output appendFormat:@"%@<username>%@</username>",tabformatting, [_lservice getCurrentServiceUsername]];
            break;
        default:
            break;
    }
    [output appendFormat:@"%@<user_export_type>1</user_export_type>",tabformatting];
    [output appendString:@"\n\t</myinfo>"];
    for (NSDictionary *d in a) {
        NSString *fstatus = [self fixstatus:d[@"my_status"]];
        [output appendString:animepretag];
        [output appendFormat:@"%@<series_animedb_id>%@</series_animedb_id>",tabformatting,d[@"series_animedb_id"]];
        [output appendFormat:@"%@<series_title><![CDATA[%@]]></series_title>",tabformatting,d[@"series_title"]];
        [output appendFormat:@"%@<series_type>%@</series_type>",tabformatting,d[@"series_type"]];
        [output appendFormat:@"%@<series_episodes>%@</series_episodes>",tabformatting,d[@"series_episodes"]];
        [output appendFormat:@"%@<my_id>0</my_id>",tabformatting];
        [output appendFormat:@"%@<my_watched_episodes>%@</my_watched_episodes>",tabformatting,d[@"my_watched_episodes"]];
        [output appendFormat:@"%@<my_start_date>%@</my_start_date>", tabformatting, d[@"my_start_date"]];
        [output appendFormat:@"%@<my_finish_date>%@</my_finish_date>", tabformatting, d[@"my_finish_date"]];
        [output appendFormat:@"%@<my_rated></my_rated>",tabformatting];
        [output appendFormat:@"%@<my_score>%@</my_score>",tabformatting,d[@"my_score"]];
        [output appendFormat:@"%@<my_dvd></my_dvd>", tabformatting];
        [output appendFormat:@"%@<my_storage></my_storage>", tabformatting];
        [output appendFormat:@"%@<my_status>%@</my_status>",tabformatting,fstatus];
        [output appendFormat:@"%@<my_comments><![CDATA[%@]]></my_comments>",tabformatting, d[@"my_comments"]];
        [output appendFormat:@"%@<my_times_watched>%i</my_times_watched>",tabformatting, ((NSNumber *)d[@"rewatch_count"]).intValue];
        [output appendFormat:@"%@<my_rewatch_value></my_rewatch_value>",tabformatting];
        [output appendFormat:@"%@<my_tags><![CDATA[%@]]></my_tags>",tabformatting,d[@"my_tags"]];
        [output appendFormat:@"%@<my_rewatching>%i</my_rewatching>",tabformatting,((NSNumber *)d[@"my_rewatching"]).intValue];
        [output appendFormat:@"%@<my_rewatching_ep>0</my_rewatching_ep>", tabformatting];
        [output appendFormat:@"%@<update_on_import>%i</update_on_import>",tabformatting,[self setUpdateonImport:fstatus]];
        [output appendString:animeendtag];
    }
    [output appendString:footerstring];
    return output;
}

- (NSString *)generateMangaListXML:(NSArray *)a {
    NSString *headerstring = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n\t<!--\n\tCreated by Shukofukurou for iOS\n\tProgrammed by MAL Updater OS X Group (James Moy) \n\tNote that not all values are exposed by the API and not all fields will be exported.\n\t--> \n\n\t<myanimelist>";
    NSString *footerstring = @"\n\n\t</myanimelist>";
    NSString *mangapretag = @"\n\n\t\t<manga>";
    NSString *mangaendtag = @"\n\t\t</manga>";
    NSString *tabformatting = @"\n\t\t\t";
    NSMutableString *output = [NSMutableString new];
    [output appendString:headerstring];
    [output appendString:@"\n\n\t<myinfo>"];
    switch ([_lservice getCurrentServiceID]) {
        case 2:
        case 3:
            [output appendFormat:@"%@<username>%@</username>",tabformatting, [_lservice getCurrentServiceUsername]];
            break;
        default:
            break;
    }
    [output appendFormat:@"%@<user_export_type>2</user_export_type>",tabformatting];
    [output appendString:@"\n\t</myinfo>"];
    for (NSDictionary *d in a) {
        NSString *fstatus = [self fixstatus:d[@"my_status"]];
        [output appendString:mangapretag];
        [output appendFormat:@"%@<manga_mangadb_id>%@</manga_mangadb_id>",tabformatting,d[@"manga_mangadb_id"]];
        [output appendFormat:@"%@<manga_title><![CDATA[%@]]></manga_title>",tabformatting,d[@"manga_title"]];
        [output appendFormat:@"%@<manga_volumes>%@</manga_volumes>",tabformatting,d[@"manga_volumes"]];
        [output appendFormat:@"%@<manga_chapters>%@</manga_chapters>",tabformatting,d[@"manga_chapters"]];
        [output appendFormat:@"%@<my_id>0</my_id>",tabformatting];
        [output appendFormat:@"%@<my_read_volumes>%@</my_read_volumes>",tabformatting,d[@"my_read_volumes"]];
        [output appendFormat:@"%@<my_read_chapters>%@</my_read_chapters>",tabformatting,d[@"my_read_chapters"]];
        [output appendFormat:@"%@<my_start_date>%@</my_start_date>", tabformatting, d[@"my_start_date"]];
        [output appendFormat:@"%@<my_finish_date>%@</my_finish_date>", tabformatting, d[@"my_finish_date"]];
        [output appendFormat:@"%@<my_scanalation_group><![CDATA[]]></my_scanalation_group>",tabformatting];
        [output appendFormat:@"%@<my_score>%@</my_score>",tabformatting,d[@"my_score"]];
        [output appendFormat:@"%@<my_storage></my_storage>", tabformatting];
        [output appendFormat:@"%@<my_status>%@</my_status>",tabformatting,fstatus];
        [output appendFormat:@"%@<my_comments><![CDATA[%@]]></my_comments>",tabformatting, d[@"my_comments"]];
        [output appendFormat:@"%@<my_times_read>%i</my_times_read>",tabformatting,((NSNumber *)d[@"my_times_read"]).intValue];
        [output appendFormat:@"%@<my_tags><![CDATA[%@]]></my_tags>",tabformatting,d[@"my_tags"]];
        [output appendFormat:@"%@<my_reread_value></my_reread_value>", tabformatting];
        [output appendFormat:@"%@<update_on_import>%i</update_on_import>",tabformatting,[self setUpdateonImport:fstatus]];
        [output appendString:mangaendtag];
    }
    [output appendString:footerstring];
    return output;
}

- (NSString *)fixstatus:(NSString *)status {
    NSString *tmpstr = [status capitalizedString];
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@" To " withString:@" to "];
    return tmpstr;
}

- (int)setUpdateonImport:(NSString *)status {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (([defaults boolForKey:@"updateonimportcurrent"] && ([status isEqualToString:@"Watching"] || [status isEqualToString:@"Reading"])) || ([defaults boolForKey:@"updateonimportcompleted"] && [status isEqualToString:@"Completed"]) || ([defaults boolForKey:@"updateonimportonhold"] && [status isEqualToString:@"On-Hold"]) ||([defaults boolForKey:@"updateonimportdropped"] && [status isEqualToString:@"Dropped"]) ||([defaults boolForKey:@"updateonimportplanned"] && ([status isEqualToString:@"Plan to Watch"] || [status isEqualToString:@"Plan to Read"])) ) {
        return 1;
    }
    return 0;
}

- (NSDictionary *)convertToMALXMLDictionary:(NSDictionary *)d {
    if (_mediatype == 0) {
        return @{@"series_animedb_id":d[@"id"], @"series_title":d[@"title"],@"series_type":d[@"type"], @"series_episodes":d[@"episodes"], @"my_watched_episodes":d[@"watched_episodes"], @"my_score":d[@"score"], @"my_status":d[@"watched_status"], @"my_tags":d[@"personal_tags"] && d[@"personal_tags"] != [NSNull null] ? [d[@"personal_tags"] componentsJoinedByString:@","] : @"", @"my_start_date" : d[@"watching_start"] && ((NSString *)d[@"watching_start"]).length > 0 ? d[@"watching_start"] : @"0000-00-00",  @"my_finish_date" : d[@"watching_end"] && ((NSString *)d[@"watching_end"]).length > 0 ? d[@"watching_end"] : @"0000-00-00", @"my_comments" : d[@"personal_comments"] && d[@"personal_comments"] != [NSNull null] ? d[@"personal_comments"] : @"", @"my_times_rewatched" : d[@"rewatch_count"] ? d[@"rewatch_count"]  : @(0), @"my_rewatching" : d[@"rewatching"]};
    }
    else {
        return @{@"manga_mangadb_id":d[@"id"], @"manga_title":d[@"title"], @"manga_volumes":d[@"volumes"], @"manga_chapters":d[@"chapters"], @"my_read_volumes":d[@"volumes_read"],@"my_read_chapters":d[@"chapters_read"], @"my_score":d[@"score"], @"my_status":d[@"read_status"], @"my_tags":d[@"personal_tags"]  && d[@"personal_tags"] != [NSNull null] ? [d[@"personal_tags"] componentsJoinedByString:@","] : @"", @"my_start_date" : d[@"reading_start"] && ((NSString *)d[@"reading_start"]).length > 0 ? d[@"reading_start"] : @"0000-00-00",  @"my_finish_date" : d[@"reading_end"] && ((NSString *)d[@"reading_end"]).length > 0 ? d[@"reading_end"] : @"0000-00-00", @"my_comments" : d[@"personal_comments"] && d[@"personal_comments"] != [NSNull null] ? d[@"personal_comments"] : @"", @"my_times_read" : d[@"reread_count"] ? d[@"reread_count"]  : @(0)};
    }
}
@end
