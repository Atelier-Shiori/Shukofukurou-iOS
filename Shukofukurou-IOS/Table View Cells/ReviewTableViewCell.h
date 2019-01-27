//
//  ReviewTableViewCell.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/1/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReviewTableViewCell : UITableViewCell

@end

@interface ReactionTableViewCell : UITableViewCell <UIAppearance>
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *likes;
@property (weak, nonatomic) IBOutlet UILabel *rating;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *reaction;

- (void)loadimage:(NSString *)imageurl;
@end

NS_ASSUME_NONNULL_END
