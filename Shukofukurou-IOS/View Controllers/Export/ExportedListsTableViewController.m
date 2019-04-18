//
//  ExportedListsTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/26/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "ExportedListsTableViewController.h"
#import "AppDelegate.h"
#import "UITableViewCellSelBackground.h"
#import "ThemeManager.h"

@interface ExportedListsTableViewController ()
@property (strong) NSDictionary *exportedlists;
@property (strong) NSArray *allsections;
@property (strong) NSManagedObjectContext *moc;
@end

@implementation ExportedListsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _moc = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self populateDictionaries];
}

- (void)populateDictionaries {
    NSFetchRequest *listFetch = [[NSFetchRequest alloc] init];
    listFetch.entity = [NSEntityDescription entityForName:@"ExportedLists" inManagedObjectContext:self.moc];
    NSError *error = nil;
    NSMutableArray *xml = [NSMutableArray new];
    NSMutableArray *json = [NSMutableArray new];
    NSMutableArray *csv = [NSMutableArray new];
    for (NSManagedObject *obj in [self.moc executeFetchRequest:listFetch error:&error]) {
        if ([(NSString *)[obj valueForKey:@"format"] isEqualToString:@"xml"]) {
            [xml addObject:obj];
        }
        else if ([(NSString *)[obj valueForKey:@"format"] isEqualToString:@"json"]) {
            [json addObject:obj];
        }
        else if ([(NSString *)[obj valueForKey:@"format"] isEqualToString:@"csv"]) {
            [csv addObject:obj];
        }
    }
    _exportedlists = @{@"MAL XML Formatted" : xml.copy, @"JSON Formatted" : json.copy, @"Comma Delimited" : csv.copy };
    _allsections = _exportedlists.allKeys;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _allsections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)_exportedlists[_allsections[section]]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _allsections[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __block UISwipeCellNoBackground *cell = [UISwipeCellNoBackground new];
    NSManagedObjectContext *obj = ((NSArray *)_exportedlists[_allsections[indexPath.section]])[indexPath.row];
    // Configure the cell
    cell.textLabel.text = [obj valueForKey:@"title"];
    cell.textLabel.textColor = [ThemeManager.sharedCurrentTheme textColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    __weak ExportedListsTableViewController *weakself = self;
    cell.rightButtons = @[[MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"delete"] backgroundColor:UIColor.redColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        NSManagedObject *list = ((NSArray *)weakself.exportedlists[weakself.allsections[indexPath.section]])[indexPath.row];
        [weakself promptdelete:list];
        return true;
    }], [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"export"] backgroundColor:[UIColor colorWithRed:1.00 green:0.58 blue:0.00 alpha:1.0] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        NSManagedObject *list = ((NSArray *)weakself.exportedlists[weakself.allsections[indexPath.section]])[indexPath.row];
        [weakself performexport:list withCell:cell];
        return true;
    }]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwipeCellNoBackground *cell = (UISwipeCellNoBackground *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell showSwipe:MGSwipeDirectionRightToLeft animated:YES];
}

- (void)promptdelete:(NSManagedObject *)obj {
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Delete Exported List?" message:[NSString stringWithFormat:@"Do you want to delete list %@? Once done, it cannot be undone.", [obj valueForKey:@"title"]] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesaction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performDelete:obj];
    }];
    UIAlertAction *noaction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertcontroller addAction:noaction];
    [alertcontroller addAction:yesaction];
    [self presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)performDelete:(NSManagedObject *)obj {
    [_moc deleteObject:obj];
    [_moc save:nil];
    [self populateDictionaries];
}

- (void)performexport:(NSManagedObject *)obj withCell:(UITableViewCell *)cell {
    NSArray *activityItems = @[[self writeToFile:obj]];
    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityViewControntroller.popoverPresentationController.sourceView = cell;
        activityViewControntroller.popoverPresentationController.sourceRect = cell.bounds;
        activityViewControntroller.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
    }
    [self presentViewController:activityViewControntroller animated:true completion:nil];
}

- (NSURL *)documentDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)writeToFile:(NSManagedObject *)obj {
    NSString *path = [NSString stringWithFormat:@"%@/%@.%@", [self documentDirectory].path, [obj valueForKey:@"title"], [obj valueForKey:@"format"]];
    NSError *error;
    if ([(NSString *)[obj valueForKey:@"data"] writeToFile:path atomically:YES encoding:NSUnicodeStringEncoding error:&error]) {
        return [NSURL fileURLWithPath:path];
    }
    NSLog(@"Error writing file: %@", error);
    return nil;
}

@end
