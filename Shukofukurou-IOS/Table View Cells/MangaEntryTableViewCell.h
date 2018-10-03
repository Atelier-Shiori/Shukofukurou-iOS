//
//  MangaEntryTableViewCell.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/12/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MGSwipeTableCell/MGSwipeTableCell.h>

NS_ASSUME_NONNULL_BEGIN

@interface MangaEntryTableViewCell : MGSwipeTableCell
@property (weak, nonatomic) IBOutlet UIImageView *posterimage;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *score;
@property (weak, nonatomic) IBOutlet UILabel *progress;
@property (weak, nonatomic) IBOutlet UILabel *progressVolumes;
@property (weak, nonatomic) IBOutlet UIImageView *active;
- (void)loadimage:(NSString *)imageurl;
@end

NS_ASSUME_NONNULL_END
