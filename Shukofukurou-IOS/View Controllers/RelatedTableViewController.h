//
//  RelatedTableViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/1/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface RelatedTableViewController : UITableViewController <SFSafariViewControllerDelegate>
- (void)generateRelated:(NSDictionary *)titleinfo withType:(int)type;
@end

NS_ASSUME_NONNULL_END
