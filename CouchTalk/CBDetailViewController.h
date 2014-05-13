//
//  CBDetailViewController.h
//  CouchTalk
//
//  Created by Chris Anderson on 3/26/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AQGridView/AQGridView.h>

@interface CBDetailViewController : UIViewController <UISplitViewControllerDelegate, AQGridViewDataSource, AQGridViewDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) IBOutlet AQGridView *messageGridView;

@end
