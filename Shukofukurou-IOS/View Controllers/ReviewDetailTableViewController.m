//
//  ReviewDetailTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/1/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ReviewDetailTableViewController.h"
#import "listservice.h"
#import "AniListScoreConvert.h"
#import "Utility.h"
#import "ReviewTableViewCell.h"
#import "TitleInfoTableViewCell.h"
#import "UITextView+SetHTMLAttributedText.h"

@interface ReviewDetailTableViewController ()
@property (strong) NSArray *reviewData;
@property int type;
@end

@implementation ReviewDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (void)populateReviewData:(NSDictionary *)review withType:(int)type {
    NSMutableArray *reviewData = [NSMutableArray new];
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
    [reviewData addObject:@{@"type" : @"info", @"score" : score, @"reviewdate" : [Utility stringDatetoLocalizedDateString:(NSString *)review[@"date"]], @"progress": type == 0 ? review[@"watched_episodes"] : review[@"chapters_read"], @"helpful" : review[@"helpful"] ? review[@"helpful"] : @(0), @"avatar" : review[@"avatar_url"]}];
    [reviewData addObject:@{@"type" : @"review", @"content" : review[@"review"]}];
    _reviewData = reviewData.copy;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _reviewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *reviewentry = _reviewData[indexPath.row];
    if ([(NSString *)reviewentry[@"type"] isEqualToString:@"info"]) {
        ReviewInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reviewdetail" forIndexPath:indexPath];
        cell.score.text = reviewentry[@"score"];
        cell.reviewdate.text = [NSString stringWithFormat:@"Reviewed on %@", reviewentry[@"reviewdate"]];
        cell.progress.text = [NSString stringWithFormat:@"%@%@", _type == 0 ? @"Episodes watched:" : @"Chapters read:", reviewentry[@"progress"]];
        cell.helpful.text = ((NSNumber *)reviewentry[@"helpful"]).stringValue;
        [cell loadimage:reviewentry[@"avatar"]];
        return cell;
    }
    else {
        TitleInfoSynopsisTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reviewcell" forIndexPath:indexPath];
        self.navigationItem.hidesBackButton = YES;
        [cell.valueText setTextToHTML:(NSString *)reviewentry[@"content"] withLoadingText:@"Loading Review" completion:^(NSAttributedString * _Nonnull astr) {
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
            self.navigationItem.hidesBackButton = NO;
        }];
        return cell;
    }
    return [UITableViewCell new];
}

@end
