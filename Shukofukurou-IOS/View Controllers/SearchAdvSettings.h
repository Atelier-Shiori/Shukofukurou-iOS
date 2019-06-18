//
//  SearchAdvSettings.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 5/20/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchAdvSettings : UITableViewController
@property int currentadvsearch;
@property int currentlistservice;
@property (strong) NSDictionary *advsearchoptions;
@property (nonatomic, copy) void (^completionHandler)(NSDictionary *advsearchoptions);
- (void)generateadvsearchdictionary;
- (void)populateSearchOptionsForType:(int)type;
- (void)generateSearchOptionsForType:(int)type;
@end

NS_ASSUME_NONNULL_END
