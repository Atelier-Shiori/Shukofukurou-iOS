//
//  ReviewDetailViewController.h
//  Shukofukurou-IOS
//
//  Created by 小鳥遊六花 on 10/16/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReviewDetailViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *avatar;
@property (strong, nonatomic) IBOutlet UILabel *score;
@property (strong, nonatomic) IBOutlet UILabel *helpful;
@property (strong, nonatomic) IBOutlet UILabel *reviewdate;
@property (strong, nonatomic) IBOutlet UILabel *progress;
@property (strong, nonatomic) IBOutlet UITextView *reviewtext;
@property int type;
- (void)populateReviewData:(NSDictionary *)review withType:(int)type;
@end

NS_ASSUME_NONNULL_END
