//
//  OLProductRequestDelegate.m
//  CashierDemo
//
//  Created by Diego Torres on 5/27/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "OLProductRequestDelegate.h"

@interface OLProductRequestDelegate () <SKProductsRequestDelegate>

@property (nonatomic, strong) void (^handler)(NSError *error, NSArray *products, NSArray *invalidIdentifiers);

@end

@implementation OLProductRequestDelegate

+ (NSMutableSet *)delegates
{
    static dispatch_once_t onceToken;
    static NSMutableSet *_delegates;
    dispatch_once(&onceToken, ^{
        _delegates = [NSMutableSet new];
    });
    return _delegates;
}

+ (void)setupDelegateForRequest:(SKProductsRequest *)request handler:(void (^)(NSError *error, NSArray *products, NSArray *invalidIdentifiers))handler
{
    OLProductRequestDelegate *delegate = [[OLProductRequestDelegate alloc] init];
    delegate.handler = [handler copy];
    
    request.delegate = delegate;
    [[self delegates] addObject:delegate];
}

- (void)processResponse:(SKProductsResponse *)response error:(NSError *)error
{
    self.handler(error, response.products, response.invalidProductIdentifiers);
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    [self processResponse:nil error:error];
    [[[self class] delegates] removeObject:self];
}

- (void)requestDidFinish:(SKRequest *)request
{
    [[[self class] delegates] removeObject:self];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    [self processResponse:response error:nil];
}

@end
