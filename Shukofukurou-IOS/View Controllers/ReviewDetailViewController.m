//
//  ReviewDetailViewController.m
//  Shukofukurou-IOS
//
//  Created by 小鳥遊六花 on 10/16/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ReviewDetailViewController.h"
#import "listservice.h"
#import "AniListScoreConvert.h"
#import "Utility.h"
#import "UITextView+SetHTMLAttributedText.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+Letters.h"
#import "ThemeManager.h"

@interface ReviewDetailViewController ()
@property bool setthemecolors;
@end

@implementation ReviewDetailViewController

-(void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setThemeColors];
    _setthemecolors = true;
    // Do view setup here.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ThemeChanged" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setThemeColors];
    _setthemecolors = true;
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"ThemeChanged"]) {
        _setthemecolors = false;
    }
}

- (void)setThemeColors {
    if (!_setthemecolors) {
        bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
        ThemeManagerTheme *current = [ThemeManager sharedCurrentTheme];
        UIColor *textcolor = [ThemeManager sharedCurrentTheme].textColor;;
        self.view.backgroundColor = darkmode ? current.viewAltBackgroundColor : current.viewBackgroundColor;
        self.reviewtext.textColor = textcolor;
        self.progress.textColor = textcolor;
        self.reviewdate.textColor = textcolor;
        self.helpful.textColor = textcolor;
        self.score.textColor = textcolor;
    }
}

- (void)populateReviewData:(NSDictionary *)review withType:(int)type {
    int currentservice = [listservice.sharedInstance getCurrentServiceID];
    _type = type;
    self.navigationItem.title = review[@"username"];
    NSString *score = @"0";
    if (currentservice == 1) {
        score = ((NSNumber *)review[@"rating"]).stringValue;
        
    }
    else {
        score = [AniListScoreConvert convertAniListScoreToActualScore:((NSNumber *)review[@"rating"]).intValue withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]];
    }
    _score.text = score;
    _reviewdate.text = [NSString stringWithFormat:@"Reviewed on %@", review[@"date"]];
    NSNumber *progress = type == 0 ? review[@"watched_episodes"] : review[@"chapters_read"];
    _progress.text = [NSString stringWithFormat:@"%@%@", _type == 0 ? @"Episodes watched:" : @"Chapters read:", progress];
    _helpful.text = ((NSNumber *)review[@"helpful"] ).stringValue;
    [self loadimage:review[@"avatar_url"]];
    self.navigationItem.hidesBackButton = YES;
    __weak ReviewDetailViewController *weakSelf = self;
    [_reviewtext setTextToHTML:(NSString *)review[@"review"] withLoadingText:@"Loading Review" completion:^(NSAttributedString * _Nonnull astr) {
        weakSelf.navigationItem.hidesBackButton = NO;
        weakSelf.reviewtext.textColor = [ThemeManager sharedCurrentTheme].textColor;
    }];
}

- (void)loadimage:(NSString *)imageurl {
    if (imageurl.length > 0) {
        [_avatar sd_setImageWithURL:[NSURL URLWithString:imageurl]];
    }
    else {
        [_avatar setImageWithString:self.navigationItem.title];
    }
    _avatar.layer.cornerRadius = _avatar.frame.size.width /2;
    _avatar.layer.masksToBounds = YES;
    _avatar.layer.borderWidth = 3.0f;
    _avatar.layer.borderColor = [UIColor whiteColor].CGColor;
}

@end
