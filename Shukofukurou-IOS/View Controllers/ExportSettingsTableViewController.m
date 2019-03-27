//
//  ExportSettingsTableViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 3/27/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "ExportSettingsTableViewController.h"
#import "UIViewThemed.h"

@interface ExportSettingsTableViewController ()
@property (strong, nonatomic) IBOutlet UISwitch *currentswitch;
@property (strong, nonatomic) IBOutlet UISwitch *completedswitch;
@property (strong, nonatomic) IBOutlet UISwitch *onholdswitch;
@property (strong, nonatomic) IBOutlet UISwitch *droppedswitch;
@property (strong, nonatomic) IBOutlet UISwitch *plannedswitch;

@end

@implementation ExportSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self loadSwitchStates];
}

- (void)loadSwitchStates {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    _currentswitch.on = [defaults boolForKey:@"updateonimportcurrent"];
    _completedswitch.on = [defaults boolForKey:@"updateonimportcurrent"];
    _onholdswitch.on = [defaults boolForKey:@"updateonimportonhold"];
    _droppedswitch.on = [defaults boolForKey:@"updateonimportdropped"];
    _plannedswitch.on = [defaults boolForKey:@"updateonimportplanned"];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    UIViewGroupHeader *view = [[UIViewGroupHeader alloc] initIsSidebar:false isFirstSection:section == 0 ? true : false];
    view.label.text = sectionTitle.uppercaseString;
    return view;
}
- (IBAction)switchtoggled:(id)sender {
    UISwitch *statusswitch = (UISwitch *)sender;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    switch (statusswitch.tag) {
        case 0:
            [defaults setBool:statusswitch.on forKey:@"updateonimportcurrent"];
            break;
        case 1:
            [defaults setBool:statusswitch.on forKey:@"updateonimportcompleted"];
            break;
        case 2:
            [defaults setBool:statusswitch.on forKey:@"updateonimportonhold"];
            break;
        case 3:
            [defaults setBool:statusswitch.on forKey:@"updateonimportdropped"];
            break;
        case 4:
            [defaults setBool:statusswitch.on forKey:@"updateonimportplanned"];
            break;
        default:
            break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
