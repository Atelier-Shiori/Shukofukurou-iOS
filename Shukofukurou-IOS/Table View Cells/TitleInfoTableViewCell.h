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

@interface TitleInfoStreamSiteTableViewCell : UITableViewCell
@property (strong) NSURL *siteURL;
- (void)selectAction;
@end

@interface TitleInfoSynopsisTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *valueText;
- (void)fixTextColor;

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
@property (nonatomic, copy) void (^dateChanged)(NSDate *date, NSString *fieldname);
@property int entrytype;
@property int rawValue;
@property (strong) NSDate *dateValue;
- (void)selectAction;
- (void)setEnabled:(bool)enabled;
@end

@interface TitleInfoNotesEntryTableViewCell : UITableViewCell <UITextViewDelegate>
@property (nonatomic, copy) void (^notesChanged)(NSString* newvalue, NSString *fieldname);
@property (weak, nonatomic) IBOutlet UITextView *notes;
- (void)selectAction;
@end

@interface TitleInfoSwitchEntryTableViewCell : UITableViewCell
@property (nonatomic, copy) void (^switchChanged)(bool switchstate, NSString *fieldname, bool dateToggle);
@property (weak, nonatomic) IBOutlet UISwitch *toggleswitch;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;
@property bool dateToggle;
- (void)selectAction;
- (void)setEnabled:(bool)enabled;
@end

@interface TitleInfoUpdateTableViewCell : UITableViewCell
@property int actiontype;
@property (nonatomic, copy) void (^cellPressed)(int actiontype, TitleInfoUpdateTableViewCell *cell);
- (void)selectAction;
- (void)setUpdateActionCell:(bool)isActionCell;
- (void)setEnabled:(bool)enabled;
@end

NS_ASSUME_NONNULL_END
