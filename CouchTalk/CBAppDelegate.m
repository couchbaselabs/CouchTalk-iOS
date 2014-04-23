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

NSString* const HOST_URL = @"http://sync.couchbasecloud.com/couchtalk-dev/";      // TODO: move into app's plist or something?
NSString* const ITEM_TYPE = @"com.couchbase.labs.couchtalk.message-item";

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
    NSURL* centralDatabase = [NSURL URLWithString:HOST_URL];
    CBLReplication* pullReplication = [database createPullReplication:centralDatabase];
    // NOTE: for now just sync everything like the browser app does
    //pullReplication.channels = @[ @"room-testing123" ];
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
    
    [database setFilterNamed: @"CouchTalk/roomItems" asBlock: FILTERBLOCK({
        // WORKAROUND: https://github.com/couchbase/couchbase-lite-ios/issues/321
        /*
        function expando(prefix, string) {
          var params = {};
          params[prefix+'LEN'] = string.length;
          Array.prototype.forEach.call(string, function (s,i) {
            params[''+prefix+i] = s.charCodeAt(0);
          });
          return params;
        }
        var o = expando('room', "😄 Happy π day!");
        Object.keys(o).map(function (k) { return [k,o[k]].join('='); }).join('&');
        */
        NSUInteger roomLen = [params[@"roomLEN"] unsignedIntegerValue];
        if (roomLen > 64) return NO;            // sanity check
        unichar roomBuffer[roomLen];            // conveniently, JavaScript also pre-dates Unicode 2.0
        for (NSUInteger i = 0, len = roomLen; i < len; ++i) {
            NSString* key = ([NSString stringWithFormat:@"room%u", i]);
            roomBuffer[i] = [params[key] unsignedShortValue];
        }
        NSString* roomName = [[NSString alloc] initWithCharactersNoCopy:roomBuffer length:roomLen freeWhenDone:NO];
        
        //NSString* roomName = params[@"room"];
        return (
            [revision[@"type"] isEqualToString:ITEM_TYPE] &&
            [revision[@"room"] isEqualToString:roomName]
        );
    })];
    
    
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
