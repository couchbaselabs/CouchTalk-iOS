//
//  CBAppDelegate.h
//  CouchTalk
//
//  Created by Chris Anderson on 3/26/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBMasterViewController;

@interface CBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CBMasterViewController *mainController;

@end
