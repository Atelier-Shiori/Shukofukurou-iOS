//
//  EpisodesTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/5/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "EpisodesTableViewController.h"
#import "EpisodeDetailViewController.h"
#import "EpisodesTableViewCell.h"
#import "listservice.h"
#import "ThemeManager.h"

@interface EpisodesTableViewController ()
@property (strong) NSArray *episodes;
@end

@implementation EpisodesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [ThemeManager fixTableView:self.tableView];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveNotification:) name:@"ThemeChanged" object:nil];
}

- (void)didReceiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"ThemeChanged"]) {
        [ThemeManager fixTableView:self.tableView];
    }
}

- (void)loadEpisodeListForTitleId:(int)titleid {
    switch ([listservice.sharedInstance getCurrentServiceID]) {
        case 2: {
            [listservice.sharedInstance.kitsuManager retrieveEpisodesList:titleid completion:^(id responseObject) {
                self.episodes = responseObject;
                if (self.episodes.count > 0) {
                    [self.tableView reloadData];
                }
                else {
                    [self showNoEpisodesAlert];
                }
            } error:^(NSError *error) {
                NSLog(@"%@", error);
                [self.navigationController popViewControllerAnimated:YES];
            }];
            break;
        }
        default: {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}
- (void)showNoEpisodesAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Episode Information" message:@"There is no episode information for this title." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    return tableView.sectionHeaderHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _episodes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *episodeInfo = _episodes[indexPath.row];
    EpisodesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"episodecell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.titlelabel.text = episodeInfo[@"episodeTitle"];
    cell.subtitlelabel.text = [NSString stringWithFormat:@"Episode %@", episodeInfo[@"episodeNumber"]];
    [cell loadimage:episodeInfo[@"thumbnail"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *episodeInfo = _episodes[indexPath.row];
    EpisodeDetailViewController *epidetailvc = [self.storyboard instantiateViewControllerWithIdentifier:@"episodedetail"];
    [self.navigationController pushViewController:epidetailvc animated:YES];
    [epidetailvc retrieveEpisodeDetail:((NSNumber *)episodeInfo[@"episodeId"]).intValue withTitleId:((NSNumber *)episodeInfo[@"titleId"]).intValue];
}

@end
