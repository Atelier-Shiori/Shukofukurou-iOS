//
//  AiringDayTableViewController.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AiringDayTableViewController.h"

@interface AiringDayTableViewController ()
@property (strong) NSArray *days;
@end

@implementation AiringDayTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _days = @[@"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", @"Sunday", @"Unknown"];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _days.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *dayname = _days[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"daycell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = dayname;
    if ([dayname isEqualToString:_selectedday]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.listChanged(_days[indexPath.row]);
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
