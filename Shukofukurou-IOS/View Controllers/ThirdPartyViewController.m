//
//  ThirdPartyViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/22/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ThirdPartyViewController.h"

@interface ThirdPartyViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textview;

@end

@implementation ThirdPartyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Load Credits
    @try {
        [_textview setAttributedText: [[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"ThirdParty" withExtension:@"rtf"] options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:nil]];
    }
    @catch (NSException *exception) {
        NSLog(@"exception: %@",exception);
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
