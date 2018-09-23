//
//  AutoRefreshTimer.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/22/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AutoRefreshTimer.h"
#import "ViewControllerManager.h"
#import "MSWeakTimer.h"

@interface AutoRefreshTimer ()
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (strong, nonatomic) MSWeakTimer *refreshtimer;
@property bool timerActive;
@end

@implementation AutoRefreshTimer
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _vcm = [ViewControllerManager getAppDelegateViewControllerManager];
    _privateQueue = dispatch_queue_create("moe.ateliershiori.Shukofukurou-iOS", DISPATCH_QUEUE_CONCURRENT);
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"AutoRefreshStateChanged" object:nil];
    [self toggleTimer];
    return self;
}

- (void)recieveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"AutoRefreshStateChanged"]) {
        [self toggleTimer];
    }
}

- (void)toggleTimer {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"refreshautomatically"] && !_timerActive) {
        _refreshtimer =  [MSWeakTimer scheduledTimerWithTimeInterval:300
                                                              target:self
                                                            selector:@selector(fireTimer)
                                                            userInfo:nil
                                                             repeats:YES
                                                       dispatchQueue:_privateQueue];
        _timerActive = YES;
        NSLog(@"Timer Active");
    }
    else {
        [_refreshtimer invalidate];
        _timerActive = NO;
        NSLog(@"Timer Stopped");
    }
}

- (void)resumeTimer {
    if (_timerActive) {
        _refreshtimer =  [MSWeakTimer scheduledTimerWithTimeInterval:300
                                                              target:self
                                                            selector:@selector(fireTimer)
                                                            userInfo:nil
                                                             repeats:YES
                                                       dispatchQueue:_privateQueue];
        NSLog(@"Timer Resumed");
    }
}

- (void)pauseTimer {
    if (_timerActive) {
        [_refreshtimer invalidate];
        NSLog(@"Timer Paused");
    }
}

- (void)fireTimer {
    [NSNotificationCenter.defaultCenter postNotificationName:@"AnimeRefreshList" object:nil];
    [NSNotificationCenter.defaultCenter postNotificationName:@"MangaRefreshList" object:nil];
}
@end
