//
//  CFSmartSearchList.m
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFSmartSearchList.h"

@implementation CFSmartSearchList

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)processSearchString:(NSString *)searchString
{
    // servicio
    NSString *serviceRegex;
    
    if (searchString.length == 2) {
        serviceRegex = @"[A-J][1-9]";
        
    } else if (searchString.length == 3) {
        serviceRegex = @"([1-5]|[A-J])[0-4][1-9]";
        
    } else if (searchString.length == 4) {
        serviceRegex = @"([1-5]|[A-J])[0-4][1-9](C|E|N|V)";
        
    }
    
    if (searchString.length >= 2 && searchString.length <= 4) {
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:serviceRegex options:(NSRegularExpressionCaseInsensitive) error:NULL];
        
        NSTextCheckingResult *result = [expression firstMatchInString:searchString options:0 range:NSMakeRange(0, searchString.length)];
        
        if (result) {
            NSLog(@"possible service");
            NSString *serviceString = searchString;
            
            if (searchString.length == 2) {
                NSLog(@"…which is shortened");
                NSMutableString *expandedServiceName = [NSMutableString stringWithString:searchString];
                [expandedServiceName insertString:@"0" atIndex:1];
                serviceString = expandedServiceName;
            }
            
            [self checkService:searchString];
        } else {
            [self clearServiceSuggestions];
        }
    } else {
        [self clearServiceSuggestions];
    }
    
    // parada
    if (searchString.length >= 3 && searchString.length <= 6) {
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"P[A-J][0-9]{1,4}$" options:(NSRegularExpressionCaseInsensitive) error:NULL];
        
        NSTextCheckingResult *result = [expression firstMatchInString:searchString options:0 range:NSMakeRange(0, searchString.length)];
        
        if (result) {
            [self checkStop:searchString];
        } else {
            [self clearStopSuggestions];
        }
    } else {
        [self clearStopSuggestions];
    }
}

- (void)checkService:(NSString *)service
{
    NSLog(@"checking possible service");
    [[CFSapoClient sharedClient] serviceInfoForService:service handler:^(NSError *error, NSArray *result) {
        if (result && [result lastObject]) {
            // win
            NSLog(@"service exists: %@", result);
        }
        
        if (error || ![result lastObject]) {
            // quit
            NSLog(@"not a service");
            [self clearServiceSuggestions];
        }
    }];
}

- (void)checkStop:(NSString *)stop
{
    NSLog(@"checking possible stop code");
    // just a stub, this method will not ship in this version
}

- (void)clearServiceSuggestions
{
    NSLog(@"clearing service suggestions");
}

- (void)clearStopSuggestions
{
    NSLog(@"clearing stop suggestions");
}

@end
