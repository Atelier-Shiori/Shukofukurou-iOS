//
//  UIViewThemed.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 2/9/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "UIViewThemed.h"
@implementation UIViewThemed

@end

@implementation UIViewVisualThemed

@end

@implementation UIViewGroupHeader
- (instancetype)initIsSidebar:(bool)sidebar isFirstSection:(bool)firstSection {
    if (self = [super init]) {
        _label = [[UILabel alloc] init];
        _label.frame = CGRectMake(sidebar ? 20 : 16, sidebar ? -6 : firstSection ? 32: 16, 320, 20);
        _label.font = [UIFont systemFontOfSize:12];
        [self addSubview:_label];
    }
    return self;
}
@end
