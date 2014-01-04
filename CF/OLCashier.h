//
//  OLCashier.h
//  CashierDemo
//
//  Created by Diego Torres on 5/27/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol OLRemoteCashier;

typedef void (^OLCashierTransactionHandler)(NSError *error, NSArray *transactions, NSDictionary *userInfo);
typedef void (^OLCashierProductFetchingHandler)(NSError *error, NSArray *products, NSArray *invalidIdentifiers);

@interface OLCashier : NSObject

@property (nonatomic, readonly) NSSet *products;
@property (nonatomic, assign) id <OLRemoteCashier> remoteCashier;
@property (nonatomic, assign) OLCashierTransactionHandler defaultTransactionHandler;
@property (nonatomic, readonly, getter = isRestoringCompletedTransactions) BOOL restoringCompletedTransactions;

+ (instancetype)defaultCashier;

- (void)setProductsWithIdentifiers:(NSSet *)identifiers
                           handler:(OLCashierProductFetchingHandler)handler;

- (void)setProductsWithRemoteIdentifiers:(OLCashierProductFetchingHandler)handler;
/**
 @note Is responsability of the handler to finish the transaction
 */
- (void)buyProduct:(id)productOrIdentifier handler:(OLCashierTransactionHandler)handler;
- (void)buyProducts:(NSSet *)productsOrIdentifiers handler:(OLCashierTransactionHandler)handler __attribute__((unavailable));
- (void)restoreCompletedTransactions:(OLCashierTransactionHandler)handler;

+ (BOOL)hasProduct:(id)productOrIdentifier;

@end

@interface NSSet (OLCashierAdditions)

- (SKProduct *)productForIdentifier:(NSString *)productIdentifier;

@end

@interface SKPaymentTransaction (OLCashierAdditions)

- (void)finish;

@end

@protocol OLRemoteCashier <NSObject>
@optional
- (void)fetchProductIdentifiers:(void(^)(NSError *error, NSSet *identifiers))identifiersHandler;
- (void)verifyTransactionReceipt:(NSData *)receiptData response:(void (^)(NSError *error))validReceiptBlock;
- (void)activateProductInTransaction:(SKPaymentTransaction *)transaction response:(void (^)(NSError *error, NSDictionary *userInfo))successfulActivationBlock;

@end