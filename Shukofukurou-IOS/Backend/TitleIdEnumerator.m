//
//  TitleIdEnumerator.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/12/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "TitleIdEnumerator.h"
#import "TitleIdConverter.h"

@implementation TitleIdEnumerator
- (instancetype) initWithList:(NSArray *)list withType:(int)type completion:(void (^)(TitleIdEnumerator *titleidenum))completionHandler {
    if ([super init]) {
        self.tmplist = list;
        self.type = type;
        _completionHandler = completionHandler;
    }
    return self;
}
- (void)generateTitleIdMappingList:(int)sourceserviceid toService:(int)targetserviceid {
    _currentposition = 0;
    _sourceserviceid = sourceserviceid;
    _targetserviceid = targetserviceid;
    [self performListConvert];
}
- (void)performListConvert {
    if (_currentposition == _tmplist.count) {
        NSLog(@"Complete");
        _completionHandler(self);
        return;
    }
    switch (_sourceserviceid) {
        case 1: {
            switch (_targetserviceid) {
                case 1: {
                    [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    break;
                }
                case 2: {
                    [TitleIdConverter getKitsuIDFromMALId:((NSNumber *)_tmplist[0][@"id"]).intValue withTitle:_tmplist[0][@"title"] titletype:_tmplist[0][@"type"] withType:_type completionHandler:^(int kitsuid) {
                        [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:kitsuid];
                    } error:^(NSError *error) {
                        [self titleidconvertFailure:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    }];
                    break;
                }
                case 3: {
                    [TitleIdConverter getAniIDFromMALListID:((NSNumber *)_tmplist[0][@"id"]).intValue withTitle:_tmplist[0][@"title"]  titletype:_tmplist[0][@"type"] withType:_type completionHandler:^(int anilistid) {
                        [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:anilistid];
                    } error:^(NSError *error) {
                        [self titleidconvertFailure:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    }];
                    break;
                }
            }
            break;
        }
        case 2: {
            switch (_targetserviceid) {
                case 1: {
                    [TitleIdConverter getMALIDFromKitsuId:((NSNumber *)_tmplist[0][@"id"]).intValue withTitle:_tmplist[0][@"title"] titletype:_tmplist[0][@"type"] withType:_type completionHandler:^(int malid) {
                        [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:malid];
                    } error:^(NSError *error) {
                        [self titleidconvertFailure:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    }];
                    break;
                }
                case 2: {
                    [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    break;
                }
                case 3: {
                    [TitleIdConverter getAniIDFromKitsuID:((NSNumber *)_tmplist[0][@"id"]).intValue withTitle:_tmplist[0][@"title"] titletype:_tmplist[0][@"type"] withType:_type completionHandler:^(int anilistid) {
                        [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:anilistid];
                    } error:^(NSError *error) {
                        [self titleidconvertFailure:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    }];
                    break;
                }
            }
            break;
        }
        case 3: {
            switch (_targetserviceid) {
                case 1: {
                    [TitleIdConverter getMALIDFromAniListID:((NSNumber *)_tmplist[0][@"id"]).intValue withTitle:_tmplist[0][@"title"] titletype:_tmplist[0][@"type"] withType:_type completionHandler:^(int malid) {
                        [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:malid];
                    } error:^(NSError *error) {
                        [self titleidconvertFailure:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    }];
                    break;
                }
                case 2: {
                    [TitleIdConverter getKitsuIdFromAniID:((NSNumber *)_tmplist[0][@"id"]).intValue withTitle:_tmplist[0][@"title"]  titletype:_tmplist[0][@"type"] withType:_type completionHandler:^(int kitsuid) {
                            [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:kitsuid];
                    } error:^(NSError *error) {
                        [self titleidconvertFailure:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    }];
                    break;
                }
                case 3: {
                    [self titleidconvertSuccess:((NSNumber *)self.tmplist[0][@"id"]).intValue withTargetid:((NSNumber *)self.tmplist[0][@"id"]).intValue];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void)titleidconvertSuccess:(int)sourceid withTargetid:(int)targetid {
    NSLog(@"Success. Source id: %i, Target id: %i", sourceid, targetid);
    [_titleidmap addObject:@{@"source_id" : @(sourceid), @"target_id" : @(targetid)}];
    _currentposition++;
    [self performListConvert];
}

- (void)titleidconvertFailure:(int)sourceid {
    NSLog(@"Failure. Source id: %i", sourceid);
    [_titleidmap addObject:@{@"source_id" : @(sourceid), @"target_id" : @(-1)}];
    _currentposition++;
    [self performListConvert];
}

- (int)findTargetIdFromSourceId:(int)sourceid {
    NSArray *filtered = [_titleidmap filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"source_id == %i", sourceid]];
    if (filtered.count > 0) {
        return ((NSNumber *)filtered[0]).intValue;
    }
    return -1;
}
@end
