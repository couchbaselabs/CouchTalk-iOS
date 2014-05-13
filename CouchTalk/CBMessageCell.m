//
//  CBMessageCell.m
//  CouchTalk
//
//  Created by Nathan Vander Wilt on 5/5/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import "CBMessageCell.h"


@interface CBMessageCell ()

@property (weak, nonatomic) UIImageView* snapView;

@end


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
        self.snapView = snap;
    }
    return self;
}

- (NSString *)imagePath
{
    return nil;     // HACK: nobody needs this…
}

- (void)setImagePath:(NSString *)imagePath
{
    self.snapView.image = [UIImage imageWithContentsOfFile:imagePath];
}

@end
