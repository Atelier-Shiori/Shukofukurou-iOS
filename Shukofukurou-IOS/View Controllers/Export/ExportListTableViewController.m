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
#import "FailedTitlesTableViewController.h"
#import "RatingTwentyConvert.h"

@interface ExportListTableViewController ()
typedef NS_ENUM(unsigned int, ExportType) {
    MALXMLAnimeExportType = 0,
    MALXMLMangaExportType = 1,
    JsonAnimeExportType = 2,
    JsonMangaExportType = 3,
    CsvAnimeExportType = 4,
    CsvMangaExportType = 5
};
@property (strong, nonatomic) IBOutlet UITableViewCell *malanimeformatted;
@property (strong, nonatomic) IBOutlet UITableViewCell *malmangaformatted;
@property (strong, nonatomic) IBOutlet UITableViewCell *jsonanimeformatted;
@property (strong, nonatomic) IBOutlet UITableViewCell *jsonmangaformatted;
@property (strong, nonatomic) IBOutlet UITableViewCell *csvanimeformatted;
@property (strong, nonatomic) IBOutlet UITableViewCell *csvmangaformatted;
@property (strong) NSManagedObjectContext *moc;
@property (strong) ExportOperationManager *exportopmanager;
@property (strong) MBProgressHUD *hud;
@end

@implementation ExportListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [ThemeManager fixTableView:self.tableView];
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
    if ([cell.textLabel.text isEqualToString:@"Export MAL XML Converted (Anime)"] || [cell.textLabel.text isEqualToString:@"Export MAL XML (Anime)"]) {
        exporttype = MALXMLAnimeExportType;
    }
    else if ([cell.textLabel.text isEqualToString:@"Export MAL XML Converted (Manga)"] || [cell.textLabel.text isEqualToString:@"Export MAL XML (Manga)"]) {
        exporttype = MALXMLMangaExportType;
    }
    else if ([cell.textLabel.text isEqualToString:@"Export to JSON (Anime)"]) {
        exporttype = JsonAnimeExportType;
    }
    else if ([cell.textLabel.text isEqualToString:@"Export to JSON (Manga)"]) {
        exporttype = JsonMangaExportType;
    }
    else if ([cell.textLabel.text isEqualToString:@"Export to CSV (Anime)"]) {
        exporttype = CsvAnimeExportType;
    }
    else if ([cell.textLabel.text isEqualToString:@"Export to CSV (Manga)"]) {
        exporttype = CsvMangaExportType;
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
        case CsvAnimeExportType:
        case CsvMangaExportType:
            exportTitle = @"Export as a CSV file?";
            break;
        default:
            break;
    }
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:exportTitle message:[NSString stringWithFormat:@"Do you want to export your %@ list?%@", [listservice.sharedInstance currentservicename], (exporttype == MALXMLAnimeExportType || exporttype == MALXMLMangaExportType) && listservice.sharedInstance.getCurrentServiceID > 1 ? @"This may take some time." : @""] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self beginExport:exporttype];
        [self deselectcell:exporttype];
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self deselectcell:exporttype];
    }];
    [alertcontroller addAction:noaction];
    [alertcontroller addAction:yesaction];
    [self presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)deselectcell:(int)exporttype {
    switch (exporttype) {
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
        case CsvAnimeExportType:
            [_csvanimeformatted setSelected:NO animated:YES];
            break;
        case CsvMangaExportType:
            [_csvmangaformatted setSelected:NO animated:YES];
            break;
        default:
            break;
    }
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
        case CsvAnimeExportType:
        case CsvMangaExportType:
            [self exportCSV:type];
        default:
            break;
    }
}

- (void)exportXML:(int)type {
    int listtype = type == MALXMLAnimeExportType ? 0 : 1;
    _exportopmanager = [ExportOperationManager new];
    [self showloadingview:YES];
    _exportopmanager.hud = self.hud;
    __weak ExportListTableViewController *weakself = self;
    _exportopmanager.completion = ^(NSMutableArray * _Nonnull failedtitles, NSString * _Nonnull xml) {
        [weakself showloadingview:NO];
        [weakself saveToCoreData:xml withType:type];
        if (failedtitles.count > 0) {
            NSLog(@"One or more titles failed to export");
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Export" bundle:nil];
            FailedTitlesTableViewController *failedviewcontroller = (FailedTitlesTableViewController *)[storyboard instantiateViewControllerWithIdentifier:@"failedtitles"];
            [weakself.navigationController pushViewController:failedviewcontroller animated:YES];
            failedviewcontroller.failedexports = failedtitles;
            [failedviewcontroller.tableView reloadData];
            [failedviewcontroller showFailedMessage];
        }
        else {
            [weakself showMessage:@"Export Successful." withInformativeText:@"You can see your exported list in the Exported Lists section."];
        }
    };
    [_exportopmanager beginTitleIdBuildingForType:listtype];
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
    [self deselectcell:type];
}

- (void)exportCSV:(int)type {
    int listtype = type == CsvAnimeExportType ? 0 : 1;
    NSString *csvOutput = [self csvListForType:listtype];
    [self saveToCoreData:csvOutput withType:type];
    [self showMessage:@"Export Successful." withInformativeText:@"You can see your exported list in the Exported Lists section."];
    [self deselectcell:type];
}

- (NSString *)csvListForType:(int)type {
    int listtype = type;
    NSString *currentservicename = listservice.sharedInstance.currentservicename.lowercaseString;
    listservice *lservice = listservice.sharedInstance;
    NSDictionary *list = [AtarashiiListCoreData retrieveEntriesForUserId:[lservice getCurrentUserID] withService:[lservice getCurrentServiceID] withType:listtype];
    NSMutableString *csvoutput = [NSMutableString new];
    // Write CSV Header
    if (listtype == 0) {
        [csvoutput appendFormat:@"\"%@_title_id\",\"title\",\"episodes\",\"type\",\"current_status\",\"current_progress\",\"rating\",\"reconsume_count\",\"comments\",\"start_date\",\"end_date\"\n",currentservicename];
    }
    else {
        [csvoutput appendFormat:@"\"%@_title_id\",\"title\",\"chapters\",\"volumes\",\"type\",\"current_status\",\"current_progress\",\"current_progress_volumes\",\"rating\",\"reconsume_count\",\"comments\",\"start_date\",\"end_date\"\n",currentservicename];
    }
    NSArray *alist = listtype == 0 ? list[@"anime"] : list[@"manga"];
    for (NSDictionary *entry in alist) {
        int score = lservice.getCurrentServiceID == 2 ? [RatingTwentyConvert translateKitsuTwentyScoreToMAL:entry[@"score"] && entry[@"score"] != [NSNull null] ? ((NSNumber *)entry[@"score"]).intValue : 0] : lservice.getCurrentServiceID == 1 ? ((NSNumber *)entry[@"score"]).intValue * 10 : ((NSNumber *)entry[@"score"]).intValue;
        if (listtype == 0) {
            [csvoutput appendFormat:@"%@,\"%@\",%@,\"%@\",\"%@\",%@,%@,%@,\"%@\",\"%@\",\"%@\"\n", entry[@"id"],entry[@"title"],entry[@"episodes"],entry[@"type"], entry[@"watched_status"], entry[@"watched_episodes"], @(score), entry[@"rewatch_count"], entry[@"comments"] && entry[@"comments"] != [NSNull null] ? entry[@"comments"] : @"", entry[@"watching_start"] && entry[@"watching_start"] != [NSNull null] ? entry[@"watching_start"] : @"",entry[@"watching_end"] && entry[@"watching_end"] != [NSNull null] ? entry[@"watching_end"] : @""];
        }
        else {
            [csvoutput appendFormat:@"%@,\"%@\",%@,%@,\"%@\",\"%@\",%@,%@,%@,%@,\"%@\",\"%@\",\"%@\"\n", entry[@"id"],entry[@"title"],entry[@"chapters"],entry[@"volumes"],entry[@"type"], entry[@"read_status"], entry[@"chapters_read"], entry[@"volumes_read"], @(score), entry[@"reread_count"], entry[@"comments"] && entry[@"comments"] != [NSNull null] ? entry[@"comments"] : @"", entry[@"reading_start"] && entry[@"reading_start"] != [NSNull null] ? entry[@"reading_start"] : @"",entry[@"reading_end"] && entry[@"reading_end"] != [NSNull null] ? entry[@"reading_end"] : @""];
        }
    }
    return csvoutput;
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
    int mediatype = (exporttype == MALXMLAnimeExportType || exporttype == JsonAnimeExportType || exporttype == CsvAnimeExportType) ? 0 : 1;
    switch (exporttype) {
        case MALXMLAnimeExportType:
        case MALXMLMangaExportType:
            format = @"xml";
            break;
        case JsonAnimeExportType:
        case JsonMangaExportType:
            format = @"json";
            break;
        case CsvAnimeExportType:
        case CsvMangaExportType:
            format = @"csv";
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
        self.navigationItem.backBarButtonItem.enabled = NO;
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = @"Exporting...";
        if (@available(iOS 13, *)) { }
        else {
            _hud.bezelView.blurEffectStyle = [NSUserDefaults.standardUserDefaults boolForKey:@"darkmode"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
            _hud.contentColor = [ThemeManager sharedCurrentTheme].textColor;
        }
    }
    else {
        [_hud hideAnimated:YES];
        self.navigationItem.backBarButtonItem.enabled = YES;
    }
}

@end
