//
//  TitleInfoViewController.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/18/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TitleInfoViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property bool selectedaired;
@property bool selectedaircompleted;
@property bool selectedfinished;
@property bool selectedpublished;
@property bool selectedreconsuming;
- (void)loadTitleInfo:(int)titleid withType:(int)type;
- (void)populateInfoWithType:(int)type withDictionary:(NSDictionary *)titleinfo;
- (void)refreshTitleInfo;
- (void)checkUnsavedChangesWithBlock:(void (^)(void))actionBlock;
@end

NS_ASSUME_NONNULL_END
