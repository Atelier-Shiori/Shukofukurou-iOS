//
//  ExportListTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/26/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "ExportListTableViewController.h"
#import "AppDelegate.h"
#import "listservice.h"
#import "AtarashiiListCoreData.h"
#import <MBProgressHudFramework/MBProgressHUD.h>
#import "ThemeManager.h"
#import "ExportOperationManager.h"

@interface ExportListTableViewController ()
typedef NS_ENUM(unsigned int, ExportType) {
    MALXMLAnimeExportType = 0,
    MALXMLMangaExportType = 1,
    JsonAnimeExportType = 2,
    JsonMangaExportType = 3
};
@property (strong, nonatomic) IBOutlet UITableViewCell *malanimeformatted;
@property (strong, nonatomic) IBOutlet UITableViewCell *malmangaformatted;
@property (strong, nonatomic) IBOutlet UITableViewCell *jsonanimeformatted;
@property (strong, nonatomic) IBOutlet UITableViewCell *jsonmangaformatted;
@property (strong) NSManagedObjectContext *moc;
@property (strong) MBProgressHUD *hud;
@end

@implementation ExportListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _moc = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
    if (![listservice.sharedInstance checkAccountForCurrentService]) {
        // Show Error
        UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Not logged in" message:[NSString stringWithFormat:@"You are not logged in %@, thus you cannot export a list. Please log in and try again", [listservice.sharedInstance currentservicename]] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
        [alertcontroller addAction:okaction];
        [self presentViewController:alertcontroller animated:YES completion:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    int exporttype = 0;
    if ([cell.textLabel.text isEqualToString:@"Export MAL XML Converted (Anime)"]) {
        exporttype = MALXMLAnimeExportType;
    }
    else if ([cell.textLabel.text isEqualToString:@"Export MAL XML Converted (Manga)"]) {
        exporttype = MALXMLMangaExportType;
    }
    else if ([cell.textLabel.text isEqualToString:@"Export to JSON (Anime)"]) {
        exporttype = JsonAnimeExportType;
    }
    else if ([cell.textLabel.text isEqualToString:@"Export to JSON (Manga)"]) {
        exporttype = JsonMangaExportType;
    }
    [self promptExport:exporttype];
}

- (void)promptExport:(int)exporttype {
    NSString *exportTitle;
    switch (exporttype) {
        case MALXMLAnimeExportType:
        case MALXMLMangaExportType:
            exportTitle = @"Export as MAL XML?";
            break;
        case JsonAnimeExportType:
        case JsonMangaExportType:
            exportTitle = @"Export as Json?";
            break;
        default:
            break;
    }
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:exportTitle message:[NSString stringWithFormat:@"Do you want to export your %@ list?%@", [listservice.sharedInstance currentservicename], (exporttype == MALXMLAnimeExportType || exporttype == MALXMLMangaExportType) ? @"This may take some time." : @""] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self beginExport:exporttype];
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertcontroller addAction:noaction];
    [alertcontroller addAction:yesaction];
    [self presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)beginExport:(int)type {
    switch (type) {
        case MALXMLAnimeExportType:
        case MALXMLMangaExportType:
            [self exportXML:type];
            break;
        case JsonAnimeExportType:
        case JsonMangaExportType:
            [self exportJson:type];
            break;
        default:
            break;
    }
}

- (void)exportXML:(int)type {
    int listtype = type == MALXMLAnimeExportType ? 0 : 1;
    ExportOperationManager *exportopmanager = [ExportOperationManager new];
    [self showloadingview:YES];
    exportopmanager.completion = ^(NSMutableArray * _Nonnull failedtitles, NSString * _Nonnull xml) {
        [self showloadingview:NO];
        [self saveToCoreData:xml withType:type];
        [self showMessage:@"Export Successful." withInformativeText:@"You can see your exported list in the Exported Lists section."];
        if (failedtitles.count > 0) {
            NSLog(@"One or more titles failed to export");
        }
    };
    [exportopmanager beginTitleIdBuildingForType:listtype];
}

- (void)exportJson:(int)type {
    int listtype = type == JsonAnimeExportType ? 0 : 1;
    listservice *lservice = listservice.sharedInstance;
    NSDictionary *list = [AtarashiiListCoreData retrieveEntriesForUserId:[lservice getCurrentUserID] withService:[lservice getCurrentServiceID] withType:listtype];
    NSMutableDictionary *finaldictionary = [NSMutableDictionary new];
    finaldictionary[@"userData"] = @{@"service" : lservice.currentservicename, @"user_id" : @(lservice.getCurrentUserID), @"username" : lservice.getCurrentServiceUsername, @"type" : listtype == 0 ? @"anime" : @"manga"};
    finaldictionary[@"list"] = listtype == 0 ? list[@"anime"] : list[@"manga"];
    NSError *error;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:finaldictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (jsondata) {
        [self saveToCoreData:[[NSString alloc] initWithData:jsondata encoding:NSUTF8StringEncoding] withType:type];
        [self showMessage:@"Export Successful." withInformativeText:@"You can see your exported list in the Exported Lists section."];
    }
    else {
        [self showMessage:@"Export Unsuccessful." withInformativeText:@"The list failed to export."];
    }
    switch (type) {
        case MALXMLAnimeExportType:
            [_malanimeformatted setSelected:NO animated:YES];
            break;
        case MALXMLMangaExportType:
            [_malmangaformatted setSelected:NO animated:YES];
            break;
        case JsonAnimeExportType:
            [_jsonanimeformatted setSelected:NO animated:YES];
            break;
        case JsonMangaExportType:
            [_jsonmangaformatted setSelected:NO animated:YES];
            break;
        default:
            break;
    }
    
}

- (void)showMessage:(NSString *)title withInformativeText:(NSString *)informativeText {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:title message:informativeText preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertcontroller addAction:okaction];
    [self presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)saveToCoreData:(NSString *)stringData withType:(int)exporttype {
    NSString *format;
    int mediatype = (exporttype == MALXMLAnimeExportType || exporttype == JsonAnimeExportType) ? 0 : 1;
    switch (exporttype) {
        case MALXMLAnimeExportType:
        case MALXMLMangaExportType:
            format = @"xml";
            break;
        case JsonAnimeExportType:
        case JsonMangaExportType:
            format = @"json";
            break;
        default:
            break;
    }
    NSManagedObject *obj = [NSEntityDescription
                            insertNewObjectForEntityForName :@"ExportedLists"
                            inManagedObjectContext: self.moc];
    // Set values in the new record
    listservice *lservice = [listservice sharedInstance];
    [obj setValue:[NSString stringWithFormat:@"%@-%li-%@-%@", lservice.currentservicename, (long)[NSDate date].timeIntervalSinceReferenceDate, lservice.getCurrentServiceUsername, mediatype == 0 ? @"anime" : @"manga"] forKey:@"title"];
    [obj setValue:stringData forKey:@"data"];
    [obj setValue:format forKey:@"format"];
    NSError *error = nil;
    // Save
    [self.moc save:&error];
}

- (void)showloadingview:(bool)show {
    if (show) {
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = @"Exporting...";
        _hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
        _hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
    }
    else {
        [_hud hideAnimated:YES];
    }
}

@end
