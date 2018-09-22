//
//  AuthWebView.m
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 4/24/18.
//  Copyright © 2018 Atelier Shiori. All rights reserved.
//

#import "AuthWebView.h"
#import "ClientConstants.h"

@interface AuthWebView ()

@end

@implementation AuthWebView
- (void)loadView {
    WKWebViewConfiguration *webConfiguration = [WKWebViewConfiguration new];
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfiguration];
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    self.view = _webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self loadAuthorization];
}

- (NSURL *)authURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://anilist.co/api/v2/oauth/authorize?client_id=%@&response_type=code",kanilistclient]];
}

- (void)loadAuthorization {
    [_webView loadRequest:[NSURLRequest requestWithURL:[self authURL]]];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([navigationAction.request.URL.absoluteString containsString:@"hiyokoauth://anilistauth/?code="]) {
        // Save Pin
        decisionHandler(WKNavigationActionPolicyCancel);
        [self resetWebView];
        _completion([navigationAction.request.URL.absoluteString stringByReplacingOccurrencesOfString:@"hiyokoauth://anilistauth/?code=" withString:@""]);
    }
    else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}


- (void)resetWebView {
    // Clears WebView cookies and cache
    NSSet *websiteDataTypes;
    websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache,WKWebsiteDataTypeOfflineWebApplicationCache,WKWebsiteDataTypeMemoryCache,WKWebsiteDataTypeLocalStorage,WKWebsiteDataTypeCookies,WKWebsiteDataTypeSessionStorage,WKWebsiteDataTypeIndexedDBDatabases, WKWebsiteDataTypeWebSQLDatabases]];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
    }];

}



@end
