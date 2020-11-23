//
//  ListViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ListViewController : UITableViewController <UISearchBarDelegate, UITableViewDelegate>
typedef NS_ENUM(unsigned int, ListMediaType) {
    Anime = 0,
    Manga = 1
};
@property (strong) NSMutableArray *listArray;
@property int listtype;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationitem;
@property bool initalload;
@property (weak, nonatomic) IBOutlet UIRefreshControl *refreshcontrol;
- (void)setViewTitle;
- (void)reloadList;
- (void)refreshListWithCompletionHandler:(void (^)(bool success)) completionHandler;
- (void)retrieveList:(bool)refresh completion:(void (^)(bool success)) completionHandler;
- (void)switchlistservice;
- (void)clearlists;
@end

NS_ASSUME_NONNULL_END
