//
//  AiringTableViewCell.h
//  Shukofukurou-IOS
//
//  Created by 千代田桃 on 5/10/21.
//  Copyright © 2021 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AiringTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *progress;
@property (weak, nonatomic) IBOutlet UILabel *type;
@property (weak, nonatomic) IBOutlet UIImageView *posterimage;
@property (weak, nonatomic) IBOutlet UILabel *airingCountdown;
@property bool enablecountdown;
@property (weak, nonatomic) IBOutlet UIImageView *active;
@property (strong) NSDate *airingDate;
@property int nextEpisode;
- (void)updateCountdown;
- (void)loadimage:(NSString *)imageurl;
@end

NS_ASSUME_NONNULL_END
