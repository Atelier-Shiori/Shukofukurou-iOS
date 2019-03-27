//
//  ExportOperationManager.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/27/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExportOperationManager : NSObject
@property (strong) NSMutableArray *failedtitles;
@property (nonatomic, copy) void (^completion)(NSMutableArray *failedtitles, NSString *xml);
- (void)beginTitleIdBuildingForType:(int)mediatype;
@end

NS_ASSUME_NONNULL_END
