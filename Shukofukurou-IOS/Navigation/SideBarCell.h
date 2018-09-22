//
//  SideBarCell.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideBarCell : UITableViewCell
@property (assign, nonatomic) IBOutlet UILabel *titleLabel;
@property (assign, nonatomic) IBOutlet UIView *separatorView;
@property  (assign, nonatomic) IBOutlet UIImageView *image;
@end
