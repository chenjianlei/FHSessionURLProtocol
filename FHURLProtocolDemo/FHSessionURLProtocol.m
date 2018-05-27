//
//  FHSessionURLProtocol.m
//  FHURLProtocolDemo
//
//  Created by 陈建蕾 on 2018/5/24.
//  Copyright © 2018年 陈建蕾. All rights reserved.
//

#import "FHSessionURLProtocol.h"
#import <objc/runtime.h>

@interface FHSessionConfiguration : NSObject
@property (nonatomic, assign, readonly) BOOL status;

+ (instancetype)shareInstance;

- (void)exchange;
- (void)unExchange;

@end

@interface FHSessionConfiguration ()
@property (nonatomic, assign, readwrite) BOOL status;
@end

@implementation FHSessionConfiguration

+ (instancetype)shareInstance {
    static FHSessionConfiguration *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [FHSessionConfiguration new];
    });
    return config;
}

- (instancetype)init {
    if (self = [super init]) {
        _status = NO;
    }
    return self;
}

- (void)exchange {
    self.status = YES;
    Class oClass = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self _exchangeMethod:@selector(protocolClasses) oClass:oClass tClass:[self class]];
}

- (void)unExchange {
    self.status = NO;
    Class oClass = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self _exchangeMethod:@selector(protocolClasses) oClass:oClass tClass:[self class]];
}

- (NSArray<Class> *)protocolClasses {
    return @[[FHSessionURLProtocol class]];
}

#pragma mark - Private
- (void)_exchangeMethod:(SEL)method oClass:(Class)oClass tClass:(Class)tClass {
    Method oMethod = class_getInstanceMethod(oClass, method);
    Method tMethod = class_getInstanceMethod(tClass, method);
    if (!oMethod || !tMethod) {
        NSLog(@"exchange Method failer");
    } else {
        method_exchangeImplementations(oMethod, tMethod);
    }
}

@end

static NSString * const FHSESSIONURLPROTOCOL = @"FHSESSIONURLPROTOCOL";
@interface FHSessionURLProtocol ()<NSURLSessionTaskDelegate>
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation FHSessionURLProtocol

+ (void)regist {
    if (![FHSessionConfiguration shareInstance].status) {
        [[FHSessionConfiguration shareInstance] exchange];
    }
    
    [NSURLProtocol registerClass:[self class]];
}

+ (void)unRegist {
    if ([FHSessionConfiguration shareInstance].status) {
        [[FHSessionConfiguration shareInstance] unExchange];
    }
    
    [NSURLProtocol unregisterClass:[self class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:FHSESSIONURLPROTOCOL inRequest:request]) {
        return NO;
    }
    
    NSString *scheme = request.URL.scheme;
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
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

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    NSMutableURLRequest *tableURLRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@(YES) forKey:FHSESSIONURLPROTOCOL inRequest:tableURLRequest];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfig.HTTPAdditionalHeaders = @{@"Proxy-Authorization": @"authHeader"};
    self.session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:tableURLRequest];
    [task resume];
}

- (void)stopLoading {
    [self.session invalidateAndCancel];
    _session = nil;
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];   
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    NSLog(@"aa");
}

@end


