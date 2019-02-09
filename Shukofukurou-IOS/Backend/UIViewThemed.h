//
//  UIViewThemed.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 2/9/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewThemed : UIView

@end

@interface UIViewVisualThemed : UIVisualEffectView

@end

@interface UIViewGroupHeader : UIView
@property (strong) UILabel *label;
- (instancetype)initIsSidebar:(bool)sidebar isFirstSection:(bool)firstSection;
@end


NS_ASSUME_NONNULL_END
