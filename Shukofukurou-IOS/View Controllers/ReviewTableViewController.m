//
//  ReviewTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/1/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ReviewTableViewController.h"
#import "ReviewTableViewCell.h"
#import "RatingTwentyConvert.h"
#import "AniListScoreConvert.h"
#import "listservice.h"
#import "ReviewDetailTableViewController.h"

@interface ReviewTableViewController ()
@property int type;
@property int titleid;
@property (strong) NSMutableArray *reviews;
@property int nextPageOffset;
@property bool loadingReactions;
@end

@implementation ReviewTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    switch ([listservice getCurrentServiceID]) {
        case 2:
            self.navigationItem.title = @"Reactions";
            break;
        default:
            break;
    }
    _reviews = [NSMutableArray new];
}

- (void)retrieveReviewsForTitleID:(int)titleid withType:(int)type {
    if (_titleid == 0) {
        _titleid = titleid;
        _type = type;
    }
    self.navigationItem.hidesBackButton = YES;
    if ([listservice getCurrentServiceID] == 2) {
        self.loadingReactions = YES;
        [Kitsu retrieveLimitedReviewsForTitle:titleid withType:type withPageOffset:_nextPageOffset completion:^(id responseObject) {
            [self.reviews addObjectsFromArray:responseObject[@"data"]];
            NSDictionary *pageInfo = responseObject[@"pageInfo"];
            if (((NSNumber *)pageInfo[@"nextPage"]).boolValue) {
                self.nextPageOffset = ((NSNumber *)pageInfo[@"nextOffset"]).intValue;
            }
            else {
                self.nextPageOffset = -1;
            }
            [self.tableView reloadData];
            self.navigationItem.hidesBackButton = NO;
            self.loadingReactions = NO;
        } error:^(NSError *error) {
            NSLog(@"%@",error);
            if (self.reviews.count > 0) {
                self.navigationItem.hidesBackButton = NO;
                self.loadingReactions = NO;
            }
            else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }
    else {
        [listservice retrieveReviewsForTitle:titleid withType:type completion:^(id responseObject) {
            switch ([listservice getCurrentServiceID]) {
                case 1:
                case 3: {
                    [self.reviews addObjectsFromArray:responseObject];
                    break;
                }
                default: {
                    break;
                }
            }
            [self.tableView reloadData];
            self.navigationItem.hidesBackButton = NO;
        } error:^(NSError *error) {
            NSLog(@"%@",error);
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _reviews.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"normalcell" forIndexPath:indexPath];
    switch ([listservice getCurrentServiceID]) {
        case 2:
            return [self generateReactionCellWithtableView:tableView cellForRowAtIndexPath:indexPath];
        case 1:
        case 3: {
            NSDictionary *review = _reviews[indexPath.row];
            cell.textLabel.text = review[@"username"];
            switch ([listservice getCurrentServiceID]) {
                case 1:
                    cell.detailTextLabel.text = ((NSNumber *)review[@"rating"]).stringValue;
                    break;
                case 3:
                    cell.detailTextLabel.text = [AniListScoreConvert convertAniListScoreToActualScore:((NSNumber *)review[@"rating"]).intValue withScoreType:[NSUserDefaults.standardUserDefaults valueForKey:@"anilist-scoreformat"]];
                    break;
                default:
                    break;
            }
            break;
        }
    }
    return cell;
}

- (UITableViewCell *)generateReactionCellWithtableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReactionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reactioncell" forIndexPath:indexPath];
    // Configure the cell...
    NSDictionary *review = _reviews[indexPath.row];
    if (!cell && tableView != self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"reactioncell" forIndexPath:indexPath];
    }
    cell.username.text = review[@"username"];
    if (review[@"helpful"]) {
        cell.likes.text = ((NSNumber *)review[@"helpful"]).stringValue;
    }
    cell.rating.text = [RatingTwentyConvert convertRatingTwentyToActualScore:((NSNumber *)review[@"rating"]).intValue scoretype:(int)[NSUserDefaults.standardUserDefaults integerForKey:@"kitsu-ratingsystem"]];
    cell.reaction.text = (NSString *)review[@"review"];
    [cell loadimage:review[@"avatar_url"]];
    // Load more reactions if there is more and the user reaches the last reaction loaded.
    if (!_loadingReactions && _nextPageOffset >= 0 && indexPath.row == self.reviews.count - 1) {
        [self retrieveReviewsForTitleID:_titleid withType:_type];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[ReactionTableViewCell class]]) {
        // Do nothing for Kitsu reactions
        return;
    }
    NSDictionary *reviewData = _reviews[indexPath.row];
    ReviewDetailTableViewController *reviewdetailvc = [self.storyboard instantiateViewControllerWithIdentifier:@"reviewdetail"];
    [self.navigationController pushViewController:reviewdetailvc animated:YES];
    [reviewdetailvc populateReviewData:reviewData withType:_type];
}

@end
