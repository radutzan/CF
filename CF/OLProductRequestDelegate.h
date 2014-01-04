//
//  OLProductRequestDelegate.h
//  CashierDemo
//
//  Created by Diego Torres on 5/27/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface OLProductRequestDelegate : NSObject

+ (void)setupDelegateForRequest:(SKProductsRequest *)request handler:(void (^)(NSError *error, NSArray *products, NSArray *invalidIdentifiers))handler;

@end
