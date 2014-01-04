//
//  OLPaymentTransactionObserver.h
//  CashierDemo
//
//  Created by Diego Torres on 5/27/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void (^OLPaymentQueueHandler)(NSError *error, NSArray *transactions, NSDictionary *userInfo);

@interface OLPaymentQueueDispatchObserver : NSObject <SKPaymentTransactionObserver>

+ (void)observePayment:(SKPayment *)payment handler:(OLPaymentQueueHandler)handler;
+ (void)observeTransactionRestoration:(OLPaymentQueueHandler)handler;
+ (void)setDefaultTransactionHandler:(OLPaymentQueueHandler)handler;

@end
