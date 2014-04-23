//
//  CBAppDelegate.m
//  CouchTalk
//
//  Created by Chris Anderson on 3/26/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import "CBAppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>
#import <CouchbaseLiteListener/CBLListener.h>

@implementation CBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    
    [self setupCouchbaseListener];
    
    return YES;
}

- (void) startReplicationsWithDatabase:(CBLDatabase *)database {
    // TODO: move centralDatabase URL into app's plist or something…
    NSURL* centralDatabase = [NSURL URLWithString:@"http://sync.couchbasecloud.com/couchtalk-dev/"];
    CBLReplication* pullReplication = [database createPullReplication:centralDatabase];
    /* NOTE: for now just sync everything like the browser app does
    pullReplication.filter = @"sync_gateway/bychannel";
    pullReplication.filterParams = @{
        // TODO: we really need a ReplicationManager class that'll update these (based on ???)
        //       maybe we can collect an (ever-growing) NSSet of every locally-posted doc.room
        @"channels" : @"room-testing123"
    };
    */
    [pullReplication start];
    
    CBLReplication* pushReplication = [database createPushReplication:centralDatabase];
    pushReplication.continuous = YES;
    [pushReplication start];
}

- (void) setupCouchbaseListener {
    CBLManager* manager = [CBLManager sharedInstance];
    NSError *error;
    CBLDatabase* database = [manager databaseNamed:@"couchtalk" error:&error];
    [self startReplicationsWithDatabase:database];
    
    CBLListener* _listener = [[CBLListener alloc] initWithManager: manager port: 59840];
    BOOL ok = [_listener start: &error];
    if (ok) {
        UInt16 actualPort = _listener.port;  // the actual TCP port it's listening on
        NSLog(@"listening on %d", actualPort);
    } else {
        NSLog(@"Couchbase Lite listener not started");
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
