//
//  ServiceSwitcherViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/09/03.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceSwitcherViewDelegate.h"
@interface ServiceSwitcherViewController : UITableViewController
@property (nonatomic, weak) id <ServiceSwitcherViewDelegate> delegate;
@end
