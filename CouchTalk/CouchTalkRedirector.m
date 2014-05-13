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

#import <SystemConfiguration/CaptiveNetwork.h>
#import <ifaddrs.h>
#import <arpa/inet.h>


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

+ (NSDictionary*)networkInfo
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
    NSString* wirelessIPv4 = nil;
    CFArrayRef ifaces = CNCopySupportedInterfaces();
    if (ifaces) {
        if (CFArrayGetCount(ifaces)) {
            CFStringRef ifN = CFArrayGetValueAtIndex(ifaces, 0);
            wirelessIPv4 = interfaceIP4s[(__bridge id)ifN];
            CFDictionaryRef info = CNCopyCurrentNetworkInfo(ifN);
            if (info) {
                wirelessSSID = [(__bridge id)CFDictionaryGetValue(info, kCNNetworkInfoKeySSID) copy];
                CFRelease(info);
            }
        }
        CFRelease(ifaces);
    }
    
    if (!wirelessSSID) wirelessSSID = @"Please connect to WiFi";
    if (!wirelessIPv4) wirelessIPv4 = interfaceIP4s.allValues[0];       // TODO: array might be empty!
    
    return @{
        @"SSID": wirelessSSID,
        @"IPv4": wirelessIPv4
    };
}

@end