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
#import <AVFoundation/AVFoundation.h>

#import "CBMessageCell.h"
#import "CBAppDelegate.h"

@interface CBDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) CBLLiveQuery *snapsQuery;
@property (copy, nonatomic) NSArray *messages;
@property (copy, nonatomic) NSURL *audioPlayback;
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

- (void)setSnapsQuery:(CBLLiveQuery *)newQuery {
    if (_snapsQuery != newQuery) {
        self.messages = @[];
        [_snapsQuery removeObserver:self forKeyPath:@"rows"];
        _snapsQuery = newQuery;
        [_snapsQuery addObserver:self forKeyPath:@"rows" options:0 context:NULL];
    }
}

- (void)setMessages:(NSArray *)newMessages {
    _messages = [newMessages copy];
    [self.messageGridView reloadData];
}

- (void)setAudioPlayback:(NSURL *)url {
    // HACK: we're actually storing an AVAudioPlayer to the ivar! [getter presumed to be unused]
    AVAudioPlayer* player = (id)_audioPlayback;
    if (player) [player stop];
    if ([AVAudioPlayer instancesRespondToSelector:@selector(initWithContentsOfURL:fileTypeHint:error:)]) {
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:url fileTypeHint:AVFileTypeWAVE error:nil];
    } else {
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    }
    [player play];
    _audioPlayback = (id)player;
}

- (void)configureView
{
    // Update the user interface for the detail item.
    NSDictionary* info = self.detailItem;
    if (!info) return;
    else if (info[@"room"]) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateStyle = NSDateFormatterShortStyle;
        fmt.timeStyle = NSDateFormatterShortStyle;
        self.detailDescriptionLabel.text = [NSString stringWithFormat:@"Room first seen:\n%@", [fmt stringFromDate:info[@"added"]]];
        self.navigationItem.title = info[@"room"];
    } else if (info[@"SSID"]) {
        self.detailDescriptionLabel.text = [NSString stringWithFormat:
            @"Connect to WiFi: %@\nBrowse to: %@", info[@"SSID"], info[@"URL"]];
    }
    
    if (info[@"query"]) {
        self.snapsQuery = ((CBLQuery*)info[@"query"]).asLiveQuery;
    } else {
        self.snapsQuery = nil;
    }
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareRoom:)];
    self.navigationItem.rightBarButtonItem = shareButton;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.snapsQuery) {
        NSMutableArray* messages = [NSMutableArray array];
        for (CBLQueryRow* row in self.snapsQuery.rows) {
            CBLDocument* doc = [self.snapsQuery.database documentWithID:row.documentID];
            NSURL* snapURL = [doc.currentRevision attachmentNamed:@"snapshot"].contentURL;
            [messages addObject:@{
                @"message": doc[@"message"],
                @"snapshotPath": [snapURL path]
            }];
        };
        self.messages = messages;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)dealloc
{
    [_snapsQuery removeObserver:self forKeyPath:@"rows"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)shareRoom:(id)sender
{
    NSDictionary* wifi = [UIApplication cb_sharedDelegate].wifi;
    NSDictionary* info = self.detailItem;
    NSString *message = [NSString stringWithFormat:@"Join my chat room via WiFi network: %@", wifi[@"SSID"]];
    NSURL *link = [NSURL URLWithString:[@"#" stringByAppendingString:info[@"room"]] relativeToURL:wifi[@"URL"]];
    NSArray *items = @[message, link];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self.navigationController presentViewController:activityVC animated:YES completion:nil];
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
    
    CBLView* messageAudioView = [self.snapsQuery.database viewNamed:@"app/audioItemsByMessage"];
    CBLQuery* audioQuery = [messageAudioView createQuery];
    audioQuery.keys = @[
        self.messages[index][@"message"]
    ];
    for (CBLQueryRow* row in [audioQuery run:nil]) {
        CBLDocument* doc = [audioQuery.database documentWithID:row.documentID];
        self.audioPlayback = [doc.currentRevision attachmentNamed:@"audio"].contentURL;
    }
}


#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Rooms", @"Rooms");
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
