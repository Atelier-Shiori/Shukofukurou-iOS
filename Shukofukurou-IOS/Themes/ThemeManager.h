//
//  ThemeManager.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 1/26/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ThemeManagerTheme.h"

NS_ASSUME_NONNULL_BEGIN

@interface ThemeManager : NSObject
typedef NS_ENUM(unsigned int, ThemeManagerThemes) {
    lightTheme = 0,
    darkTheme = 1
};
@property ThemeManagerTheme *currentTheme;
+ (ThemeManagerTheme *)sharedCurrentTheme;
- (void)setTheme;
@end

@interface HighLightView : UIImageView

@end

NS_ASSUME_NONNULL_END
