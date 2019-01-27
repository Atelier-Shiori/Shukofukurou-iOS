//
//  AppDelegate.h
//  Hiyoko
//
//  Created by 天々座理世 on 2018/08/14.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ViewControllerManager.h"
#import "OAuthViewControllerDelegate.h"
#import "ServiceSwitcherViewDelegate.h"
#import "MainSideBarViewDelegate.h"
#import "AiringNotificationManager.h"

@class ThemeManager;

@interface AppDelegate : UIResponder <UIApplicationDelegate, AuthViewControllerDelegate, ServiceSwitcherViewDelegate, MainSideBarViewDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

@property (readonly, strong) ViewControllerManager *vcmanager;

@property (strong) AiringNotificationManager *airingnotificationmanager;

@property (strong) ThemeManager *tmanager;

- (void)loadtheme;
- (NSManagedObjectContext *)managedObjectContext;
- (void)saveContext;
- (ViewControllerManager *)getvcmanager;

@end

