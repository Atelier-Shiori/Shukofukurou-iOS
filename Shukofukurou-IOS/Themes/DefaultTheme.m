//
//  DefaultTheme.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 1/26/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "DefaultTheme.h"

@implementation DefaultTheme
- (instancetype)init {
    if (self = [super init]) {
        
        self.viewBackgroundColor = UIColor.whiteColor;
        self.viewAltBackgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];;
        self.tableCellSelectionBackgroundColor = [UITableViewCell new].selectedBackgroundView.backgroundColor.copy;
        self.textColor = [UITextField new].textColor.copy;
        self.tintColor = [UIView new].tintColor.copy;
        self.thumbTintColor = [UISwitch new].thumbTintColor.copy;
        self.navBarStyle = UIBarStyleDefault;
        self.keyboardappearence = UIKeyboardAppearanceLight;
    }
    return self;
}

@end
