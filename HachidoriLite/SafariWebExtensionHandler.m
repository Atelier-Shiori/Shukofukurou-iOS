//
//  SafariWebExtensionHandler.m
//  Hachidori Lite Extension
//
//  Created by 千代田桃 on 9/21/21.
//

#import "SafariWebExtensionHandler.h"

#import <SafariServices/SafariServices.h>
#import "ezregex.h"
#import "MediaStreamParse.h"

#if __MAC_OS_X_VERSION_MIN_REQUIRED < 110000
NSString * const SFExtensionMessageKey = @"message";
#endif

@interface SafariWebExtensionHandler ()
@property (strong) NSString *pagesite;
@property (strong) NSString *pageurl;
@property (strong) NSString *pagetitle;
@property (strong) NSString *pagedom;
@property (strong) NSArray *detected;
@property (strong) NSArray *parsedresult;
@end

@implementation SafariWebExtensionHandler
NSString *const supportedSites = @"(crunchyroll|hidive|funimation|vrv)";

- (NSArray *)performparsing {
    NSArray *final = @[ @{@"title": _pagetitle, @"url": _pageurl, @"browser": @"Safari", @"site": _pagesite, @"DOM": _pagedom}];
    _detected = [MediaStreamParse parse:final];
    NSLog(@"%@",_detected);
    return _detected;
}

- (NSString *)checkURL:(NSString *)url {
    NSString * site = [[[ezregex alloc] init] findMatch:url pattern:supportedSites rangeatindex:0];
    return site;
}

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    id message = [context.inputItems.firstObject userInfo][SFExtensionMessageKey];
    NSLog(@"Received message from browser.runtime.sendNativeMessage: %@", message);

    NSExtensionItem *response = [[NSExtensionItem alloc] init];
    if ([(NSString *)message[@"type"] isEqualToString:@"detection"]) {
        self.pageurl = message[@"url"];
        self.pagetitle = message[@"title"];
        self.pagedom = message[@"DOM"];
        self.pagesite = [self checkURL:self.pageurl];
        _parsedresult = [self performparsing];
        response.userInfo = @{ SFExtensionMessageKey: @{ @"results": _parsedresult } };
    }
    else if ([(NSString *)message[@"type"] isEqualToString:@"update"]) {
        NSLog(@"Add Update Code");
        NSLog(@"Result: %@", message[@"data"]);
    }
    else {
        return;
    }
    [context completeRequestReturningItems:@[ response ] completionHandler:nil];
}

@end
