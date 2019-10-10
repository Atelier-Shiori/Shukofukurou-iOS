//
//  StreamingRegionTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 8/12/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "StreamingRegionTableViewController.h"
#import "UITableViewCellSelBackground.h"
#import "StreamDataRetriever.h"
#import "ThemeManager.h"

@interface StreamingRegionTableViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCellSelBackground *usStreamRegion;
@property (strong, nonatomic) IBOutlet UITableViewCellSelBackground *canStreamRegion;
@property (strong, nonatomic) IBOutlet UITableViewCellSelBackground *ukStreamRegion;
@property (strong, nonatomic) IBOutlet UITableViewCellSelBackground *ausStreamRegion;

@end

@implementation StreamingRegionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [ThemeManager fixTableView:self.tableView];
    
    [self setcellstate];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    [NSUserDefaults.standardUserDefaults setInteger:indexPath.row forKey:@"stream_region"];
    [self setcellstate];
    [StreamDataRetriever removeAllStreamEntries];
    [StreamDataRetriever performrestrieveStreamData];
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
}

- (void)setcellstate {
    long selectedregion = [NSUserDefaults.standardUserDefaults integerForKey:@"stream_region"];
    _usStreamRegion.accessoryType = selectedregion == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    _canStreamRegion.accessoryType = selectedregion == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    _ukStreamRegion.accessoryType = selectedregion == 2 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    _ausStreamRegion.accessoryType = selectedregion == 3 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

@end
