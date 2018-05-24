//
//  FHSessionURLProtocol.m
//  FHURLProtocolDemo
//
//  Created by 陈建蕾 on 2018/5/24.
//  Copyright © 2018年 陈建蕾. All rights reserved.
//

#import "FHSessionURLProtocol.h"

static NSString * const FHSESSIONURLPROTOCOL = @"FHSESSIONURLPROTOCOL";
@interface FHSessionURLProtocol ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation FHSessionURLProtocol

+ (void)regist {
    [NSURLProtocol registerClass:[self class]];
}

+ (void)unRegist {
    [NSURLProtocol unregisterClass:[self class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:FHSESSIONURLPROTOCOL inRequest:request]) {
        return NO;
    }
    
    if ([request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"]) {
        return YES;
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    //此处可以添加head URL重定向等操作
    NSMutableURLRequest *tableURLRequest = [request mutableCopy];
    [tableURLRequest setValue:@"token" forHTTPHeaderField:@"token"];
    return tableURLRequest;
}



@end
