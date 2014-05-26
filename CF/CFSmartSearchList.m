//
//  CFSmartSearchList.m
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFSmartSearchList.h"
#import "CFServiceSuggestionView.h"

@interface CFSmartSearchList () <CFServiceSuggestionViewDelegate>

@property (nonatomic, strong) CFServiceSuggestionView *serviceSuggestionView;

@end

@implementation CFSmartSearchList

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _serviceSuggestionView = [[CFServiceSuggestionView alloc] initWithFrame:CGRectMake(20.0, 20.0, frame.size.width - 40.0, 52.0)];
        _serviceSuggestionView.delegate = self;
        _serviceSuggestionView.hidden = YES;
        _serviceSuggestionView.clipsToBounds = NO;
        _serviceSuggestionView.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:.96].CGColor;
        _serviceSuggestionView.layer.cornerRadius = 5.0;
        _serviceSuggestionView.layer.shadowColor = [UIColor blackColor].CGColor;
        _serviceSuggestionView.layer.shadowOffset = CGSizeZero;
        _serviceSuggestionView.layer.shadowOpacity = 0.5;
        _serviceSuggestionView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_serviceSuggestionView.bounds cornerRadius:_serviceSuggestionView.layer.cornerRadius].CGPath;
        _serviceSuggestionView.layer.shadowRadius = 0.5;
        [self addSubview:_serviceSuggestionView];
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
            
            [self checkService:serviceString];
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
            NSDictionary *serviceInfo = [result firstObject];
            [self showServiceSuggestionWithService:[serviceInfo objectForKey:@"servicio"] outwardString:[serviceInfo objectForKey:@"ida"] inwardString:[serviceInfo objectForKey:@"regreso"]];
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
    [UIView animateWithDuration:0.1 animations:^{
        self.serviceSuggestionView.alpha = 0;
    } completion:^(BOOL finished) {
        self.serviceSuggestionView.hidden = YES;
        self.serviceSuggestionView.alpha = 1;
    }];
}

- (void)clearStopSuggestions
{
    NSLog(@"clearing stop suggestions");
}

- (void)showServiceSuggestionWithService:(NSString *)service outwardString:(NSString *)outwardString inwardString:(NSString *)inwardString
{
    NSLog(@"showing service suggestion for service: %@", service);
    self.serviceSuggestionView.service = service;
    self.serviceSuggestionView.outwardDirectionString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [outwardString capitalizedString]];
    self.serviceSuggestionView.inwardDirectionString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [inwardString capitalizedString]];
    self.serviceSuggestionView.hidden = NO;
}

- (void)serviceSuggestionViewDidSelectButtonAtIndex:(NSUInteger)index service:(NSString *)service
{
    CFDirection direction = (index == 0) ? CFDirectionOutward : CFDirectionInward;
    [self.delegate smartSearchListDidSelectService:service direction:direction];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    if (![self.subviews containsObject:hitView]) {
        return nil;
    }
    
    return hitView;
}

@end
