//
//  CBMasterViewController.h
//  CouchTalk
//
//  Created by Chris Anderson on 3/26/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBDetailViewController;

@interface CBMasterViewController : UITableViewController

@property (strong, nonatomic) CBDetailViewController *detailViewController;

@property (copy) NSDictionary* wifi;
@property (copy) NSArray* objects;

@end
