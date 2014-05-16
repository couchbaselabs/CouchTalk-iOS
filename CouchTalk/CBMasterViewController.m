//
//  CBMasterViewController.m
//  CouchTalk
//
//  Created by Chris Anderson on 3/26/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import "CBMasterViewController.h"

#import "CBDetailViewController.h"
#import "CBAppDelegate.h"



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



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareServer:)];
    self.navigationItem.rightBarButtonItem = shareButton;
    self.detailViewController = (CBDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (IBAction)shareServer:(id)sender
{
    NSDictionary* wifi = [UIApplication cb_sharedDelegate].wifi;
    NSString *message = [NSString stringWithFormat:@"Join my chat server on WiFi network: %@", wifi[@"SSID"]];
    NSURL *link = wifi[@"URL"];
    NSArray *items = @[message, link];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self.navigationController presentViewController:activityVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setObjects:(NSArray*)objects
{
    _objects = [objects mutableCopy];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateWiFi
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section) ? _objects.count : 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // TODO: these should come from localized strings file…
    return (section) ? @"Active rooms:" : @"Connection info:";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return (section) ? nil : @"NOTE: Some wireless access points block direct communication between devices, even when they are all connected to the same network!";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary* info = [self detailItemForIndexPath:indexPath];
    if (indexPath.section) {
        cell.textLabel.text = info[@"room"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.userInteractionEnabled = YES;
    } else {
        if (info) cell.textLabel.text = (indexPath.row) ? info[@"SSID"] : [info[@"URL"] absoluteString];
        else cell.textLabel.text = @"No WiFi!";
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
    }
    return cell;
}

- (id)detailItemForIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section) ? self.objects[indexPath.row] : [UIApplication cb_sharedDelegate].wifi;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.detailViewController.detailItem = [self detailItemForIndexPath:indexPath];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary* object = [self detailItemForIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:object];
    }
}

@end
