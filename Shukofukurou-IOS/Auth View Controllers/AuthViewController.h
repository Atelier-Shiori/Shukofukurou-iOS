//
//  AuthViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/09/04.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthViewControllerDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface AuthViewController : UIViewController
@property (nonatomic, weak) id <AuthViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
