//
//  AdvSearchSelectionCell.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 5/20/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdvSearchSelectionCell : UITableViewCell
@property (strong) NSMutableDictionary *parrentvalues;
@property (strong) NSArray *itemselections;
@property (strong) NSString *valueKey;
- (instancetype)generateCell:(NSArray *)items withParentDictionary:(NSMutableDictionary *)pdict withCellTitle:(NSString *)celltitle withValueKey:(NSString *)valuekey;
- (void)showPicker;
@end

NS_ASSUME_NONNULL_END
