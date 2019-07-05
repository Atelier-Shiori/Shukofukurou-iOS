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
@property bool loaded;
@end

@implementation ThirdPartyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Load Credits
    @try {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.textview.attributedText =  [[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"ThirdParty" withExtension:@"rtf"] options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:nil];
            [self.textview setContentOffset:CGPointZero animated:NO];
             });
    }
    @catch (NSException *exception) {
        NSLog(@"exception: %@",exception);
    }
    [self fixtheme];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)fixtheme {
    if (@available(iOS 13, *)) {
        self.view.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        _textview.backgroundColor = [UIColor clearColor];
        _textview.textColor = [UIColor labelColor];
    }
    else {
        bool darkmode = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"];
        self.view.backgroundColor = darkmode ? [ThemeManager sharedCurrentTheme].viewAltBackgroundColor : [ThemeManager sharedCurrentTheme].viewBackgroundColor;
        _textview.textColor = [ThemeManager sharedCurrentTheme].textColor;
    }
}

@end
