//
//  OLCashier.m
//  CashierDemo
//
//  Created by Diego Torres on 5/27/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "OLCashier.h"
#import "OLProductRequestDelegate.h"
#import "OLPaymentQueueDispatchObserver.h"

@interface OLCashier () {
    NSMutableSet * products_;
}

@property (nonatomic, readwrite, getter = isRestoringCompletedTransactions) BOOL restoringCompletedTransactions;

@end

@implementation OLCashier

static NSMutableSet *verifiedPurchasedProducts;

static dispatch_once_t onceCashierToken;
static OLCashier *_defaultCashier;

+ (void)load
{
    verifiedPurchasedProducts = [NSMutableSet new];
}

+ (instancetype)defaultCashier
{
    dispatch_once(&onceCashierToken, ^{
        _defaultCashier = [[self alloc] init];
    });
    return _defaultCashier;
}

- (id)init
{
    self = [super init];
    if (self) {
        products_ = [NSMutableSet new];
    }
    return self;
}

- (void)setProductsWithIdentifiers:(NSSet *)identifiers handler:(OLCashierProductFetchingHandler)handler
{
    NSMutableArray *currentProducts = [[products_ allObjects] mutableCopy];
    NSMutableSet *identifiersToRequest = [identifiers mutableCopy];
    
    for (SKProduct *product in currentProducts) {
        if ([identifiersToRequest containsObject:product.productIdentifier]) {
            [identifiersToRequest removeObject:product.productIdentifier];
        } else {
            [products_ removeObject:product];
        }
    }
    
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiersToRequest];
    [OLProductRequestDelegate setupDelegateForRequest:request handler:^(NSError *error, NSArray *products, NSArray *invalidIdentifiers) {
        [products_ addObjectsFromArray:products];
        if (handler) {
            handler(error, products, invalidIdentifiers);
        }
    }];
    [request start];
}

-  (void)setProductsWithRemoteIdentifiers:(OLCashierProductFetchingHandler)handler
{
    if (!self.remoteCashier || ![self.remoteCashier respondsToSelector:@selector(fetchProductIdentifiers:)]) {
        NSError *error = [NSError errorWithDomain:@"OLCashierErrorDomain" code:0 userInfo:nil];
        return handler(error, nil, nil);
    }
    [self.remoteCashier fetchProductIdentifiers:^(NSError *error, NSSet *identifiers) {
        if (error) {
            return handler(error, nil, nil);
        }
        [self setProductsWithIdentifiers:identifiers handler:handler];
    }];
}

- (OLCashierTransactionHandler)remoteTransactionActivationHandlerWithHandler:(OLCashierTransactionHandler)handler
{
    OLCashierTransactionHandler aHandler = nil;
    if ([self.remoteCashier respondsToSelector:@selector(activateProductInTransaction:response:)]) {
        aHandler = ^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
            if (error) {
                return handler(error, transactions, userInfo);
            }
            [self.remoteCashier activateProductInTransaction:[transactions lastObject] response:^(NSError *error, NSDictionary *userInfo) {
                handler(error, transactions, userInfo);
            }];
        };
    } else {
        aHandler = handler;
    }
    return aHandler;
}

- (void)setDefaultTransactionHandler:(OLCashierTransactionHandler)defaultTransactionHandler
{
    if (self != _defaultCashier) {
        NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:@"defaultTransactionHandler is only available in the defaultCashier" userInfo:nil];
        [exception raise];
    }
    OLCashierTransactionHandler aHandler = [self remoteTransactionActivationHandlerWithHandler:defaultTransactionHandler];
    [OLPaymentQueueDispatchObserver setDefaultTransactionHandler:aHandler];
}

- (void)removeAllProducts
{
    [products_ removeAllObjects];
}

- (void)removeProducts:(NSSet *)objects
{
    [products_ minusSet:objects];
}

- (void)removeProduct:(SKProduct *)product
{
    [products_ removeObject:product];
}

- (NSSet *)products
{
    return [products_ copy];
}

- (void)buyProduct:(id)productOrIdentifier handler:(OLCashierTransactionHandler)handler
{
    if (![SKPaymentQueue canMakePayments]) {
        NSError *error = [NSError errorWithDomain:@"OLCashierErrorDomain" code:3 userInfo:nil];
        handler(error, nil, nil);
    }
    SKProduct *product = nil;
    if ([productOrIdentifier isKindOfClass:[NSString class]]) {
        product = [products_ productForIdentifier:productOrIdentifier];
        if (product == nil) {
            NSError *error = [NSError errorWithDomain:@"OLCashierErrorDomain" code:1 userInfo:nil];
            return handler(error, nil, nil);
        }
    } else if ([productOrIdentifier isKindOfClass:[SKProduct class]]) {
        product = productOrIdentifier;
    } else {
        NSError *error = [NSError errorWithDomain:@"OLCashierErrorDomain" code:2 userInfo:nil];
        return handler(error, nil, nil);
    }
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    OLCashierTransactionHandler aHandler = [self remoteTransactionActivationHandlerWithHandler:handler];
    
    [OLPaymentQueueDispatchObserver observePayment:payment handler:aHandler];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restoreCompletedTransactions:(OLCashierTransactionHandler)handler
{
    if (self != _defaultCashier) {
        NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:@"transaction restoration is only available in the defaultCashier" userInfo:nil];
        [exception raise];
    }
    OLCashierTransactionHandler aHandler = ^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
        self.restoringCompletedTransactions = NO;
        if (handler) {
            handler(error, transactions, userInfo);
        }
    };
    [OLPaymentQueueDispatchObserver observeTransactionRestoration:aHandler];
    if (![self isRestoringCompletedTransactions]) {
        self.restoringCompletedTransactions = YES;
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
}

#pragma mark - Product Querying

//Unsafe implementation.
//Is the same as an old product
+ (BOOL)hasProduct:(id)productOrIdentifier
{
    NSString *identifier = nil;
    if ([productOrIdentifier isKindOfClass:[SKProduct class]]) {
        identifier = [productOrIdentifier productIdentifier];
    } else if ([productOrIdentifier isKindOfClass:[NSString class]]) {
        identifier = productOrIdentifier;
    } else {
        return NO;
    }
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:identifier];
}

@end

@implementation SKPaymentTransaction (OLCashierAdditions)

- (void)finish
{
    [[SKPaymentQueue defaultQueue] finishTransaction:self];
}

@end

@implementation NSSet (OLCashierAdditions)

- (SKProduct *)productForIdentifier:(NSString *)productIdentifier
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"productIdentifier = %@", productIdentifier];
    NSSet *filteredSet = [self filteredSetUsingPredicate:predicate];
    return [filteredSet anyObject];
}

@end
