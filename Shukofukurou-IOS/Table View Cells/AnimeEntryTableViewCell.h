//
//  AnimeEntryTableViewCell.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/11/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnimeEntryTableViewCell : UITableViewCell
@property (strong) UIContextualAction *incrementswipebutton;
@property (strong) UIContextualAction *adveditswipebutton;
@property (strong) UIContextualAction *viewonsiteswipebutton;
@property (strong) UIContextualAction *customlistbutton;
@property (strong) UIContextualAction *shareswipebutton;
@property (strong) UIContextualAction *optionswipebutton;
@property (strong) UIContextualAction *deleteswipeaction;
@property (weak, nonatomic) IBOutlet UILabel *airingCountdown;
@property bool enablecountdown;
@property (strong) NSDate *airingDate;
@property int nextEpisode;
@property int titleid;

// UIActions
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
@property (strong) UIAction *actionIncrement;
@property (strong) UIAction *actionadvEdit;
@property (strong) UIAction *actionviewonsite;
@property (strong) UIAction *actioncustomlist;
@property (strong) UIAction *actionshare;
@property (strong) UIAction *actiondelete;
@property (strong) NSArray *contextActions;
#else
#endif

@property (strong) NSArray *regularswipebuttons;
@property (strong) NSArray *compactswipebuttons;
@property (weak, nonatomic) IBOutlet UIImageView *posterimage;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *score;
@property (weak, nonatomic) IBOutlet UILabel *progress;
@property (weak, nonatomic) IBOutlet UIImageView *active;
- (void)loadimage:(NSString *)imageurl;
- (void)loadAiringData;
- (void)setSwipeButtons;
- (void)updateCountdown;
@end

NS_ASSUME_NONNULL_END
