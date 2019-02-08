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
        self.viewAltBackgroundColor = [UIColor colorWithRed:0.27 green:0.27 blue:0.27 alpha:1.0];
        self.tableCellSelectionBackgroundColor = [UIColor colorWithRed:0.43 green:0.43 blue:0.43 alpha:1.0];
        self.tableHeaderBackgroundColor = [UIColor colorWithRed:0.42 green:0.42 blue:0.43 alpha:1.0];
        self.textColor = [UIColor whiteColor];
        self.tintColor = [UIColor colorWithRed:0.27 green:0.44 blue:0.99 alpha:1.0];
        self.thumbTintColor = [UISwitch new].thumbTintColor.copy;
        self.trackTintColor = [UIProgressView new].trackTintColor.copy;
        self.tablecellImageTintColor = [UIColor whiteColor];
        self.navBarStyle = UIBarStyleBlackTranslucent;
        self.keyboardappearence = UIKeyboardAppearanceDark;
    }
    return self;
}
@end
