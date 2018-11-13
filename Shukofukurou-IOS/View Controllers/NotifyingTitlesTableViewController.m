//
//  NotifyingTitlesTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/13/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "NotifyingTitlesTableViewController.h"
#import "AiringNotificationManager.h"
#import "AppDelegate.h"

@import CoreData;

@interface NotifyingTitlesTableViewController ()
@property (strong) NSArray *notificationitems;
@end

@implementation NotifyingTitlesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)loadNotifications {
    _notificationitems = [[AiringNotificationManager sharedAiringNotificationManager] getAllNotifications:YES];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _notificationitems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject * notification = _notificationitems[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"entrycell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [notification valueForKey:@"title"];
    if (((NSNumber *)[notification valueForKey:@"enabled"]).boolValue) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObjectContext *moc = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
    NSManagedObject * notification = _notificationitems[indexPath.row];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    bool enabled = !((NSNumber *)[notification valueForKey:@"enabled"]).boolValue;
    [notification setValue:@(enabled) forKey:@"enabled"];
    [moc save:nil];
    cell.accessoryType = enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    AiringNotificationManager *anm = [AiringNotificationManager sharedAiringNotificationManager];
    if (enabled) {
        [anm setNotification:notification];
    }
    else {
        [anm removependingnotification:((NSNumber *)[notification valueForKey:@"anilistid"]).intValue];
    }
    [cell setSelected:NO animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


@end
