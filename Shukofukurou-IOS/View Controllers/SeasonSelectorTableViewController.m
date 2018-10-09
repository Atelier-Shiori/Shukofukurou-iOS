//
//  SeasonSelectorTableViewController.m
//  Hiyoko
//
//  Created by 香風智乃 on 9/17/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SeasonSelectorTableViewController.h"

@interface SeasonSelectorTableViewController ()
@property (strong) NSArray *selections;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationitem;
@property int selectiontype;
@end

@implementation SeasonSelectorTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)generateselectionitems:(int)selectiontype {
    _selectiontype = selectiontype;
    switch (_selectiontype) {
        case seasonselect: {
            _navigationitem.title = @"Select a Season";
            _selections = @[@"Winter", @"Spring", @"Summer", @"Fall"];
            break;
        }
        case yearselect: {
            _navigationitem.title = @"Select a Year";
            _selections = [self generateYearArray];
            break;
        }
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _selections.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (_selectiontype) {
        case seasonselect: {
            NSString *seasonname = _selections[indexPath.row];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"daycell" forIndexPath:indexPath];
            
            // Configure the cell...
            cell.textLabel.text = seasonname;
            if ([seasonname isEqualToString:_selectedseason]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            return cell;
        }
        case yearselect: {
            NSString *year = ((NSNumber *)_selections[indexPath.row]).stringValue;
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"daycell" forIndexPath:indexPath];
            
            // Configure the cell...
            cell.textLabel.text = year;
            if (((NSNumber *)_selections[indexPath.row]).intValue == _year) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            return cell;
        }
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (_selectiontype) {
        case seasonselect: {
            _seasonChanged(_selections[indexPath.row]);
            break;
        }
        case yearselect: {
            _yearChanged(((NSNumber *)_selections[indexPath.row]).intValue);
            break;
        }
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark helpers
- (NSArray *)generateYearArray {
    NSMutableArray *tmparray = [NSMutableArray new];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
    int currentyear = (int)components.year;
    while (currentyear >= 1990) {
        [tmparray addObject:@(currentyear)];
        currentyear--;
    }
    return tmparray.copy;
}
@end
