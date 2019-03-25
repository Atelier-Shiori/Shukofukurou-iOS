//
//  AnimeRelations.h
//  Shukofukurou-IOS
//
//  Created by 小鳥遊六花 on 5/7/18.
//

#import <UIKit/UIKit.h>

@interface AnimeRelations : NSObject
+ (instancetype)sharedInstance;
- (void)autoupdateRelations:(void (^)(bool success)) completionHandler;
- (void)updateRelations:(void (^)(bool success)) completionHandler;
- (NSArray *)retrieveRelationsEntriesForTitleID:(int)titleid withService:(int)service;
- (void)clearAnimeRelations;
@end
