//
//  CharacterDetailViewController.h
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 10/2/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CharacterDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
typedef NS_ENUM(unsigned int, personType) {
    personTypeCharacter = 0,
    personTypeStaff = 1
};
@property (strong, nonatomic) IBOutlet UIImageView *posterimage;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (void)retrieveCharacterDetailsForID:(int)personid;
- (void)populateCharacterData:(NSDictionary *)data;
- (void)retrievePersonDetailsForID:(int)personid;
@end

NS_ASSUME_NONNULL_END
