//
//  TitleInfoTableViewCell.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/18/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "TitleInfoTableViewCell.h"
#import <CoreActionSheetPicker/CoreActionSheetPicker.h>
#import "listservice.h"
#import "AniListScoreConvert.h"
#import "RatingTwentyConvert.h"

@implementation TitleInfoBasicTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:false animated:animated];
}
@end

@implementation TitleInfoBasicExpandTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:false animated:animated];
}
@end

@implementation TitleInfoSynopsisTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:false animated:animated];
}
@end

@implementation TitleInfoAdvScoreEntryTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state

}

- (void)selectAction {
    [_scorefield becomeFirstResponder];
    self.selected = NO;
}

- (IBAction)scoreeditdidend:(id)sender {
    NSString *anilistscoretype = [NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"];
    if ([anilistscoretype isEqualToString:@"POINT_100"]) {
        if (_scorefield.text.intValue <= 100 && _scorefield.text.intValue >= 0) {
            _rawscore = _scorefield.text.intValue;
            self.scoreChanged(_rawscore, @"Score");
        }
        else {
            _scorefield.text = @(_rawscore).stringValue;
        }
    }
    else if ([anilistscoretype isEqualToString:@"POINT_10_DECIMAL"]) {
        if (_scorefield.text.intValue <= 10 && _scorefield.text.intValue >= 0) {
            _rawscore = _scorefield.text.intValue * 10;
            self.scoreChanged(_rawscore, @"Score");
        }
        else {
            _scorefield.text = @(_rawscore/10).stringValue;
        }
    }
}

@end

@implementation TitleInfoProgressTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)selectAction {
    [_episodefield becomeFirstResponder];
    self.selected = NO;
}

- (IBAction)progressdidchange:(id)sender {
    if (_episodefield.text.intValue <= _stepper.maximumValue && _stepper.maximumValue && _episodefield.text.intValue >= 0) {
        _stepper.value = _episodefield.text.intValue;
        _currentprogress = _episodefield.text.intValue;
        _valueChanged(@(_currentprogress), _fieldtitlelabel.text);
    }
    else {
        _episodefield.text = @(_currentprogress).stringValue;
    }
}

- (IBAction)stepperincrement:(id)sender {
    if ((int)_stepper.value <= _stepper.maximumValue && _stepper.maximumValue && (int)_stepper.value >= 0) {
        _episodefield.text = @(@(_stepper.value).intValue).stringValue;
        _currentprogress = _episodefield.text.intValue;
        _valueChanged(@(_currentprogress), _fieldtitlelabel.text);
    }
    else {
        _stepper.value = _currentprogress;
    }
}

@end


@implementation TitleInfoListEntryTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state

}

- (void)selectAction {
    if ([self.textLabel.text isEqualToString:@"Status"]) {
        [self showStatusPicker];
    }
    else if ([self.textLabel.text isEqualToString:@"Score"]) {
        [self showScorePicker];
    }
}

- (void)showStatusPicker {
    NSArray *status;
    switch (_entrytype) {
        case 0:
            status = @[@"watching", @"completed", @"on-hold", @"dropped", @"plan to watch"];
            break;
        case 1:
            status = @[@"reading", @"completed", @"on-hold", @"dropped", @"plan to read"];
            break;
    }
    int selectedstatus = 0;
    for (NSString *strstatus in status) {
        if ([strstatus isEqualToString:self.detailTextLabel.text]) {
            break;
        }
        selectedstatus++;
    }
    [ActionSheetStringPicker showPickerWithTitle:@"Select a Status" rows:status initialSelection:selectedstatus doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        self.valueChanged(status[selectedIndex], self.textLabel.text);
        self.detailTextLabel.text = status[selectedIndex];
    } cancelBlock:^(ActionSheetStringPicker *picker) {
    } origin:self];
}

- (void)showScorePicker {
    NSArray *score = [self getScoreMenuArray];
    NSArray *rawscorearray = [self getRawScoreArray];
    __block int actualscore = _rawValue;
    int selection = 0;
    int currentservice = [listservice getCurrentServiceID];
    if (currentservice == 3) {
        actualscore = [AniListScoreConvert convertScoreToRawActualScore:actualscore withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]].intValue;
    }
    selection = [self getRawScoreIndex:actualscore withArray:rawscorearray];
    [ActionSheetStringPicker showPickerWithTitle:@"Pick a Score" rows:score initialSelection:selection doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        actualscore = ((NSNumber *)rawscorearray[selectedIndex]).intValue;
        NSString *displayscore = @(actualscore).stringValue;
        if (currentservice == 3) {
            actualscore = [AniListScoreConvert convertScoretoScoreRaw:actualscore withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]];
            displayscore = [AniListScoreConvert convertAniListScoreToActualScore:actualscore withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]];
        }
        else if (currentservice == 2) {
            displayscore = [RatingTwentyConvert convertRatingTwentyToActualScore:actualscore scoretype:(int)[NSUserDefaults.standardUserDefaults integerForKey:@"kitsu-ratingsystem"]];
        }
        self.detailTextLabel.text = displayscore;
        self.rawValue = actualscore;
        self.scoreChanged(actualscore, self.textLabel.text);
    } cancelBlock:^(ActionSheetStringPicker *picker) {
    } origin:self];

}

- (NSArray *)getScoreMenuArray {
    NSString *anilistscoretype = [NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"];
    int kitsuscoretype = (int)[NSUserDefaults.standardUserDefaults integerForKey:@"kitsu-ratingsystem"];
    int currentservice = [listservice getCurrentServiceID];
    if (([anilistscoretype isEqualToString:@"POINT_10"] && currentservice == 3) || currentservice == 1) {
        return @[@"0 - No Score", @"10 - Masterpiece", @"9 - Great", @"8 - Very Good", @"7 - Good", @"6 - Fine", @"5 - Average", @"4 - Bad", @"3 - Very Bad", @"2 - Horrible", @"1 - Unwatchable"];

    }
    else if ([anilistscoretype isEqualToString:@"POINT_5"] && currentservice == 3) {
        return @[@"No Rating", @"⭐️", @"⭐️⭐️", @"⭐️⭐️⭐️", @"⭐️⭐️⭐️⭐️", @"⭐️⭐️⭐️⭐️⭐️"];
    }
    else if ([anilistscoretype isEqualToString:@"POINT_3"] && currentservice == 3) {
        return @[@"No Rating", @"🙁", @"😐", @"🙂"];
    }
    else if (kitsuscoretype == 0 && currentservice == 2) {
        return @[@"No Rating", @"🙁 Awful", @"😐 Meh", @"🙂 Good", @"😍 Great"];
    }
    else if (kitsuscoretype == 1 && currentservice == 2) {
        return @[@"No Rating", @"0.5", @"1.0", @"1.5", @"2.0", @"2.5", @"3.0", @"3.5", @"4.0", @"4.5", @"5.0"];
    }
    else if (kitsuscoretype == 2 && currentservice == 2) {
        return @[@"No Rating", @"1.0", @"1.5", @"2.0", @"2.5", @"3.0", @"3.5", @"4.0", @"4.5", @"5.0", @"5.5", @"6.0", @"6.5", @"7.0", @"7.5", @"8.0", @"8.5", @"9.0", @"9.5", @"10"];
    }
    return @[];
}

- (NSArray *)getRawScoreArray {
    NSString *anilistscoretype = [NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"];
    int kitsuscoretype = (int)[NSUserDefaults.standardUserDefaults integerForKey:@"kitsu-ratingsystem"];
    int currentservice = [listservice getCurrentServiceID];
    if (([anilistscoretype isEqualToString:@"POINT_10"] && currentservice == 3) || currentservice == 1) {
        return @[@(0), @(10), @(9), @(8), @(7), @(6), @(5), @(4), @(3), @(2), @(1)];
    }
    else if ([anilistscoretype isEqualToString:@"POINT_5"] && currentservice == 3) {
        return @[@(0),@(1),@(2), @(3), @(4), @(5)];
    }
    else if ([anilistscoretype isEqualToString:@"POINT_3"] && currentservice == 3) {
        return @[@(0),@(2),@(8),@(14),@(20)];
    }
    else if (kitsuscoretype == 0 && currentservice == 2) {
        return @[@(0), @(2), @(8), @(14), @(20)];
    }
    else if (kitsuscoretype == 1 && currentservice == 2) {
        return @[@(0), @(2), @(4), @(6), @(8), @(10), @(12), @(14), @(16), @(18), @(20)];
    }
    else if (kitsuscoretype == 2 && currentservice == 2) {
        return @[@(0), @(2), @(3), @(4), @(5), @(6), @(7), @(8), @(9), @(10), @(11), @(12), @(13), @(14), @(15), @(16), @(17), @(18), @(19), @(20)];
    }
    return @[];
}

- (int)getRawScoreIndex:(int)score withArray:(NSArray *)rawScores{
    int index = 0;
    for (NSNumber *rawScore in rawScores)  {
        if (rawScore.intValue == score) {
            return index;
        }
        index++;
    }
    return -1;
}

@end


@implementation TitleInfoUpdateTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
        
    // Configure the view for the selected state
}

- (void)selectAction {
    self.cellPressed(_actiontype, self);
    self.selected = NO;
}

- (void)setEnabled:(bool)enabled {
    self.userInteractionEnabled = enabled;
    self.textLabel.enabled = enabled;
}

@end
