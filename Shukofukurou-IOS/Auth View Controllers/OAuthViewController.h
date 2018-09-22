//
//  OAuthViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/15.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthViewControllerDelegate.h"
@interface OAuthViewController : UIViewController
@property (strong, nonatomic) IBOutlet UINavigationItem *nativationitem;
@property (strong, nonatomic) IBOutlet UIView *oauthviewcontainer;
@property (nonatomic, weak) id <AuthViewControllerDelegate> delegate;
@end
