//
//  AdvSearchSelectionCell.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 5/20/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "AdvSearchSelectionCell.h"
#import <CoreActionSheetPicker/CoreActionSheetPicker.h>
#import "TableViewCellBackgroundView.h"

@implementation AdvSearchSelectionCell

- (instancetype)init {
    if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil]) {
    }
    return self;
}

- (instancetype)generateCell:(NSArray *)items withParentDictionary:(NSMutableDictionary *)pdict withCellTitle:(NSString *)celltitle withValueKey:(NSString *)valuekey {
    if ([self init]) {
        _itemselections = items;
        _parrentvalues = pdict;
        self.textLabel.text = celltitle;
        _valueKey = valuekey;
        self.detailTextLabel.text = _parrentvalues[_valueKey];
    }
    return self;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectedBackgroundView = [TableViewCellBackgroundView new];
}

- (void)showPicker {
    int selecteditem = 0;
    for (NSString *item in _itemselections) {
        if ([item isEqualToString:_parrentvalues[_valueKey]]) {
            break;
        }
        selecteditem++;
    }
    [ActionSheetStringPicker showPickerWithTitle:self.textLabel.text rows:_itemselections initialSelection:selecteditem doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        self.parrentvalues[self.valueKey] = selectedValue;
        self.detailTextLabel.text = self.parrentvalues[self.valueKey];
        [self setSelected:NO animated:YES];
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        [self setSelected:NO animated:YES];
    } origin:self];
}
@end
