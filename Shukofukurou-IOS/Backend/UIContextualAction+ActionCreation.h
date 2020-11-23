//
//  UIContextualAction+ActionCreation.h
//  Shukofukurou-IOS
//
//  Created by 千代田桃 on 11/23/20.
//  Copyright © 2020 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIContextualAction (ActionCreation)
+ (instancetype)contextualActionWithStyle:(UIContextualActionStyle)style
                                          title:(nullable NSString *)title
                                          image:(nullable UIImage *)image
                                backgroundColor:(nullable UIColor *)color
                                        handler:(UIContextualActionHandler)handler;
@end

NS_ASSUME_NONNULL_END
