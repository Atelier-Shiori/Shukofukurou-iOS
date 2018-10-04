//
//  Utility.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/15.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AFHTTPSessionManager;
@class AFHTTPRequestSerializer;
@class AFJSONRequestSerializer;
@class AFJSONResponseSerializer;
@class AFHTTPResponseSerializer;

@interface Utility : NSObject
+ (NSString *)urlEncodeString:(NSString *)string;
+ (NSString *)appendstringwithArray:(NSArray *) a;
+ (NSString *)statusFromDateRange:(NSString *)start toDate:(NSString *)end;
+ (NSDate *)stringDatetoDate:(NSString *)stringdate;
+ (NSString *)stringDatetoLocalizedDateString:(NSString *)stringdate;
+ (AFHTTPSessionManager*)jsonmanager;
+ (AFHTTPSessionManager*)httpmanager;
+ (AFHTTPSessionManager*)syncmanager;
+ (AFJSONRequestSerializer *)jsonrequestserializer;
+ (AFHTTPRequestSerializer *)httprequestserializer;
+ (AFJSONResponseSerializer *)jsonresponseserializer;
+ (AFHTTPResponseSerializer *)httpresponseserializer;
+ (double)calculatedays:(NSArray *)list;
+ (NSString *)dateIntervalToDateString:(double)timeinterval;
+ (NSString *)convertAnimeType:(NSString *)type;

@end
