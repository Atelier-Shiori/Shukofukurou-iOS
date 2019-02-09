//
//  UIViewThemed.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 2/9/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "UIViewThemed.h"
#import "ThemeManager.h"

@implementation UIViewThemed

@end

@implementation UIViewVisualThemed

@end

@implementation UIViewGroupHeader
- (instancetype)initIsSidebar:(bool)sidebar isFirstSection:(bool)firstSection {
    if (self = [super init]) {
        _label = [[UILabel alloc] init];
        _label.frame = CGRectMake(sidebar ? 20 : 16, sidebar ? -6 : firstSection ? 32: 16, 320, 20);
        _label.textColor = [ThemeManager sharedCurrentTheme].groupHeaderTextColor;
        _label.font = [UIFont systemFontOfSize:12];
        [self addSubview:_label];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveNotification:) name:@"ThemeChanged" object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)didReceiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"ThemeChanged"]) {
        _label.textColor = [ThemeManager sharedCurrentTheme].groupHeaderTextColor;
    }
}
@end
