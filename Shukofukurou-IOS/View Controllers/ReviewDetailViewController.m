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

@implementation ReviewDetailViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)populateReviewData:(NSDictionary *)review withType:(int)type {
    int currentservice = [listservice getCurrentServiceID];
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
    [_reviewtext setTextToHTML:(NSString *)review[@"review"] withLoadingText:@"Loading Review" completion:^(NSAttributedString * _Nonnull astr) {
        self.navigationItem.hidesBackButton = NO;
    }];
}

- (void)loadimage:(NSString *)imageurl {
    if (imageurl.length > 0) {
        [_avatar sd_setImageWithURL:[NSURL URLWithString:imageurl]];
    }
    else {
        _avatar.image = [UIImage new];
    }
}

@end
