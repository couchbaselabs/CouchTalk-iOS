//
//  CouchTalkRedirector.h
//  CouchTalk
//
//  Created by Nathan Vander Wilt on 4/25/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import "HTTPServer.h"

@interface CouchTalkRedirector : HTTPServer

+ (NSDictionary*)networkInfo;       // including this here for laziness…

@property (nonatomic) UInt16 targetPort;
@property (nonatomic, copy) NSString *targetPath;


@end
