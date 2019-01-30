//
//  SideBarCell.m
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SideBarCell.h"
#import "TableViewCellBackgroundView.h"

@implementation SideBarCell
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectedBackgroundView = [TableViewCellBackgroundView new];
}
@end
