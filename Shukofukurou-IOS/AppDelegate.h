//
//  AppDelegate.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/21/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

