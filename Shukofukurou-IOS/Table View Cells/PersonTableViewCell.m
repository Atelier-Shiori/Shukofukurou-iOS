//
//  PersonTableViewCell.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/2/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "PersonTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation PersonTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectedBackgroundView = [TableViewCellBackgroundView new];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)loadimage:(NSString *)imageurl {
    if (imageurl.length > 0) {
        [_image sd_setImageWithURL:[NSURL URLWithString:imageurl]];
    }
    else {
        _image.image = [UIImage new];
    }
}
@end

@implementation PersonSubtitleTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectedBackgroundView = [TableViewCellBackgroundView new];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)loadimage:(NSString *)imageurl {
    if (imageurl.length > 0) {
        [_image sd_setImageWithURL:[NSURL URLWithString:imageurl]];
    }
    else {
        _image.image = [UIImage new];
    }
}

@end
