//
//  AiringTableViewCell.m
//  Shukofukurou-IOS
//
//  Created by 千代田桃 on 5/10/21.
//  Copyright © 2021 MAL Updater OS X Group. All rights reserved.
//

#import "AiringTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "TableViewCellBackgroundView.h"

@implementation AiringTableViewCell
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

- (void)loadimage:(NSString *)imageurl {
    if (imageurl.length > 0) {
        [_posterimage sd_setImageWithURL:[NSURL URLWithString:imageurl]];
    }
    else {
        _posterimage.image = [UIImage new];
    }
}

- (void)updateCountdown {
    if (!_enablecountdown) {
        return;
    }
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                        fromDate:[NSDate date]
                                                          toDate:_airingDate
                                                         options:0];
    long days;
    long hours;
    long minutes;
    days = components.day;
    hours = components.hour;
    minutes = components.minute;
    
    NSMutableString *fstring = [NSMutableString new];
    if (days > 0 || hours > 0 || minutes > 0) {
        [fstring appendFormat:@"Ep %i in ", _nextEpisode];
        if (days > 0) {
            [fstring appendFormat:days > 1 ? @"%li days " : @"%li day ", days];
        }
        if (hours  > 0) {
            [fstring appendFormat:hours > 1 ? @"%li hrs " : @"%li hr ", hours];
        }
        if (minutes > 0) {
            [fstring appendFormat:minutes > 1 ? @"%li mins" : @"%li min", minutes];
        }
    }
    else {
        [fstring appendFormat:@"Ep %i aired!", _nextEpisode];
    }
    _airingCountdown.text = fstring;
}
@end
