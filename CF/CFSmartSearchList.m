//
//  CFSmartSearchList.m
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFSmartSearchList.h"
#import "CFServiceSuggestionView.h"
#import "CFStopSuggestionView.h"

#define VERTICAL_MARGIN 20.0
#define HORIZONTAL_MARGIN 20.0

@interface CFSmartSearchList () <CFServiceSuggestionViewDelegate, CFStopSuggestionViewDelegate>

@property (nonatomic, strong) UIView *darkOverlay;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) CFServiceSuggestionView *serviceSuggestionView;
@property (nonatomic, strong) CFStopSuggestionView *stopSuggestionView;
@property (nonatomic, readwrite) BOOL suggesting;

@end

@implementation CFSmartSearchList

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = YES;
        
        _darkOverlay = [[UIView alloc] initWithFrame:self.bounds];
        _darkOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _darkOverlay.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
        [self addSubview:_darkOverlay];
        
        UITapGestureRecognizer *overlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        [_darkOverlay addGestureRecognizer:overlayTap];
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.clipsToBounds = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _scrollView.contentSize = self.bounds.size;
        _scrollView.alwaysBounceVertical = YES;
        [self addSubview:_scrollView];
        
        _serviceSuggestionView = [[CFServiceSuggestionView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERTICAL_MARGIN, frame.size.width - HORIZONTAL_MARGIN * 2, 52.0)];
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
        [_scrollView addSubview:_serviceSuggestionView];
        
        _stopSuggestionView = [[CFStopSuggestionView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERTICAL_MARGIN, frame.size.width - HORIZONTAL_MARGIN * 2, 52.0)];
        _stopSuggestionView.delegate = self;
        _stopSuggestionView.hidden = YES;
        [_scrollView addSubview:_stopSuggestionView];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.frame = CGRectOffset(_activityIndicator.frame, (frame.size.width - _activityIndicator.frame.size.width) / 2, VERTICAL_MARGIN);
        [_scrollView addSubview:_activityIndicator];
        
        _suggesting = NO;
    }
    return self;
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    self.scrollView.frame = CGRectMake(0, contentInset.top, self.bounds.size.width, self.bounds.size.height - contentInset.top - contentInset.bottom);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, contentInset.left, 0, contentInset.right);
}

- (void)show
{
    self.alpha = 0;
    self.hidden = NO;
    
    [UIView animateWithDuration:0.33 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 1;
    } completion:nil];
}

- (void)hide
{
    [self.superview endEditing:YES];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
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
    [self.activityIndicator startAnimating];
    
    [[CFSapoClient sharedClient] serviceInfoForService:service handler:^(NSError *error, NSArray *result) {
        [self.activityIndicator stopAnimating];
        
        if (result && [result lastObject]) {
            // win
            NSLog(@"service exists: %@", result);
            self.suggesting = YES;
            
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
    [self.activityIndicator startAnimating];
    [self clearStopSuggestions];
    
    [[CFSapoClient sharedClient] fetchBusStop:stop handler:^(NSError *error, id result) {
        [self.activityIndicator stopAnimating];
        NSLog(@"result: %@", result);
        NSLog(@"error: %@", error);

        if (result) {
            NSLog(@"stop exists");
            self.suggesting = YES;
            
            NSDictionary *stopData = [result firstObject];
            CLLocationCoordinate2D coordinate;
            coordinate.latitude = [[stopData objectForKey:@"latitude"] doubleValue];
            coordinate.longitude = [[stopData objectForKey:@"longitude"] doubleValue];

            CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[stopData objectForKey:@"codigo"] name:[stopData objectForKey:@"nombre"] services:[stopData objectForKey:@"recorridos"]];
            self.stopSuggestionView.stop = stop;
            self.stopSuggestionView.hidden = NO;
            
            self.scrollView.contentSize = CGSizeMake(self.bounds.size.width, self.stopSuggestionView.bounds.size.height + VERTICAL_MARGIN * 2);
        } else {
            NSLog(@"not a stop");
            [self clearStopSuggestions];
        }
    }];
}

- (void)clearServiceSuggestions
{
    self.suggesting = NO;
    NSLog(@"clearing service suggestions");
    self.scrollView.contentSize = self.bounds.size;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.serviceSuggestionView.alpha = 0;
    } completion:^(BOOL finished) {
        self.serviceSuggestionView.hidden = YES;
        self.serviceSuggestionView.alpha = 1;
    }];
}

- (void)clearStopSuggestions
{
    self.suggesting = NO;
    NSLog(@"clearing stop suggestions");
    self.scrollView.contentSize = self.bounds.size;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.stopSuggestionView.alpha = 0;
    } completion:^(BOOL finished) {
        self.stopSuggestionView.hidden = YES;
        self.stopSuggestionView.alpha = 1;
    }];
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

- (void)stopSuggestionViewDidSelectStop:(NSString *)stop
{
    [self.delegate smartSearchListDidSelectStop:stop];
}

- (void)stopSuggestionViewDidSelectService:(NSString *)service directionString:(NSString *)directionString
{
    [self.delegate smartSearchListDidSelectService:service directionString:directionString];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    if ([hitView isEqual:self] || [hitView isEqual:self.scrollView]) {
        return self.darkOverlay;
    }
    
    return hitView;
}

@end
