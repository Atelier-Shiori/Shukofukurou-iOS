//
//  ListEntryActionTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 天々座理世 on 7/29/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "ListEntryActionTableViewController.h"
#import "CellActionEnum.h"

@interface ListEntryActionTableViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *viewtitleoptioncell;
@property (strong, nonatomic) IBOutlet UITableViewCell *advancededitoptioncell;
@property (strong, nonatomic) IBOutlet UITableViewCell *showentryoptioncell;

@end

@implementation ListEntryActionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setcellstate];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    [NSUserDefaults.standardUserDefaults setInteger:indexPath.row forKey:@"cellaction"];
    [self setcellstate];
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
}

- (void)setcellstate {
    long selectedaction = [NSUserDefaults.standardUserDefaults integerForKey:@"cellaction"];
    _viewtitleoptioncell.accessoryType = selectedaction == ListActionViewTitle ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    _advancededitoptioncell.accessoryType = selectedaction == ListActionAdvancedEdit ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    _showentryoptioncell.accessoryType = selectedaction == ListActionShowEntryOptions ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}
@end
