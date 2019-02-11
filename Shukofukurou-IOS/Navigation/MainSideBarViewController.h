//
//  MainSideBarViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainSideBarViewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainSideBarViewController : UIViewController
@property (assign, nonatomic) IBOutlet UILabel *username;
@property  (assign, nonatomic) IBOutlet UIImageView *avatar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *logintoolbarbtn;
@property (nonatomic, strong) id <MainSideBarViewDelegate> delegate;
- (void)setLoggedinUser;
- (void)performLogin;
@end

NS_ASSUME_NONNULL_END
