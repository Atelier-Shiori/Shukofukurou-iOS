//
//  ShareViewController.m
//  ShukofukurouScrobble
//
//  Created by 香風智乃 on 3/18/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "ShareViewController.h"
#import "StreamInfoRetrieval.h"
#import "MediaStreamParse.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>
#import <MBProgressHUDFramework/MBProgressHUD.h>

@interface ShareViewController ()
@property bool validurl;
@property (strong) NSDictionary *streamdata;
@property (strong) MBProgressHUD *hud;
@end

@implementation ShareViewController

NSString *const sharesupportedSites = @"(crunchyroll)";

- (void)viewDidLoad {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.moe.malupdaterosx.Shukofukurou-IOS.scrobbleextension"];
    if ([defaults valueForKey:@"streamdata"]) {
        [self promptExistingStreamData];
    }
    else if ([defaults boolForKey:@"currentserviceloggedin"]) {
        [self getURLAndPopulateData];
    }
    else {
        [self showNotLoggedInError];
    }
}

- (void)promptExistingStreamData {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Pending Scrobble" message:@"There is an scrobble that is pending. If you continue, it will be overwritten. Is this okay?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[self extensionContext] completeRequestReturningItems:nil completionHandler:nil];
    }];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self getURLAndPopulateData];
    }];
    [alertcontroller addAction:noaction];
    [alertcontroller addAction:yesaction];
    [self presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)getURLAndPopulateData {
    __block NSString *texturl;
    __block NSString *regularurl;
    __block bool validitem;
    [self showloadingview:YES withText:@"Loading Stream Info"];
    for (NSItemProvider* itemProvider in ((NSExtensionItem*)self.extensionContext.inputItems[0]).attachments ) {
        NSLog(@"itemprovider = %@", itemProvider);
        [itemProvider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
            validitem = true;
            if ([(NSObject *)item isKindOfClass:[NSURL class]]) {
                regularurl = ((NSURL *)item).absoluteString;
                regularurl = [regularurl stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                [self retrieveAndPopulateData:regularurl];
            }
        }];
        [itemProvider loadItemForTypeIdentifier:@"public.plain-text" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
            validitem = true;
            if ([(NSObject *)item isKindOfClass:[NSString class]]) {
                OnigRegexp *regex = [OnigRegexp compile:@"(https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9]+\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]+\\.[^\\s]{2,})" options:OnigOptionIgnorecase];
                NSArray *results = [regex search:(NSString *)item].strings;
                if (results.count > 0) {
                    texturl = results[0];
                    texturl = [texturl stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                    [self retrieveAndPopulateData:texturl];
                }
            }
        }];
    }
}

- (void)retrieveAndPopulateData:(NSString *)url {
    NSDictionary *tmpstreamdata = [StreamInfoRetrieval retrieveStreamInfo:url];
    if (tmpstreamdata) {
        NSArray *tmparray =  [MediaStreamParse parse:@[tmpstreamdata]];
        if (tmparray.count > 0) {
            _streamdata = tmparray[0];
            [self showloadingview:NO withText:@""];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else {
            [self showError];
            [self showloadingview:NO withText:@""];
        }
    }
    else {
        [self showloadingview:NO withText:@""];
        [self showError];
    }
}

- (void)showError {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Stream Data Retrieval Failed" message:@"You can only send a valid stream URL to scrobble. See user manual for details." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[self extensionContext] completeRequestReturningItems:nil completionHandler:nil];
    }];
    [alertcontroller addAction:okaction];
    [self presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)showNotLoggedInError {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Not logged in." message:@"You cannot scrobble a title unless you are logged in. Launch Shukofukurou, log into an account and try again." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[self extensionContext] completeRequestReturningItems:nil completionHandler:nil];
    }];
    [alertcontroller addAction:okaction];
    [self presentViewController:alertcontroller animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _streamdata.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detail"];
    cell.textLabel.text = ((NSString *)_streamdata.allKeys[indexPath.row]).capitalizedString;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", _streamdata[_streamdata.allKeys[indexPath.row]]];
    return cell;
}
- (IBAction)scrobble:(id)sender {
    // Save Scrobble Data
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.moe.malupdaterosx.Shukofukurou-IOS.scrobbleextension"];
    [defaults setObject:_streamdata forKey:@"streamdata"];
    [defaults synchronize];
    [[self extensionContext] completeRequestReturningItems:nil completionHandler:nil];
    
}
- (IBAction)cancel:(id)sender {
    [[self extensionContext] completeRequestReturningItems:nil completionHandler:nil];
}

- (void)showloadingview:(bool)show withText:(NSString *)text{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cancelButton.enabled = !show;
        self.scrobbleButton.enabled = !show;
        if (show) {
            self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.label.text = text;
        }
        else {
            [self.hud hideAnimated:YES];
        }
    });
}
@end
