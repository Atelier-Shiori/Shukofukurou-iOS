//
//  SearchTableViewCell.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/12/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SearchTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "TableViewCellBackgroundView.h"

@implementation SearchTableViewCell

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
        [_posterimage sd_setImageWithURL:[NSURL URLWithString:imageurl]];
    }
    else {
        _posterimage.image = [UIImage new];
    }
}

@end
