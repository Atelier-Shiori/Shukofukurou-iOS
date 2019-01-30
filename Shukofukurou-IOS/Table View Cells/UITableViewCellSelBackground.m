//
//  UITableViewCellSelBackground.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 1/30/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "UITableViewCellSelBackground.h"
#import "TableViewCellBackgroundView.h"

@implementation UITableViewCellSelBackground
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectedBackgroundView = [TableViewCellBackgroundView new];
}
@end

@implementation UITableViewCellNoSelection

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:NO animated:NO];
}

@end
