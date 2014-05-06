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
@property (copy) NSArray *messages;
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
    } else if (info[@"SSID"]) {
        self.detailDescriptionLabel.text = [NSString stringWithFormat:
            @"Connect to WiFi: %@\nBrowse to: %@", info[@"SSID"], info[@"URL"]];
    }
    
NSLog(@"INFO IS %@", info);
    if (info[@"query"]) {
        // TODO: use live updates
        CBLQuery* query = info[@"query"];
        NSMutableArray* messages = [NSMutableArray array];
        for (CBLQueryRow* row in [query run:nil]) {
            CBLDocument* doc = [query.database documentWithID:row.documentID];
            NSURL* snapURL = [doc.currentRevision attachmentNamed:@"snapshot"].contentURL;
            [messages addObject:@{
                @"message": doc[@"message"],
                @"snapshotPath": [snapURL path]
            }];
        };
        self.messages = messages;
    } else {
        self.messages = @[];
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
    return [self.messages count];
}

- (AQGridViewCell *)gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index
{
    CBMessageCell* cell = (id)[gridView dequeueReusableCellWithIdentifier:@"Message"];
    if (!cell) {
        cell = [[CBMessageCell alloc]
            initWithFrame: CGRectMake(0.0, 0.0, 64.0, 64.0) reuseIdentifier: @"Message"];
    }
    cell.imagePath = self.messages[index][@"snapshotPath"];
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
