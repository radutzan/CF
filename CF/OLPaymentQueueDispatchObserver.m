//
//  OLPaymentQueueDispatchObserver.m
//  CashierDemo
//
//  Created by Diego Torres on 5/27/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "OLPaymentQueueDispatchObserver.h"

static NSString *OLTransactionRestorationKey = @"OLTransactionRestorationKey";

static inline NSString * OLPaymentKey(SKPayment *payment) {
    return [NSString stringWithFormat:@"%ld - %@", (long)payment.quantity, payment.productIdentifier];
}

@interface OLPaymentQueueDispatchObserver ()

@property (nonatomic, strong) NSMutableDictionary *transactionObservers;
@property (nonatomic, strong) NSMutableSet *restoredTransactions;
@property (nonatomic, copy) OLPaymentQueueHandler defaultTransactionHandler;

@end

@implementation OLPaymentQueueDispatchObserver

+ (instancetype)sharedObserver
{
    static dispatch_once_t onceToken;
    static OLPaymentQueueDispatchObserver *observer;
    dispatch_once(&onceToken, ^{
        observer = [[self alloc] initInternally];
    });
    return observer;
}

- (id)initInternally
{
    self = [super init];
    if (self) {
        self.transactionObservers = [NSMutableDictionary new];
        self.restoredTransactions = [NSMutableSet new];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"You can not initialize your own observer" userInfo:nil];
}

+ (void)observePayment:(SKPayment *)payment handler:(OLPaymentQueueHandler)handler
{
    NSString *paymentKey = OLPaymentKey(payment);
    NSMutableDictionary *observersSets = [[self sharedObserver] transactionObservers];
    NSMutableSet *paymentsSet = [observersSets objectForKey:paymentKey];
    if (!paymentsSet) {
        paymentsSet = [NSMutableSet new];
        [observersSets setObject:paymentsSet forKey:paymentKey];
    }
    [paymentsSet addObject:[handler copy]];
}

+ (void)observeTransactionRestoration:(OLPaymentQueueHandler)handler
{
    [[[self sharedObserver] transactionObservers] setObject:[handler copy] forKey:OLTransactionRestorationKey];
}

+ (void)setDefaultTransactionHandler:(OLPaymentQueueHandler)handler
{
    [[self sharedObserver] setDefaultTransactionHandler:handler];
}

- (OLPaymentQueueHandler)handlerForPayment:(SKPayment *)payment {
    NSString *key = OLPaymentKey(payment);
    OLPaymentQueueHandler handler = [[[self transactionObservers] objectForKey:key] anyObject];
    if (handler) {
        [[[self transactionObservers] objectForKey:key] removeObject:handler];
    }
    return handler;
}

#pragma mark - SKPaymentTransactionObserver

- (void)handleTransactionChange:(SKPaymentTransaction *)transaction error:(NSError *)error
{
    NSAssert(self.defaultTransactionHandler, @"You should really, really setup a defaultTransactionHandler");
    OLPaymentQueueHandler handler = [self handlerForPayment:transaction.payment];
    handler = handler ? : self.defaultTransactionHandler;
    if (handler == self.defaultTransactionHandler && error && [error.domain isEqualToString:SKErrorDomain]) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        return;
    }
    if (handler) {
        handler(error, @[transaction], nil);
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateFailed:
                [self handleTransactionChange:transaction error:transaction.error];
                break;
            case SKPaymentTransactionStateRestored: {
                [self.restoredTransactions addObject:transaction];
                break;
            }
            default:
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    OLPaymentQueueHandler handler = [[self transactionObservers] objectForKey:OLTransactionRestorationKey];
    [[self transactionObservers] removeObjectForKey:OLTransactionRestorationKey];
    [self.restoredTransactions removeAllObjects];
    handler(error, nil, nil);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    OLPaymentQueueHandler handler = [[self transactionObservers] objectForKey:OLTransactionRestorationKey];
    [[self transactionObservers] removeObjectForKey:OLTransactionRestorationKey];
    NSArray *transactions = [self.restoredTransactions allObjects];
    [self.restoredTransactions removeAllObjects];
    handler(nil, transactions, nil);
}

@end
