//
//  CouchTalkRedirector.m
//  CouchTalk
//
//  Created by Nathan Vander Wilt on 4/25/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.
//

#import "CouchTalkRedirector.h"

#import "HTTPMessage.h"
#import "HTTPConnection.h"
#import "HTTPRedirectResponse.h"


@interface RedirectHandler : HTTPConnection
@end


@implementation RedirectHandler

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSString* scheme = (self.isSecureServer) ? @"https" : @"http";      // NOTE: assumes CBL has been set up for HTTPS too, if we were
    NSString* origHost = self->request.allHeaderFields[@"Host"];
    NSString* origPort = [NSString stringWithFormat:@"%u", self->config.server.listeningPort];
    NSString* host = [origHost stringByReplacingOccurrencesOfString:origPort withString:@"59840"];
    NSString* target = [NSString stringWithFormat:@"%@://%@/couchtalk/_design/app/index.html", scheme, host];
    return [[HTTPRedirectResponse alloc] initWithPath:target];
}

@end


@implementation CouchTalkRedirector

- (instancetype)init {
    self = [super init];
    self.connectionClass = [RedirectHandler class];
    return self;
}

@end