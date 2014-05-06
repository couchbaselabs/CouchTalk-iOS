//
//  CBMessageCell.m
//  CouchTalk
//
//  Created by Nathan Vander Wilt on 5/5/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import "CBMessageCell.h"

@implementation CBMessageCell


- (id) initWithFrame: (CGRect) frame reuseIdentifier: (NSString *) aReuseIdentifier
{
    self = [super initWithFrame: frame reuseIdentifier: aReuseIdentifier];
    if (self) {
        UIImageView* snap = [[UIImageView alloc] init];
        snap.contentMode = UIViewContentModeScaleAspectFill;
        snap.clipsToBounds = YES;
        snap.frame = self.contentView.bounds;       // HACK: layout elsewhere?
        [self.contentView addSubview:snap];
        
        // TODO: assign actual snapshot via setter…
        snap.image = [UIImage imageWithContentsOfFile:@"/Users/natevw/Desktop/Clients/Couchbase/CouchTalk-iOS/page/static/splash.jpg"];
    }
    return self;
}


@end
