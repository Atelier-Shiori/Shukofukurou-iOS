//
//  HistoryCell.h
//  Shukofukurou-IOS
//
//  Created by 天々座理世 on 2019/08/01.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HistoryManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HistoryCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *datestring;
- (void)setActionText:(HistoryActionType)action withSegment:(NSNumber *)segment withMediaType:(int)mediatype;
@end

NS_ASSUME_NONNULL_END
