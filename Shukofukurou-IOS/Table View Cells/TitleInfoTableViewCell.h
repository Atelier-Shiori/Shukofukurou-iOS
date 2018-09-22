//
//  TitleInfoTableViewCell.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/18/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TitleInfoBasicTableViewCell : UITableViewCell

@end

@interface TitleInfoBasicExpandTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@interface TitleInfoSynopsisTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *valueText;

@end

@interface TitleInfoAdvScoreEntryTableViewCell : UITableViewCell
@property (nonatomic, copy) void (^scoreChanged)(int newvalue, NSString *fieldname);
@property (weak, nonatomic) IBOutlet UITextField *scorefield;
@property int rawscore;
- (void)selectAction;
@end

@interface TitleInfoProgressTableViewCell : UITableViewCell
@property int currentprogress;
@property (nonatomic, copy) void (^valueChanged)(NSNumber *newvalue, NSString *fieldname);
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UITextField *episodefield;
@property (weak, nonatomic) IBOutlet UILabel *fieldtitlelabel;
- (void)selectAction;
@end


@interface TitleInfoListEntryTableViewCell : UITableViewCell
@property (nonatomic, copy) void (^valueChanged)(NSString *newvalue, NSString *fieldname);
@property (nonatomic, copy) void (^scoreChanged)(int newvalue, NSString *fieldname);
@property int entrytype;
@property int rawValue;
- (void)selectAction;
@end

@interface TitleInfoUpdateTableViewCell : UITableViewCell
@property int actiontype;
@property (nonatomic, copy) void (^cellPressed)(int actiontype, TitleInfoUpdateTableViewCell *cell);
- (void)selectAction;
- (void)setEnabled:(bool)enabled;
@end

NS_ASSUME_NONNULL_END
