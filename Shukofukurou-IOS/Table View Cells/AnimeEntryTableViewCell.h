//
//  AnimeEntryTableViewCell.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/11/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MGSwipeTableCell/MGSwipeTableCell.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnimeEntryTableViewCell : MGSwipeTableCell
@property (strong) MGSwipeButton *incrementswipebutton;
@property (strong) MGSwipeButton *adveditswipebutton;
@property (strong) MGSwipeButton *viewonsiteswipebutton;
@property (strong) MGSwipeButton *customlistbutton;
@property (strong) MGSwipeButton *shareswipebutton;
@property (strong) MGSwipeButton *optionswipebutton;
@property (strong) NSArray *regularswipebuttons;
@property (strong) NSArray *compactswipebuttons;
@property (weak, nonatomic) IBOutlet UIImageView *posterimage;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *score;
@property (weak, nonatomic) IBOutlet UILabel *progress;
@property (weak, nonatomic) IBOutlet UIImageView *active;
- (void)loadimage:(NSString *)imageurl;
- (void)setSwipeButtons;
@end

NS_ASSUME_NONNULL_END
