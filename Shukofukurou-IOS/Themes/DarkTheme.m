//
//  DarkTheme.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 1/26/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "DarkTheme.h"

@implementation DarkTheme
- (instancetype)init {
    if (self = [super init]) {
        self.viewBackgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.23 alpha:1.0];;
        self.viewAltBackgroundColor = [UIColor colorWithRed:0.27 green:0.27 blue:0.24 alpha:1.0];
        self.tableCellSelectionBackgroundColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0];;
        self.textColor = [UIColor whiteColor];
        self.tintColor = [UIColor colorWithRed:0.27 green:0.44 blue:0.99 alpha:1.0];
        self.thumbTintColor = [UISwitch new].thumbTintColor.copy;
        self.trackTintColor = [UIProgressView new].trackTintColor.copy;
        self.navBarStyle = UIBarStyleBlackTranslucent;
        self.keyboardappearence = UIKeyboardAppearanceDark;
    }
    return self;
}
@end
