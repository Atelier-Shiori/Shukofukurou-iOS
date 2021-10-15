//
//  AnimeEntryTableViewCell.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/11/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AnimeEntryTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "TableViewCellBackgroundView.h"
#import "AiringSchedule.h"
#import "listservice.h"

@interface AnimeEntryTableViewCell ()
@property (strong) NSNumber *watchedepisodes;
@property (strong) NSNumber *numepisodes;
@end

@implementation AnimeEntryTableViewCell


- (instancetype)init {
    self = [super init];
    if (self) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receivedNotification:) name:@"airTimerFire" object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)receivedNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"airTimerFire"]) {
        [self updateCountdown];
    }
}

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

- (void)loadAiringData {
    if (!_active.hidden) {
        // Retrieve Air Date and Next Episode
        NSArray *schedule = [AiringSchedule retrieveAllAiringData];
        NSPredicate *predicate;
        switch ([listservice.sharedInstance getCurrentServiceID]) {
            case 1:
                //idMal
                predicate = [NSPredicate predicateWithFormat:@"idMal == %i", _titleid];
                break;
            case 2:
                //idKitsu
                predicate = [NSPredicate predicateWithFormat:@"idKitsu == %i", _titleid];
                break;
            case 3:
                //id
                predicate = [NSPredicate predicateWithFormat:@"id == %i", _titleid];
                break;
            default:
                return;
        }
        
        NSArray *filtered = [schedule filteredArrayUsingPredicate:predicate];
        if (filtered.count > 0) {
            NSDictionary *airdata = filtered[0];
            if (airdata[@"nextairdate"]) {
                _airingCountdown.hidden = false;
                _airingDate = airdata[@"nextairdate"];
                _nextEpisode = ((NSNumber *)airdata[@"nextepisode"]).intValue;
                _enablecountdown = true;
                [self updateCountdown];
                [self setEpisodeText:self.watchedepisodes withEpisodes:self.numepisodes];
                [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receivedNotification:) name:@"airTimerFire" object:nil];
            }
            else {
                _enablecountdown = false;
            }
        }
        else {
            _enablecountdown = false;
        }
    }
    else {
        _enablecountdown = false;
    }
    if (!_enablecountdown) {
        _airingCountdown.hidden = true;
        [NSNotificationCenter.defaultCenter removeObserver:self name:@"airTimerFire" object:nil];
    }
}

- (void)updateCountdown {
    if (!_enablecountdown || _active.hidden || [_airingDate isKindOfClass:[NSNull class]]) {
        _airingCountdown.hidden = true;
        _enablecountdown = false;
        _nextEpisode = 0;
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
            [fstring appendFormat:@"%lid ", days];
        }
        if (hours  > 0) {
            [fstring appendFormat:@"%lih ", hours];
        }
        if (minutes > 0) {
            [fstring appendFormat:@"%lim", minutes];
        }
    }
    else {
        [fstring appendFormat:@"Ep %i aired!", _nextEpisode];
    }
    _airingCountdown.text = fstring;
}

- (void)setEpisodeText:(id)watchedepisodes withEpisodes:(id)episodes {
    self.watchedepisodes = watchedepisodes;
    self.numepisodes = episodes;
    self.progress.text = _airingCountdown && (_nextEpisode-1)-((NSNumber *)self.watchedepisodes).intValue > 0 && _nextEpisode > 0 ? [NSString stringWithFormat:@"Episode: %@/%@ (%i %@ Behind)", self.watchedepisodes, self.numepisodes , (_nextEpisode-1)-((NSNumber *)watchedepisodes).intValue, (_nextEpisode-1)-((NSNumber *)watchedepisodes).intValue > 1 ? @"Eps" : @"Ep"] : [NSString stringWithFormat:@"Episode: %@/%@", self.watchedepisodes, self.numepisodes];
}

- (void)resetAirParameters {
    _airingCountdown.hidden = true;
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"airTimerFire" object:nil];
    _nextEpisode = 0;
    _enablecountdown = false;
    _airingDate = nil;
}
@end
