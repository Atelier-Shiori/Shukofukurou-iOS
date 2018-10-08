//
//  EntryCellInfo.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/20/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "EntryCellInfo.h"

@implementation EntryCellInfo
- (instancetype)initCellWithTitle:(NSString *)title withValue:(id)value withCellType:(cellType)celltype {
    if (self = [super init]) {
        _cellTitle = title;
        _cellValue = value;
        _type = celltype;
    }
    return self;
}

- (instancetype)initDateCellWithTitle:(NSString *)title withValue:(id)value withCellType:(cellType)celltype withDateExists:(bool)dateexist {
    if (self = [super init]) {
        _cellTitle = title;
        _cellValue = value;
        _type = celltype;
        _dateExists = dateexist;
    }
    return self;
}

- (instancetype)initCellWithTitle:(NSString *)title withValue:(id)value withMaximumCellValue:(int)cellvalueMax withCellType:(cellType)celltype {
    if (self = [super init]) {
        _cellTitle = title;
        _cellValue = value;
        _cellValueMax = cellvalueMax;
        _type = celltype;
    }
    return self;
}

- (instancetype)initActionCellWithTitle:(NSString *)title withCellAction:(cellAction)action {
    if (self = [super init]) {
        _cellTitle = title;
        _type = cellTypeAction;
        _action = action;
    }
    return self;
}

- (Class)getValueClassName {
    return [_cellValue class];
}
@end
