//
//  CFSmartSearchList.m
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFSearchController.h"
#import "CFSearchSuggestionsCard.h"
#import "CFServiceRouteBar.h"
#import <Mixpanel/Mixpanel.h>

#define VERTICAL_MARGIN 0.0
#define HORIZONTAL_MARGIN 0.0

@interface CFSearchController () <CFServiceRouteBarDelegate, CFSearchFieldDelegate>

@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) CFSearchSuggestionsCard *searchSuggestionsCard;
@property (nonatomic, strong) CFServiceRouteBar *serviceSuggestionView;

@property (nonatomic, strong) UIView *currentCard;
@property (nonatomic, assign) BOOL hiding;
@property (nonatomic, assign) BOOL thinking;
@property (nonatomic, readwrite) BOOL suggesting;
@property (nonatomic, readwrite) CFStop *suggestedStop;

@end

@implementation CFSearchController

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = YES;
        
        _overlay = [[UIView alloc] initWithFrame:self.bounds];
        _overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _overlay.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
        [self addSubview:_overlay];
        
        UITapGestureRecognizer *overlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        [_overlay addGestureRecognizer:overlayTap];
        
        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_containerView];
        
        _searchSuggestionsCard = [[CFSearchSuggestionsCard alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERTICAL_MARGIN, frame.size.width - HORIZONTAL_MARGIN * 2, 150.0)];
        _searchSuggestionsCard.clipsToBounds = NO;
        [_containerView addSubview:_searchSuggestionsCard];
        
        _serviceSuggestionView = [[CFServiceRouteBar alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERTICAL_MARGIN, frame.size.width - HORIZONTAL_MARGIN * 2, 44.0)];
        _serviceSuggestionView.delegate = self;
        _serviceSuggestionView.hidden = YES;
        _serviceSuggestionView.clipsToBounds = NO;
        _serviceSuggestionView.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:.96].CGColor;
        [_containerView addSubview:_serviceSuggestionView];
        
        _suggesting = NO;
    }
    return self;
}

#pragma mark - View handling

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    if (UIEdgeInsetsEqualToEdgeInsets(_contentInset, contentInset)) return;
    _contentInset = contentInset;
    self.containerView.frame = CGRectMake(0, contentInset.top, self.bounds.size.width, self.bounds.size.height - contentInset.top - contentInset.bottom);
    
    if (self.suggestedStop && !(self.hidden || self.hiding)) [self.delegate searchControllerNeedsStopCardForStop:self.suggestedStop];
}

- (void)show
{
    self.alpha = 0;
    self.hidden = NO;
    
    if (!self.suggesting) {
        self.searchSuggestionsCard.frame = CGRectMake(self.searchSuggestionsCard.frame.origin.x, - SEARCH_CARD_ANIMATION_OFFSET, self.searchSuggestionsCard.bounds.size.width, self.searchSuggestionsCard.bounds.size.height);
    }
    
    if (self.suggestedStop) [self.delegate searchControllerNeedsStopCardForStop:self.suggestedStop];
    
    [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 1;
        if (!self.suggesting) {
            self.searchSuggestionsCard.frame = CGRectMake(self.searchSuggestionsCard.frame.origin.x, 0, self.searchSuggestionsCard.bounds.size.width, self.searchSuggestionsCard.bounds.size.height);
        }
    } completion:^(BOOL finished) {
    }];
}

- (void)hide
{
    self.hiding = YES;
    self.hidden = NO;
    [self.delegate searchControllerWillHide];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
        if (self.searchField.editing) [self.searchField endEditing:YES];
    } completion:^(BOOL finished) {
        self.hiding = NO;
        self.hidden = YES;
    }];
}

- (void)setSuggesting:(BOOL)suggesting
{
    if (_suggesting == suggesting) return;
    
    _suggesting = suggesting;
    
    self.searchSuggestionsCard.hidden = suggesting;
    self.searchSuggestionsCard.alpha = suggesting;
    self.searchSuggestionsCard.frame = CGRectMake(self.searchSuggestionsCard.frame.origin.x, - (SEARCH_CARD_ANIMATION_OFFSET * (1 - suggesting)), self.searchSuggestionsCard.bounds.size.width, self.searchSuggestionsCard.bounds.size.height);
    
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.searchSuggestionsCard.alpha = 1 - suggesting;
        self.searchSuggestionsCard.frame = CGRectMake(self.searchSuggestionsCard.frame.origin.x, - (SEARCH_CARD_ANIMATION_OFFSET * suggesting), self.searchSuggestionsCard.bounds.size.width, self.searchSuggestionsCard.bounds.size.height);
    } completion:^(BOOL finished) {
        self.searchSuggestionsCard.hidden = suggesting;
    }];
}

- (void)setThinking:(BOOL)thinking
{
    _thinking = thinking;
    
    if (thinking) {
        [self.searchField.activityIndicator startAnimating];
    } else {
        [self.searchField.activityIndicator stopAnimating];
    }
}

- (void)setCurrentCard:(UIView *)currentCard
{
    CGFloat animationOffset = SEARCH_CARD_ANIMATION_OFFSET;
    
    if ((_currentCard && !currentCard)) {
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _currentCard.center = CGPointMake(_currentCard.center.x, _currentCard.center.y - animationOffset);
            _currentCard.alpha = 0;
        } completion:^(BOOL finished) {
            _currentCard.center = CGPointMake(_currentCard.center.x, _currentCard.center.y + animationOffset);
            _currentCard.hidden = YES;
            _currentCard.alpha = 1;
        }];
    }
    
    if (currentCard && ![currentCard isKindOfClass:[_currentCard class]]) {
        currentCard.frame = CGRectMake(0, -animationOffset, currentCard.bounds.size.width, currentCard.bounds.size.height);
        currentCard.alpha = 0;
        currentCard.hidden = NO;
        
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            currentCard.alpha = 1;
            currentCard.center = CGPointMake(currentCard.center.x, currentCard.center.y + animationOffset);
        } completion:^(BOOL finished) {
            currentCard.alpha = 1;
        }];
    }
    
    _currentCard = currentCard;
}

- (void)clearServiceSuggestions
{
//    NSLog(@"clearing service suggestions");
    if ([self.currentCard isKindOfClass:[self.serviceSuggestionView class]]) {
        self.currentCard = nil;
    }
    
    if (!self.suggestedStop) self.suggesting = NO;
}

- (void)clearStopSuggestions
{
//    NSLog(@"clearing stop suggestions");
    [self.delegate searchControllerDidClearStopSuggestions];
    self.suggesting = NO;
    self.suggestedStop = nil;
}

- (void)showServiceSuggestionWithService:(CFService *)service
{
//    NSLog(@"showing service suggestion for service: %@", service);
    self.serviceSuggestionView.service = service;
    self.currentCard = self.serviceSuggestionView;
}

#pragma mark - Search field

- (void)setSearchField:(CFSearchField *)searchField
{
    _searchField = searchField;
    _searchField.delegate = self;
}

- (void)searchFieldDidBeginEditing:(CFSearchField *)searchField
{
    [self show];
    searchField.frame = CGRectMake(searchField.frame.origin.x, searchField.frame.origin.y, searchField.superview.bounds.size.width - 16.0, searchField.bounds.size.height);
    [self.delegate searchControllerDidBeginSearching];
}

- (void)searchField:(CFSearchField *)searchField textDidChange:(NSString *)searchText
{
    [self processSearchString:searchText];
}

- (void)searchFieldSearchButtonClicked:(CFSearchField *)searchField
{
    [searchField endEditing:YES];
    [self.delegate searchControllerDidEndSearching];
    
    if (self.suggesting) return;
    
    [self hide];
    [self.delegate searchControllerRequestedLocalSearch:searchField.text];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Searched in Map" properties:nil];
}

- (void)searchFieldDidEndEditing:(CFSearchField *)searchField
{
    [self.delegate searchControllerDidEndSearching];
    
    searchField.frame = CGRectMake(searchField.frame.origin.x, searchField.frame.origin.y, searchField.superview.bounds.size.width - 70.0, searchField.bounds.size.height);
    
    if (!self.suggesting) {
        [self hide];
    }
}

#pragma mark - Search string processing

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
//            NSLog(@"possible service");
            NSString *serviceString = searchString;
            
            if (searchString.length == 2) {
//                NSLog(@"…which is shortened");
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
//    NSLog(@"checking possible service");
    self.thinking = YES;
    
    [[CFSapoClient sharedClient] serviceInfoForService:service handler:^(NSError *error, NSArray *result) {
        self.thinking = NO;
        
        if (result && [result lastObject]) {
            // win
//            NSLog(@"service exists: %@", result);
            self.suggesting = YES;
            
            NSDictionary *serviceInfo = [result firstObject];
            [self showServiceSuggestionWithService:[CFService serviceWithName:[serviceInfo objectForKey:@"servicio"] outwardDirectionName:[serviceInfo objectForKey:@"ida"] inwardDirectionName:[serviceInfo objectForKey:@"regreso"]]];
        }
        
        if (error || ![result lastObject]) {
            // quit
//            NSLog(@"not a service");
            [self clearServiceSuggestions];
        }
    }];
}

- (void)checkStop:(NSString *)stop
{
//    NSLog(@"checking possible stop code");
    self.thinking = YES;
    
    [[CFSapoClient sharedClient] fetchBusStop:stop handler:^(NSError *error, id result) {
        self.thinking = NO;

        if (result) {
//            NSLog(@"stop exists");
            self.suggesting = YES;
            
            NSDictionary *stopData = [result firstObject];
            CLLocationCoordinate2D coordinate;
            coordinate.latitude = [[stopData objectForKey:@"latitude"] doubleValue];
            coordinate.longitude = [[stopData objectForKey:@"longitude"] doubleValue];

            CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[stopData objectForKey:@"codigo"] name:[stopData objectForKey:@"nombre"] services:[stopData objectForKey:@"recorridos"]];
            [self.delegate searchControllerNeedsStopCardForStop:stop];
            self.suggestedStop = stop;
            
        } else {
//            NSLog(@"not a stop");
            [self clearStopSuggestions];
        }
    }];
}

#pragma mark - Delegates, etc

- (void)serviceRouteBar:(CFServiceRouteBar *)serviceRouteBar selectedButtonAtIndex:(NSUInteger)index service:(CFService *)service
{
    serviceRouteBar.selectedDirection = 3;
    CFDirection direction = (index == 0) ? CFDirectionOutward : CFDirectionInward;
    [self.delegate searchControllerDidSelectService:service direction:direction];
    [self.searchField clear];
    [self hide];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    if ([hitView isEqual:self] || [hitView isEqual:self.containerView]) {
        return self.overlay;
    }
    
    return hitView;
}

@end
