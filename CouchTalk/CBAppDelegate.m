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

//#import <CocoaHTTPServer/HTTPServer.h>    // pod is old broken version, and causes linker conflicts with CBL…
#import "CBMasterViewController.h"
#import "CouchTalkRedirector.h"



NSString* const HOST_URL = @"http://sync.couchbasecloud.com/couchtalk";      // TODO: move into app's plist or something?
NSString* const ITEM_TYPE = @"com.couchbase.labs.couchtalk.message-item";


@interface CBAppDelegate ()
@property (nonatomic) NSTimer *wifiPoller;
@property (nonatomic) BOOL monitoringWiFi;
@property (nonatomic) CouchTalkRedirector *redirector;

@property (nonatomic) CBLReplication *pushReplication;
@property (nonatomic) CBLReplication *pullReplication;
@end

@implementation CBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        
        // HACK: should probably use an IBOutlet or something instead…
        navigationController = [splitViewController.viewControllers firstObject];
        self.mainController = (id)navigationController.topViewController;
    } else {
        self.mainController = (id)(((UINavigationController*)self.window.rootViewController).visibleViewController);
    }
    
    [self setupCouchbaseListener];
    
    return YES;
}

- (void) setupCouchbaseListener {
    CBLManager* manager = [CBLManager sharedInstance];
    
    // WORKAROUND: only user-created data is allowed in iCloud; simply omit everything
    NSURL* storage = [NSURL fileURLWithPath:manager.directory isDirectory:YES];
    [storage setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    
    NSError *error;
    CBLDatabase* database = [manager existingDatabaseNamed:@"couchtalk" error:&error];
    
    if (!database) {
        NSString* cannedDbPath = [[NSBundle mainBundle] pathForResource: @"couchtalk"
                                                                 ofType: @"cblite"];
        NSString* cannedAttPath = [[NSBundle mainBundle] pathForResource: @"couchtalk attachments"
                                                                  ofType: @""];
        BOOL ok = [manager replaceDatabaseNamed: @"couchtalk"
                                 withDatabaseFile: cannedDbPath
                                  withAttachments: cannedAttPath
                                            error: &error];
        NSAssert(ok, @"Failed to install database: %@", error);
        database = [manager existingDatabaseNamed: @"couchtalk"
                                                           error: &error];
        NSAssert(database, @"Failed to open database");
    }
    
    CBLView* detailViewView = [database viewNamed:@"snapshotsByRoom"];
    [detailViewView setMapBlock: MAPBLOCK({
        if (
            [doc[@"type"] isEqualToString:ITEM_TYPE] &&
            [doc[@"snapshotNumber"] isEqual:@"join"]
        ) emit(doc[@"room"], nil);
    }) version:@"1.0"];
    
    CBLView* roomSnapsView = [database viewNamed:@"app/initialSnapshotsByRoomAndTimestamp"];
    [roomSnapsView setMapBlock: MAPBLOCK({
        if (
            [doc[@"type"] isEqualToString:ITEM_TYPE] &&
            ([doc[@"snapshotNumber"] isEqual:@"join"] || [doc[@"snapshotNumber"] isEqual:@(0)])
        ) emit(@[
            doc[@"room"],
            doc[@"timestamp"]
        ], doc[@"message"]);
    }) version:@"1.0"];
    
    CBLView* messageAudioView = [database viewNamed:@"app/audioItemsByMessage"];
    [messageAudioView setMapBlock: MAPBLOCK({
        if (
            [doc[@"type"] isEqualToString:ITEM_TYPE] &&
            !doc[@"snapshotNumber"]
        ) emit(doc[@"message"], nil);
    }) version:@"1.0"];
    
    
    NSURL* centralDatabase = [NSURL URLWithString:HOST_URL];
    self.pushReplication = [database createPushReplication:centralDatabase];
    self.pushReplication.continuous = YES;
    [self.pushReplication start];
    self.pullReplication = [database createPullReplication:centralDatabase];
    self.pullReplication.continuous = YES;
    // instead of starting, we wait until it has at least one channel (to avoid grabbing all!)
    
    NSMutableSet* channelsUsed = [NSMutableSet set];
    NSMutableArray* roomItems = [NSMutableArray array];
    void (^subscribeToRoom)(NSString*) = ^(NSString* room) {
        NSString* channel = [NSString stringWithFormat:@"room-%@", room];
        if (channel && ![channelsUsed containsObject:channel]) {
          [channelsUsed addObject:channel];
          self.pullReplication.channels = [channelsUsed allObjects];
            if (!self.pullReplication.running) {
                [self.pullReplication start];
            } else {
                [self.pullReplication restart];
            }
          NSLog(@"Now syncing with %@", self.pullReplication.channels);
          
          CBLQuery* query = [roomSnapsView createQuery];
          query.startKey = @[ room ];
          query.endKey = @[ room, @{} ];
          [roomItems addObject:@{
              @"room": room,
              @"query": query,
              @"added": [NSDate date]
          }];
          self.mainController.objects = roomItems;
        }
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:kCBLDatabaseChangeNotification object:database queue:nil usingBlock:^(NSNotification *note) {
      for (CBLDatabaseChange* change in note.userInfo[@"changes"]) {
        if (change.source) continue;    // handy! this means it was synced from remote (not that we'd get items from unsubscribed channels anyway though…)
        CBLDocument* doc = [database existingDocumentWithID:change.documentID];
        /* NOTE: the following code expects this Sync Gateway callback to be installed
        function(doc) {
          if (doc.type === 'com.couchbase.labs.couchtalk.message-item') {
            channel('room-'+doc.room);
          }
        }
        */
        if ([doc[@"type"] isEqualToString:ITEM_TYPE]) subscribeToRoom(doc[@"room"]);
      }
    }];
    subscribeToRoom(@"howto");
    
    [database setFilterNamed: @"app/roomItems" asBlock: FILTERBLOCK({
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
            NSString* key = ([NSString stringWithFormat:@"room%lu", (unsigned long)i]);
            roomBuffer[i] = [params[key] unsignedShortValue];
        }
        NSString* roomName = [[NSString alloc] initWithCharactersNoCopy:roomBuffer length:roomLen freeWhenDone:NO];
        
        //NSString* roomName = params[@"room"];
        return (
            [revision[@"type"] isEqualToString:ITEM_TYPE] &&
            [revision[@"room"] isEqualToString:roomName]
        );
    })];
    
    CBLListener* _listener = [[CBLListener alloc] initWithManager: manager port:0];
    BOOL ok = [_listener start: &error];
    if (ok) {
        UInt16 actualPort = _listener.port;  // the actual TCP port it's listening on
        NSLog(@"listening on %d", actualPort);
    } else {
        NSLog(@"Couchbase Lite listener not started");
    }
    
    CouchTalkRedirector* redirector = [[CouchTalkRedirector alloc] init];
    redirector.type = @"_http._tcp.";
    //[redirector setPort:8080];            // pros: easy to remember/type, cons: what if already in use?
    redirector.targetPort = _listener.port;
    redirector.targetPath = @"/couchtalk/_design/app/index.html";
    
    ok = [redirector start:&error];
    if (!ok) {
        NSLog(@"Couldn't start redirect helper: %@", error);
    } else {
        NSLog(@"Redirector listening on %u", redirector.listeningPort);
    }
    self.redirector = redirector;
}

- (void)upateWiFi:(__unused NSTimer *)timer
{
    NSDictionary* wifi = [CouchTalkRedirector networkInfo];
    if (wifi[@"IPv4"]) {
        UInt16 port = self.redirector.listeningPort;
        self.wifi = @{
            @"SSID": wifi[@"SSID"],
            @"URL": [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%u", wifi[@"IPv4"], port]],
            @"IPv4": wifi[@"IPv4"],
            @"port": @(port)
        };
    } else {
        self.wifi = nil;
    }
    [self.mainController updateWiFi];
}

- (void)setMonitoringWiFi:(BOOL)monitoringWiFi
{
    if (monitoringWiFi == _monitoringWiFi) return;
    if (monitoringWiFi) {
        NSTimer* poller = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(upateWiFi:) userInfo:nil repeats:YES];
        self.wifiPoller = poller;
        [poller fire];
    } else {
        [self.wifiPoller invalidate];
    }
    _monitoringWiFi = monitoringWiFi;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    self.monitoringWiFi = YES;
    application.idleTimerDisabled = YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    self.monitoringWiFi = NO;
    application.idleTimerDisabled = NO;
}


// TODO: start/pause replications here?
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
}
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
}


- (void)applicationWillTerminate:(UIApplication *)application
{
NSLog(@"applicationWillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end


@implementation UIApplication (CBAppDelegate)

+ (CBAppDelegate *)cb_sharedDelegate {
    return [UIApplication sharedApplication].delegate;
}

@end
