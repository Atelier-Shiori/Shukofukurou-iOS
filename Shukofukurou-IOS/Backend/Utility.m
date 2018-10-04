//
//  Utility.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/15.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "Utility.h"
#import <AFNetworking/AFNetworking.h>
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>
@implementation Utility
+ (NSString *)urlEncodeString:(NSString *)string {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (__bridge CFStringRef)string,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8 ));
}

+ (NSString *)appendstringwithArray:(NSArray *) a {
    NSMutableString *string = [NSMutableString new];
    for (int i=0; i < a.count; i++) {
        if (i == a.count-1 && i != 0) {
            [string appendString:[NSString stringWithFormat:@"and %@",(NSString *)a[i]]];
        }
        else if (a.count == 1) {
            [string appendString:[NSString stringWithFormat:@"%@",(NSString *)a[i]]];
        }
        else {
            [string appendString:[NSString stringWithFormat:@"%@, ",(NSString *)a[i]]];
        }
    }
    return (NSString *)string;
}

+ (NSString *)statusFromDateRange:(NSString *)start toDate:(NSString *)end {
    bool startedairing = false;
    bool finishedairing = false;
    NSDate * datenow = [NSDate date];
    NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
    dateformat.dateFormat = @"yyyy-MM-dd";
    if (start.length == 7 && start) {
        start = [NSString stringWithFormat:@"%@-01",start];
    }
    if (start) {
        NSDate * startdate = [dateformat dateFromString:start];
        if ([datenow compare:startdate] == NSOrderedDescending || [datenow compare:startdate] == NSOrderedSame) {
            startedairing = true;
        }
    }
    if (end.length > 7 && end) {
        end = [NSString stringWithFormat:@"%@-01",end];
    }
    if (end) {
        NSDate * enddate = [dateformat dateFromString:end];
        if ([datenow compare:enddate] == NSOrderedDescending || [datenow compare:enddate] == NSOrderedSame) {
            finishedairing = true;
        }
    }
    // Generate Status String
    if (!startedairing && !finishedairing) {
        return @"not yet aired";
    }
    else if (startedairing && finishedairing) {
        return @"finished airing";
    }
    return @"currently airing";
}


+ (NSDate *)stringDatetoDate:(NSString *)stringdate {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init] ;
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    return [dateFormatter dateFromString:stringdate];
}

+ (NSString *)stringDatetoLocalizedDateString:(NSString *)stringdate {
    return [NSDateFormatter localizedStringFromDate:[Utility stringDatetoDate:stringdate]
                                          dateStyle: NSDateFormatterShortStyle
                                          timeStyle: NSDateFormatterNoStyle];
}
+ (AFHTTPSessionManager*)jsonmanager {
    static dispatch_once_t jonceToken;
    static AFHTTPSessionManager *jmanager = nil;
    if (jmanager) {
        [jmanager.requestSerializer clearAuthorizationHeader];
        jmanager.requestSerializer = [Utility httprequestserializer];
        jmanager.responseSerializer =  [Utility jsonresponseserializer];
    }
    dispatch_once(&jonceToken, ^{
        jmanager = [AFHTTPSessionManager manager];
        jmanager.requestSerializer = [Utility httprequestserializer];
        jmanager.responseSerializer =  [Utility jsonresponseserializer];
    });
    return jmanager;
}
+ (AFHTTPSessionManager*)httpmanager {
    static dispatch_once_t hmonceToken;
    static AFHTTPSessionManager *hmanager = nil;
    if (hmanager) {
        [hmanager.requestSerializer clearAuthorizationHeader];
        hmanager.requestSerializer = [Utility httprequestserializer];
        hmanager.responseSerializer =  [Utility httpresponseserializer];
    }
    dispatch_once(&hmonceToken, ^{
        hmanager = [AFHTTPSessionManager manager];
        hmanager.requestSerializer = [Utility httprequestserializer];
        hmanager.responseSerializer =  [Utility httpresponseserializer];
    });
    return hmanager;
}
+ (AFHTTPSessionManager*)syncmanager {
    static dispatch_once_t synconceToken;
    static AFHTTPSessionManager *syncmanager = nil;
    if (syncmanager) {
        [syncmanager.requestSerializer clearAuthorizationHeader];
        syncmanager.requestSerializer = [Utility httprequestserializer];
        syncmanager.responseSerializer = [Utility jsonresponseserializer];
    }
    dispatch_once(&synconceToken, ^{
        syncmanager = [AFHTTPSessionManager manager];
        syncmanager.requestSerializer = [Utility httprequestserializer];
        syncmanager.responseSerializer = [Utility jsonresponseserializer];
        syncmanager.completionQueue = dispatch_queue_create("moe.ateliershiori.Shukofukurou", DISPATCH_QUEUE_CONCURRENT);
    });
    return syncmanager;
}
+ (AFJSONRequestSerializer *)jsonrequestserializer {
    static dispatch_once_t jronceToken;
    static AFJSONRequestSerializer *jsonrequest = nil;
    dispatch_once(&jronceToken, ^{
        jsonrequest = [AFJSONRequestSerializer serializer];
    });
    switch ((int)[NSUserDefaults.standardUserDefaults integerForKey:@"currentservice"]) {
        case 2:
            [jsonrequest setValue:@"application/vnd.api+json" forHTTPHeaderField:@"Content-Type"];
            break;
        default:
            [jsonrequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            break;
    }
    return jsonrequest;
}
+ (AFHTTPRequestSerializer *)httprequestserializer {
    static dispatch_once_t hronceToken;
    static AFHTTPRequestSerializer *httprequest = nil;
    dispatch_once(&hronceToken, ^{
        httprequest = [AFHTTPRequestSerializer serializer];
    });
    return httprequest;
}
+ (AFJSONResponseSerializer *)jsonresponseserializer {
    static dispatch_once_t jonceToken;
    static AFJSONResponseSerializer *jsonresponse = nil;
    dispatch_once(&jonceToken, ^{
        jsonresponse = [AFJSONResponseSerializer serializer];
        jsonresponse.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"application/vnd.api+json", @"text/javascript", @"text/html", @"text/plain", nil];
    });
    return jsonresponse;
}
+ (AFHTTPResponseSerializer *)httpresponseserializer {
    static dispatch_once_t honceToken;
    static AFHTTPResponseSerializer *httpresponse = nil;
    dispatch_once(&honceToken, ^{
        httpresponse = [AFHTTPResponseSerializer serializer];
    });
    return httpresponse;
}

+ (double)calculatedays:(NSArray *)list {
    double duration = 0;
    for (NSDictionary *entry in list) {
        duration += ((NSNumber *)entry[@"watched_episodes"]).integerValue * ((NSNumber *)entry[@"duration"]).intValue;
    }
    duration = (duration/60)/24;
    return duration;
}

+ (NSString *)dateIntervalToDateString:(double)timeinterval {
    NSDate *aDate = [NSDate dateWithTimeIntervalSince1970:timeinterval];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"YYYY-MM-dd";
    return [dateFormatter stringFromDate:aDate];
}

+ (NSString *)convertAnimeType:(NSString *)type {
    NSString *tmpstr = type.lowercaseString;
    if ([tmpstr isEqualToString: @"tv"]||[tmpstr isEqualToString: @"ova"]||[tmpstr isEqualToString: @"ona"]) {
        tmpstr = tmpstr.uppercaseString;
    }
    else {
        tmpstr = tmpstr.capitalizedString;
        tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"Tv" withString:@"TV"];
    }
    return tmpstr;
}

@end
