//
//  PatronTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 4/1/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "PatronTableViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUDFramework/MBProgressHUDFramework.h>
#import "Utility.h"

@interface PatronTableViewController ()
@property (strong) MBProgressHUD *hud;
@property (strong) NSArray *patrons;
@end

@implementation PatronTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    AFHTTPSessionManager *manager = [Utility jsonmanager];
    [self showloadingview:YES];
    [manager GET:@"https://patreonlicensing.malupdaterosx.moe/patronslist.php" parameters:nil headers:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.patrons = responseObject;
        [self.tableView reloadData];
        [self showloadingview:NO];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self showloadingview:NO];
        UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:@"Unable to load patron list." message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alertcontroller addAction:okaction];
        [self presentViewController:alertcontroller animated:YES completion:nil];
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _patrons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"patron" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = _patrons[indexPath.row][@"name"];
    return cell;
}

- (void)showloadingview:(bool)show {
    if (show ) {
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = @"Loading";
    }
    else if (!show) {
        [_hud hideAnimated:YES];
    }
}

@end
