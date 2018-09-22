//
//  SideBarMenuDelegate.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/29.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol  SideBarMenuDelegate <NSObject>
@optional
- (void)sidebarItemDidChange:(NSString *)identifier;
@end
