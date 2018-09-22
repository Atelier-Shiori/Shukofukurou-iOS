//
//  MainSideBarViewDelegate.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/30.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

@protocol  MainSideBarViewDelegate <NSObject>
@optional
- (void)accountRemovedForService:(int)service;
@end
