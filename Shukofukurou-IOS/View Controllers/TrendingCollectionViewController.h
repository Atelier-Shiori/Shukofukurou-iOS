//
//  TrendingCollectionViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/6/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TrendingCollectionViewController : UICollectionViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeselector;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menubtn;
- (void)loadretrieving;
@end

NS_ASSUME_NONNULL_END
