//
//  SideBarViewController.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SideBarMenuDelegate.h"
@interface SideBarViewController : UITableViewController
@property (nonatomic, weak) id <SideBarMenuDelegate> delegate;
@end
