//
//  UITextView+SetHTMLAttributedText.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/3/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextView (SetHTMLAttributedText)
- (void)setTextToHTML:(NSString *)html withLoadingText:(nullable NSString *)loadingtext completion:(void (^)(NSAttributedString *astr)) completionHandler;
@end

NS_ASSUME_NONNULL_END
