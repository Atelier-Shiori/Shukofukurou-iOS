//
//  ThirdPartyViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 9/22/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "ThirdPartyViewController.h"
#import "ThemeManager.h"

@interface ThirdPartyViewController ()
@property (strong, nonatomic) IBOutlet UITextView *textview;

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
    [self fixtheme];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [_textview setContentOffset:CGPointZero animated:NO];
    }
}

- (void)fixtheme {
    bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
    self.view.backgroundColor = darkmode ? [ThemeManager sharedCurrentTheme].viewAltBackgroundColor : [ThemeManager sharedCurrentTheme].viewBackgroundColor;
    _textview.textColor = [ThemeManager sharedCurrentTheme].textColor;
}

@end
