//
//  SeasonCollectionViewCell.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SeasonCollectionViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation SeasonCollectionViewCell
- (void)loadimage:(NSString *)imageurl {
    if (imageurl.length > 0) {
        [_posterimage sd_setImageWithURL:[NSURL URLWithString:imageurl]];
        _posterimage.accessibilityLabel = [NSString stringWithFormat:@"Poster image for %@", _title.text];
    }
    else {
        _posterimage.image = [UIImage new];
        _posterimage.accessibilityLabel = @"No poster image available";
    }
}
@end
