//
//  EpisodesTableViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/5/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EpisodesTableViewController : UITableViewController
- (void)loadEpisodeListForTitleId:(int)titleid;
@end

NS_ASSUME_NONNULL_END
