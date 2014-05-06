//
//  CBDetailViewController.m
//  CouchTalk
//
//  Created by Chris Anderson on 3/26/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import "CBDetailViewController.h"

#import <AQGridView/AQGridView.h>
#import <CouchbaseLite/CouchbaseLite.h>

#import "CBMessageCell.h"

@interface CBDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation CBDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.
    NSDictionary* info = self.detailItem;
    if (!info) return;
    else if (info[@"room"]) {
        self.detailDescriptionLabel.text = [NSString stringWithFormat:@"%@ first seen %@", info[@"room"], info[@"added"]];
        // TODO: use info[@"query"] to display messages
        
//        CBLQuery* query = info[@"query"];
//        for (CBLQueryRow* row in [query run:nil]) {
//            self.messageGridView;
//        };
//        [self.messageGridView reloadData];
    } else if (info[@"SSID"]) {
        self.detailDescriptionLabel.text = [NSString stringWithFormat:
            @"Connect to WiFi: %@\nBrowse to: %@", info[@"SSID"], info[@"URL"]];
    }
    [self.messageGridView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark — Messages view

// see http://sapandiwakar.in/getting-started-with-aqgridview/
// and http://code.tutsplus.com/tutorials/design-build-a-small-business-app-aqgridview--mobile-9651

- (NSUInteger)numberOfItemsInGridView:(AQGridView *)gridView
{
    (void)gridView;
    // TODO: base off of item's query results…
    return 3;
}

- (AQGridViewCell *)gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index
{
    AQGridViewCell* cell = [gridView dequeueReusableCellWithIdentifier:@"Message"];
    if (!cell) {
        cell = [[CBMessageCell alloc]
            initWithFrame: CGRectMake(0.0, 0.0, 64.0, 64.0) reuseIdentifier: @"Message"];
    }
    // TODO: set image based on message
    (void)index;
    return cell;
}

- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)gridView
{
    (void)gridView;
    return CGSizeMake(64.0, 64.0);
}

- (void)gridView:(AQGridView*)gridView didSelectItemAtIndex:(NSUInteger)index {
    (void)gridView;
    // TODO: play message audio :-)
    (void)index;
NSLog(@"Clicked message %lu", (unsigned long)index);
}


#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
