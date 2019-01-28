//
//  MangaEntryTableViewCell.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/12/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "MangaEntryTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation MangaEntryTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self setSwipeButtons];
}

- (void)setSwipeButtons {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        bool isregular = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
        if (isregular) {
            self.rightButtons = _regularswipebuttons;
        }
        else {
            self.rightButtons = _compactswipebuttons;
        }
    }
    else {
        self.rightButtons = _compactswipebuttons;
    }
    [self refreshButtons:NO];
}

@end
