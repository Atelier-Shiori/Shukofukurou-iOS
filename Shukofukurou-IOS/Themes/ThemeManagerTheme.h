//
//  ThemeManagerTheme.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 1/26/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThemeManagerTheme : NSObject
@property (strong) UIColor *viewBackgroundColor;
@property (strong) UIColor *viewAltBackgroundColor;
@property (strong) UIColor *tableCellSelectionBackgroundColor;
@property (strong) UIColor *groupHeaderTextColor;
@property (strong) UIColor *tableHeaderBackgroundColor;
@property (strong) UIColor *textColor;
@property (strong) UIColor *tintColor;
@property (strong) UIColor *thumbTintColor;
@property (strong) UIColor *trackTintColor;
@property (strong) UIColor *tablecellImageTintColor;
@property UIKeyboardAppearance keyboardappearence;
@property UIBarStyle navBarStyle;
@end

NS_ASSUME_NONNULL_END
