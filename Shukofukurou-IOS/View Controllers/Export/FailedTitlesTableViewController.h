//
//  FailedTitlesTableViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/26/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FailedTitlesTableViewController : UITableViewController
@property (strong) NSArray *failedexports;
- (void)showFailedMessage;
@end

NS_ASSUME_NONNULL_END
