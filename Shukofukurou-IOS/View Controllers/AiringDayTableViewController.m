//
//  AiringDayTableViewController.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AiringDayTableViewController.h"
#import "ThemeManager.h"

@interface AiringDayTableViewController ()
@property (strong) NSArray *days;
@end

@implementation AiringDayTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTheme];
    _days = @[@"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", @"Sunday", @"Unknown"];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setTheme];
}

- (void)setTheme {
    if (self.navigationController.popoverPresentationController) {
        if (@available(iOS 13, *)) { }
        else {
            self.navigationController.popoverPresentationController.backgroundColor =  [ThemeManager sharedCurrentTheme].viewBackgroundColor;
        }
    }
}

- (void)viewDidLayoutSubviews {
    self.preferredContentSize = CGSizeMake(320, self.tableView.contentSize.height);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _days.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    return tableView.sectionHeaderHeight;
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
