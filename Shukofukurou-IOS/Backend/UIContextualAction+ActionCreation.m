//
//  UIContextualAction+ActionCreation.m
//  Shukofukurou-IOS
//
//  Created by 千代田桃 on 11/23/20.
//  Copyright © 2020 MAL Updater OS X Group. All rights reserved.
//

#import "UIContextualAction+ActionCreation.h"

@implementation UIContextualAction (ActionCreation)
+ (instancetype)contextualActionWithStyle:(UIContextualActionStyle)style
                                          title:(nullable NSString *)title
                                          image:(nullable UIImage *)image
                                backgroundColor:(nullable UIColor *)color
                                  handler:(UIContextualActionHandler)handler {
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:style title:title handler:handler];
    if (image) {
        action.image = image;
    }
    if (color) {
        action.backgroundColor = color;
    }
    return action;
}
@end
