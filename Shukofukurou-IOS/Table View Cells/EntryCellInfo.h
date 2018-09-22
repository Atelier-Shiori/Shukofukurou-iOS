//
//  EntryCellInfo.h
//  Hiyoko
//
//  Created by 香風智乃 on 9/20/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EntryCellInfo : NSObject
typedef NS_ENUM(unsigned int, cellType) {
    cellTypeInfo = 0,
    cellTypeEntry = 1,
    cellTypeProgressEntry = 2,
    cellTypeAction = 3,
    cellTypeInfoExpand = 4,
    cellTypeSynopsis = 5
};
typedef NS_ENUM(unsigned int, cellAction) {
    updateEntry = 0,
    addEntry = 1
};
@property (strong) NSString *cellTitle;
@property (strong) id cellValue;
@property int cellValueMax;
@property cellType type;
@property cellAction action;
- (instancetype)initCellWithTitle:(NSString *)title withValue:(id)value withCellType:(cellType)celltype;
- (instancetype)initCellWithTitle:(NSString *)title withValue:(id)value withMaximumCellValue:(int)cellvalueMax withCellType:(cellType)celltype;
- (instancetype)initActionCellWithTitle:(NSString *)title withCellAction:(cellAction)action;
- (Class)getValueClassName;
@end

NS_ASSUME_NONNULL_END
