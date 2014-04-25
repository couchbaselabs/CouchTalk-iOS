//
//  CBMasterViewController.m
//  CouchTalk
//
//  Created by Chris Anderson on 3/26/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import "CBMasterViewController.h"

#import "CBDetailViewController.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#import <ifaddrs.h>
#import <arpa/inet.h>


@interface CBMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation CBMasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

+ (NSString*)networkInfo            // TODO: move this to the App Delegate along with necessary Reachability stuff…
{
    // collect IP4 address for each active interface, we'll figure out which one's the WiFi below
    // just use POSIX stuff, i.e. http://www.beej.us/guide/bgnet/output/html/multipage/inet_ntopman.html
    // c.f. http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically
    NSMutableDictionary* interfaceIP4s = [NSMutableDictionary dictionary];
    struct ifaddrs* iface = NULL;
    int err = getifaddrs(&iface);
    while (!err && iface) {
        if (iface->ifa_addr->sa_family == AF_INET) {
            char buff[INET_ADDRSTRLEN];
            struct sockaddr_in* addr = (void*)iface->ifa_addr;
            const char* iface_addr_str = inet_ntop(iface->ifa_addr->sa_family, &addr->sin_addr, buff, sizeof(buff));
            if (iface_addr_str) {
                NSString* ifN = [NSString stringWithUTF8String:iface->ifa_name];
                NSString* ip4 = [NSString stringWithUTF8String:iface_addr_str];
                interfaceIP4s[ifN] = ip4;
            }
        }
        iface = iface->ifa_next;
    }
    NSLog(@"Found IP4 addresses for interfaces: %@", interfaceIP4s);
    
    NSString* wirelessSSID = nil;
    CFArrayRef ifaces = CNCopySupportedInterfaces();
    if (!ifaces) return nil;
    if (ifaces && CFArrayGetCount(ifaces)) {
        CFStringRef en0 = CFArrayGetValueAtIndex(ifaces, 0);
        CFDictionaryRef info = CNCopyCurrentNetworkInfo(en0);
        wirelessSSID = [(__bridge id)CFDictionaryGetValue(info, kCNNetworkInfoKeySSID) copy];
        CFRelease(info);
    }
    if (ifaces) CFRelease(ifaces);
    
    
    // TODO: we'll also need to monitor general network reachability
    
    return wirelessSSID;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO: this info should come from the app delegate
    self.navigationItem.title = @"http://127.0.0.1:8080";
    NSLog(@"WiFi is %@", [[self class] networkInfo]);
    
	// Do any additional setup after loading the view, typically from a nib.
    /*
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (CBDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSDate *object = _objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSDate *object = _objects[indexPath.row];
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

@end
