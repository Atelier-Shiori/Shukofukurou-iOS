//
//  ReviewTableViewCell.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/1/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ReviewTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UILabel+Copyable.h"
#import "TableViewCellBackgroundView.h"
#import "UIImageView+Letters.h"

@implementation ReviewTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    if (@available(iOS 13, *)) { }
    else {
        self.selectedBackgroundView = [TableViewCellBackgroundView new];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

@implementation ReactionTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _reaction.copyingEnabled = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:NO animated:NO];
    
    // Configure the view for the selected state
}

- (void)loadimage:(NSString *)imageurl {
    if (imageurl.length > 0) {
        [_avatar sd_setImageWithURL:[NSURL URLWithString:imageurl]];
    }
    else {
        [_avatar setImageWithString:_username.text];
    }
    _avatar.layer.cornerRadius = _avatar.frame.size.width /2;
    _avatar.layer.masksToBounds = YES;
    _avatar.layer.borderWidth = 3.0f;
    _avatar.layer.borderColor = [UIColor whiteColor].CGColor;
}

@end
