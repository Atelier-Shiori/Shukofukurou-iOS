//
//  SearchTabViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/30.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnimeSearchRootViewController.h"
#import "MangaSearchRootViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchTabViewController : UITabBarController
@property (strong) AnimeSearchRootViewController *animesearchrootvc;
@property (strong) MangaSearchRootViewController *mangasearchrootvc;
@end

NS_ASSUME_NONNULL_END
