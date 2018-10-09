//
//  SortTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/8/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "SortTableViewController.h"
#import <CoreActionSheetPicker/CoreActionSheetPicker.h>

@interface SortTableViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *sortbycell;
@property (weak, nonatomic) IBOutlet UISwitch *accendingswitch;
@property int type;
@end

@implementation SortTableViewController
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isEqual:_sortbycell]) {
        // Show Picker
        [self showPicker];
    }
}

- (void)loadSort:(NSString *)sortby withAccending:(bool)accending withType:(int)type {
    _sortbycell.detailTextLabel.text = sortby;
    _accendingswitch.on = accending;
    _type = type;
}

- (void)showPicker {
    NSArray *choices = @[];
    switch (_type) {
        case 0:
            choices = @[@"Title", @"Episodes", @"Watched Episodes", @"Score"];
            break;
        case 1:
            choices = @[@"Title", @"Chapters", @"Volumes", @"Chapters Read", @"Volumes Read", @"Score"];
            break;
    }
    int selectedsort = 0;
    for (NSString *strsort in choices) {
        if ([strsort isEqualToString:_sortbycell.detailTextLabel.text]) {
            break;
        }
        selectedsort++;
    }
    [ActionSheetStringPicker showPickerWithTitle:@"Sort by" rows:choices initialSelection:selectedsort doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        self.sortbycell.detailTextLabel.text = selectedValue;
        [self.sortbycell setSelected:NO animated:YES];
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        [self.sortbycell setSelected:NO animated:YES];
    } origin:_sortbycell];
}

- (IBAction)cancelaction:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveaction:(id)sender {
    self.listSortChanged(_sortbycell.detailTextLabel.text, _accendingswitch.on, _type);
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
@end
