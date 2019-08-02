//
//  HistoryCell.m
//  Shukofukurou-IOS
//
//  Created by 天々座理世 on 2019/08/01.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "HistoryCell.h"

@interface HistoryCell ()
@property (strong, nonatomic) IBOutlet UILabel *actiontext;

@end

@implementation HistoryCell
- (void)setActionText:(HistoryActionType)action withSegment:(NSNumber *)segment withMediaType:(int)mediatype{
    switch (action) {
        case HistoryActionTypeAddTitle:
            _actiontext.text = @"Added title.";
            break;
        case HistoryActionTypeUpdateTitle:
            _actiontext.text = @"Updated entry.";
            break;
        case HistoryActionTypeIncrement:
            _actiontext.text = [NSString stringWithFormat:@"Incremented %@ to %i", mediatype == 0 ? @"episode" : @"chapter", segment.intValue];
            break;
        case HistoryActionTypeDeleteTitle:
            _actiontext.text = @"Removed entry.";
            break;
        case HistoryActionTypeScrobbleTitle:
            _actiontext.text = [NSString stringWithFormat:@"Scrobbled episode %i", segment.intValue];
            break;
        case HistoryActionTypeEditCustomList:
            _actiontext.text = @"Modified custom lists.";
            break;
        default:
            break;
    }
}
@end
