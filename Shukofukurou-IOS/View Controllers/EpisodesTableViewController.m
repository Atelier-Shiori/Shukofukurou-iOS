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

@interface EpisodesTableViewController ()
@property (strong) NSArray *episodes;
@end

@implementation EpisodesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)loadEpisodeListForTitleId:(int)titleid {
    switch ([listservice getCurrentServiceID]) {
        case 2: {
            [Kitsu retrieveEpisodesList:titleid completion:^(id responseObject) {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
