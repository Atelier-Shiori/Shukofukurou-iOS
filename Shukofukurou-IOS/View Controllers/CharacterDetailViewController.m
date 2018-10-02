//
//  CharacterDetailViewController.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/2/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "CharacterDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "listservice.h"
#import "TitleInfoTableViewCell.h"
#import "PersonTableViewCell.h"
#import "TitleInfoViewController.h"
#import "NSString+HTMLtoNSAttributedString.h"

@interface CharacterDetailViewController ()
@property (strong) NSDictionary *items;
@property (strong) NSArray *sections;
@property (strong) NSString *website_url;
@property int personid;
@property int persontype;
@end

@implementation CharacterDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)retrievePersonDetailsForID:(int)personid {
    _personid = personid;
    _persontype = personTypeStaff;
    self.navigationItem.hidesBackButton = YES;
    [listservice retrievePersonDetails:_personid completion:^(id responseObject) {
        //NSLog(@"%@",[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingSortedKeys error:nil] encoding:NSUTF8StringEncoding]);
        [self populatePersonData:responseObject];
        self.navigationItem.hidesBackButton = NO;
    } error:^(NSError *error) {
        NSLog(@"%@",error);
        [self.navigationController popViewControllerAnimated:YES];
        self.navigationItem.hidesBackButton = NO;
    }];
}

- (void)populatePersonData:(NSDictionary *)data {
    NSMutableDictionary *persondetails = [NSMutableDictionary new];
    NSMutableArray *detailsArray = [NSMutableArray new];
    self.navigationItem.title = data[@"name"];
    [self loadimage:(NSString *)data[@"image_url"]];
    [detailsArray addObject:@{@"title" : @"Details", @"value" : data[@"more_details"], @"type" : @"longdetail"}];
    if (data[@"birthdate"] && ((NSString *)data[@"birthdate"]).length > 0) {
        [detailsArray addObject:@{@"title" : @"Birthdate", @"value" : data[@"birthdate"], @"type" : @"detail"}];
    }
    if (data[@"family_name"] && ((NSString *)data[@"family_name"]).length > 0) {
        [detailsArray addObject:@{@"title" : @"Family Name", @"value" : data[@"family_name"], @"type" : @"detail"}];
    }
    if (((NSNumber *)data[@"favorited_count"]).intValue > 0) {
        [detailsArray addObject:@{@"title" : @"Favorited", @"value" : ((NSNumber *)data[@"favorited_count"]).stringValue, @"type" : @"detail"}];
    }
    if (data[@"native_name"] && ((NSString *)data[@"native_name"]).length > 0) {
        [detailsArray addObject:@{@"title" : @"Native Name", @"value" : data[@"native_name"], @"type" : @"detail"}];
    }
    if (data[@"website_url"] && ((NSString *)data[@"website_url"]).length > 0) {
        _website_url = data[@"website_url"];
    }
    persondetails[@"Details"] = detailsArray;
    persondetails[@"Anime Staff Positions"] = data[@"anime_staff_positions"];
    persondetails[@"Published Manga"] = data[@"published_manga"];
    persondetails[@"Voice Acting Roles"] = data[@"voice_acting_roles"];
    _items = persondetails.copy;
    NSMutableArray *tmpsections = [NSMutableArray new];
    [tmpsections addObject:@"Details"];
    if (((NSArray *)persondetails[@"Anime Staff Positions"]).count > 0) {
        [tmpsections addObject:@"Anime Staff Positions"];
    }
    if (((NSArray *)persondetails[@"Published Manga"]).count > 0) {
        [tmpsections addObject:@"Published Manga"];
    }
    if (((NSArray *)persondetails[@"Voice Acting Roles"]).count > 0) {
        [tmpsections addObject:@"Voice Acting Roles"];
    }
    _sections = tmpsections.copy;
    [self.tableView reloadData];
}

- (void)populateCharacterData:(NSDictionary *)data {
    NSMutableDictionary *persondetails = [NSMutableDictionary new];
    NSMutableArray *detailsArray = [NSMutableArray new];
    _personid = ((NSNumber *)data[@"id"]).intValue;
    _persontype = personTypeCharacter;
    self.navigationItem.title = data[@"name"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadimage:(NSString *)data[@"image"]];
    });
    [detailsArray addObject:@{@"title" : @"Details", @"value" : data[@"description"], @"type" : @"longdetail"}];
    [detailsArray addObject:@{@"title" : @"Role", @"value" : data[@"role"], @"type" : @"detail"}];
    persondetails[@"Details"] = detailsArray;
    persondetails[@"Voice Actors"] = data[@"actors"];
    _items = persondetails.copy;
    _sections = @[@"Details", @"Voice Actors"];
    [self.tableView reloadData];
}
- (IBAction)showoptions:(id)sender {
    UIAlertController *options = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak CharacterDetailViewController *weakSelf = self;
    [options addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"View on %@", [listservice currentservicename]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf performViewOnListSite];
    }]];
    [options addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf performShare:sender];
    }]];
    [options addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    
    options.popoverPresentationController.barButtonItem = sender;
    options.popoverPresentationController.sourceView = self.view;
    
    [self
     presentViewController:options
     animated:YES
     completion:nil];
}

- (void)performViewOnListSite {
    NSString *URL = [self getTitleURL];
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:URL] options:@{} completionHandler:^(BOOL success) {}];
}

- (void)performShare:(id)sender {
    NSArray *activityItems = @[[NSURL URLWithString:[self getTitleURL]]];
    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    activityViewControntroller.popoverPresentationController.barButtonItem = sender;
    activityViewControntroller.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewControntroller animated:true completion:nil];
}

- (NSString *)getTitleURL {
    switch ([listservice getCurrentServiceID]) {
        case 1: {
            if (_persontype == personTypeStaff){
                return [NSString stringWithFormat:@"https://myanimelist.net/people/%i" ,_personid];
            }
            else {
                return [NSString stringWithFormat:@"https://myanimelist.net/character/%i", _personid];
            }
        }
        case 2: {
            if (_persontype == personTypeStaff) {
                return [NSString stringWithFormat:@"https://kitsu.io/people/%i", _personid];
            }
            else {
                return [NSString stringWithFormat:@"https://kitsu.io/character/%i", _personid];
            }
        }
        case 3: {
            if (_persontype == personTypeStaff) {
                return [NSString stringWithFormat:@"https://anilist.co/staff/%i", _personid];
            }
            else {
                return [NSString stringWithFormat:@"https://anilist.co/character/%i", _personid];
            }
        }
        default:
            return @"";
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)_items[_sections[section]]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sections[section];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     NSString *cellType = _sections[indexPath.section];
     NSDictionary *entry = _items[cellType][indexPath.row];
 
 // Configure the cell...
     if ([cellType isEqualToString:@"Details"]) {
         if ([(NSString *)entry[@"type"] isEqualToString:@"longdetail"]) {
             TitleInfoSynopsisTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:@"synopsiscell" forIndexPath:indexPath];
             detailcell.valueText.attributedText = [(NSString *)entry[@"value"] convertHTMLtoAttStr];
             return detailcell;
         }
         else if ([(NSString *)entry[@"type"] isEqualToString:@"detail"]) {
             TitleInfoBasicTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:@"titleinfocell" forIndexPath:indexPath];
             detailcell.textLabel.text = entry[@"title"];
             detailcell.detailTextLabel.text = entry[@"value"];
             return detailcell;
         }
     }
     else if ([cellType isEqualToString:@"Characters"] || [cellType isEqualToString:@"Voice Actors"]) {
         PersonSubtitleTableViewCell *subtitlecell = [tableView dequeueReusableCellWithIdentifier:@"charactercell" forIndexPath:indexPath];
         subtitlecell.titlelabel.text = entry[@"name"];
         if ([cellType isEqualToString:@"Characters"]) {
             subtitlecell.subtitlelabel.text = entry[@"role"];
         }
         else if ([cellType isEqualToString:@"Voice Actors"]) {
             subtitlecell.subtitlelabel.text = entry[@"language"];
         }
         [subtitlecell loadimage:entry[@"image"]];
         return subtitlecell;
     }
     else if ([cellType isEqualToString:@"Anime Staff Positions"] || [cellType isEqualToString:@"Published Manga"] || [cellType isEqualToString:@"Voice Acting Roles"]) {
         PersonSubtitleTableViewCell *subtitlecell = [tableView dequeueReusableCellWithIdentifier:@"charactercell" forIndexPath:indexPath];
         
         if ([cellType isEqualToString:@"Anime Staff Positions"]) {
             [subtitlecell loadimage:entry[@"anime"][@"image_url"]];
             subtitlecell.titlelabel.text = entry[@"anime"][@"title"];
             subtitlecell.subtitlelabel.text = entry[@"position"];
         }
         else if ([cellType isEqualToString:@"Published Manga"]) {
             [subtitlecell loadimage:entry[@"manga"][@"image_url"]];
             subtitlecell.titlelabel.text = entry[@"manga"][@"title"];
             subtitlecell.subtitlelabel.text = entry[@"position"];
         }
         else if ([cellType isEqualToString:@"Voice Acting Roles"]) {
             [subtitlecell loadimage:entry[@"image_url"]];
             subtitlecell.titlelabel.text = entry[@"anime"][@"title"];
             subtitlecell.subtitlelabel.text = [NSString stringWithFormat:@"%@ - %@", entry[@"name"], ((NSNumber *)entry[@"main_role"]).boolValue ? @"Main Role" : @"Supporting Role"];
         }
         return subtitlecell;
     }
      return [UITableViewCell new];
 }
 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellType = _sections[indexPath.section];
    NSDictionary *entry = _items[cellType][indexPath.row];
    if ([cellType isEqualToString:@"Anime Staff Positions"] || [cellType isEqualToString:@"Voice Acting Roles"]) {
        int titleid = ((NSNumber *)entry[@"anime"][@"id"]).intValue;
        TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"TitleInfo"];
        [self.navigationController pushViewController:titleinfovc animated:YES];
        [titleinfovc loadTitleInfo:titleid withType:0];
    }
    else if ([cellType isEqualToString:@"Published Manga"]) {
        int titleid = ((NSNumber *)entry[@"manga"][@"id"]).intValue;
        TitleInfoViewController *titleinfovc = (TitleInfoViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"TitleInfo"];
        [self.navigationController pushViewController:titleinfovc animated:YES];
        [titleinfovc loadTitleInfo:titleid withType:1];
    }
    else if ([cellType isEqualToString:@"Voice Actors"]) {
        CharacterDetailViewController *cdetailvc = [self.storyboard instantiateViewControllerWithIdentifier:@"characterdetail"];
        [self.navigationController pushViewController:cdetailvc animated:YES];
        [cdetailvc retrievePersonDetailsForID:((NSNumber *)entry[@"id"]).intValue];
    }
}

     
#pragma mark helpers
 - (void)loadimage:(NSString *)imageurl {
     if (imageurl.length > 0) {
         [_posterimage sd_setImageWithURL:[NSURL URLWithString:imageurl]];
     }
     else {
         _posterimage.image = [UIImage new];
     }
 }

@end
