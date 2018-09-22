//
//  SeasonCollectionViewCell.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeasonCollectionViewCell : UICollectionViewCell
@property (strong) IBOutlet UIImageView *posterimage;
@property (strong, nonatomic) IBOutlet UILabel *title;
- (void)loadimage:(NSString *)imageurl;
@end

NS_ASSUME_NONNULL_END
