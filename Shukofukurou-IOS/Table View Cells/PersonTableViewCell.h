//
//  PersonTableViewCell.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/2/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewCellBackgroundView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PersonTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *titlelabel;
- (void)loadimage:(NSString *)imageurl;
@end

@interface PersonSubtitleTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *titlelabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitlelabel;
- (void)loadimage:(NSString *)imageurl;
@end

NS_ASSUME_NONNULL_END
