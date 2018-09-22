//
//  SeasonSelectorTableViewController.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeasonSelectorTableViewController : UITableViewController
typedef NS_ENUM(unsigned int, SeasonSelectionType) {
    seasonselect = 0,
    yearselect = 1
};
@property (nonatomic, copy) void (^seasonChanged)(NSString *season);
@property (nonatomic, copy) void (^yearChanged)(int year);
@property (strong) NSString *selectedseason;
@property int year;
- (void)generateselectionitems:(int)selectiontype;
@end

NS_ASSUME_NONNULL_END
