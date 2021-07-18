//
//  AiringNotificationServiceSelector.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 11/13/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AiringNotificationServiceSelector.h"

@interface AiringNotificationServiceSelector ()
@property (strong, nonatomic) IBOutlet UITableViewCell *myanimelistservicecell;
@property (strong, nonatomic) IBOutlet UITableViewCell *kitsuservicecell;
@property (strong, nonatomic) IBOutlet UITableViewCell *anilistservicecell;
@end

@implementation AiringNotificationServiceSelector

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setcurrentservicestate];
}

- (void)setcurrentservicestate {
    switch ((int)[NSUserDefaults.standardUserDefaults integerForKey:@"airingnotification_service"]) {
        case 1:
            _myanimelistservicecell.accessoryType = UITableViewCellAccessoryCheckmark;
            _kitsuservicecell.accessoryType = UITableViewCellAccessoryNone;
            _anilistservicecell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case 2:
            _myanimelistservicecell.accessoryType = UITableViewCellAccessoryNone;
            _kitsuservicecell.accessoryType = UITableViewCellAccessoryCheckmark;
            _anilistservicecell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case 3:
            _myanimelistservicecell.accessoryType = UITableViewCellAccessoryNone;
            _kitsuservicecell.accessoryType = UITableViewCellAccessoryNone;
            _anilistservicecell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newindex = (int)indexPath.row+1;
    int currentservice = (int)[NSUserDefaults.standardUserDefaults integerForKey:@"airingnotification_service"];
    if (newindex != currentservice) {
        [NSUserDefaults.standardUserDefaults setInteger:newindex forKey:@"airingnotification_service"];
        [NSNotificationCenter.defaultCenter postNotificationName:@"AirNotifyServiceChanged" object:nil];
        [self setcurrentservicestate];
    }
    [[self.tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
}


@end
