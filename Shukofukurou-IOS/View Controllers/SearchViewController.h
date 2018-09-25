//
//  AnimeSearchViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/30.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchViewController : UITableViewController <UISearchBarDelegate>
typedef NS_ENUM(unsigned int, SearchMediaType) {
    AnimeSearchType = 0,
    MangaSearchType = 1
};
@property (weak, nonatomic) IBOutlet UINavigationItem *navitem;
@property (strong) NSMutableArray *searchArray;
@property int searchtype;
- (void)resetSearchUI;
@end

NS_ASSUME_NONNULL_END
