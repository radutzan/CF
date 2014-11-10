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
#import "CFMapSearchSuggestionView.h"
#import <Mixpanel/Mixpanel.h>

#define VERTICAL_MARGIN 0.0
#define HORIZONTAL_MARGIN 0.0

@interface CFSearchController () <CFServiceRouteBarDelegate, CFSearchFieldDelegate, CFMapSearchSuggestionViewDelegate>

@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) CFSearchSuggestionsCard *searchSuggestionsCard;
@property (nonatomic, strong) CFServiceRouteBar *serviceSuggestionView;
@property (nonatomic, strong) CFMapSearchSuggestionView *mapSearchSuggestionView;

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
        
        _serviceSuggestionView = [[CFServiceRouteBar alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERTICAL_MARGIN, frame.size.width - HORIZONTAL_MARGIN * 2, 44.0)];
        _serviceSuggestionView.delegate = self;
        _serviceSuggestionView.hidden = YES;
        _serviceSuggestionView.clipsToBounds = NO;
        _serviceSuggestionView.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:.96].CGColor;
        [_containerView addSubview:_serviceSuggestionView];
        
        _searchSuggestionsCard = [[CFSearchSuggestionsCard alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERTICAL_MARGIN, frame.size.width - HORIZONTAL_MARGIN * 2, 150.0)];
        _searchSuggestionsCard.clipsToBounds = NO;
        _searchSuggestionsCard.hidden = YES;
        [_containerView addSubview:_searchSuggestionsCard];
        
        _mapSearchSuggestionView = [[CFMapSearchSuggestionView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERTICAL_MARGIN, frame.size.width - HORIZONTAL_MARGIN * 2, 50.0)];
        _mapSearchSuggestionView.delegate = self;
        _mapSearchSuggestionView.hidden = YES;
        _mapSearchSuggestionView.clipsToBounds = NO;
        [_containerView addSubview:_mapSearchSuggestionView];
        
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
    
    if (self.suggestedStop && !(self.hidden || self.hiding)) [self showStopSuggestionWithStop:self.suggestedStop];
}

- (void)show
{
    self.alpha = 0;
    self.hidden = NO;
    
    if (!self.suggesting) self.currentCard = self.searchSuggestionsCard;
    if (self.suggestedStop) [self showStopSuggestionWithStop:self.suggestedStop];
    
    [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 1;
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

#pragma mark - Search string processing

- (void)processSearchString:(NSString *)searchString
{
    // servicio
    NSString *serviceRegex;
    
    if (searchString.length == 2) {
        serviceRegex = @"[A-J][1-9]";
        
    } else if (searchString.length == 3) {
        serviceRegex = @"([1-5]|[A-J])[0-4][0-9]";
        
    } else if (searchString.length == 4) {
        serviceRegex = @"([1-5]|[A-J])[0-4][0-9](C|E|N|V)";
        
    }
    
    BOOL possibleServiceMatch = NO;
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
            possibleServiceMatch = YES;
        } else {
            possibleServiceMatch = NO;
        }
    } else {
        possibleServiceMatch = NO;
    }
    
    if (!possibleServiceMatch) [self clearServiceSuggestions];
    
    // parada
    BOOL possibleStopMatch = NO;
    if (searchString.length >= 3 && searchString.length <= 6) {
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"P[A-J][0-9]{1,4}$" options:(NSRegularExpressionCaseInsensitive) error:NULL];
        
        NSTextCheckingResult *result = [expression firstMatchInString:searchString options:0 range:NSMakeRange(0, searchString.length)];
        
        if (result) {
            [self checkStop:searchString];
            possibleStopMatch = YES;
        } else {
            possibleStopMatch = NO;
        }
    } else {
        possibleStopMatch = NO;
    }
    
    if (!possibleStopMatch) [self clearStopSuggestions];
    
    // suggest map search
    BOOL possibleMatch = (possibleServiceMatch || possibleStopMatch);
    
    if (!possibleMatch && (!self.suggesting || !self.thinking) && ![searchString isEqualToString:@""]) {
        [self showMapSearchSuggestionWithString:searchString];
    }
    
    if ([searchString isEqualToString:@""]) self.suggesting = NO;
}

- (void)checkService:(NSString *)service
{
//    NSLog(@"checking possible service");
    self.thinking = YES;
    
    [[CFSapoClient sharedClient] serviceInfoForService:service handler:^(NSError *error, NSArray *result) {
        self.thinking = NO;
        
        if (result && [result lastObject]) {
//            NSLog(@"service exists: %@", result);
            self.suggesting = YES;
            
            NSDictionary *serviceInfo = [result firstObject];
            [self showServiceSuggestionWithService:[CFService serviceWithName:[serviceInfo objectForKey:@"servicio"] outwardDirectionName:[serviceInfo objectForKey:@"ida"] inwardDirectionName:[serviceInfo objectForKey:@"regreso"]]];
        }
        
        if (error || ![result lastObject]) {
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
            [self showStopSuggestionWithStop:stop];
            
        } else {
//            NSLog(@"not a stop");
            [self clearStopSuggestions];
        }
    }];
}

#pragma mark - Suggestions

- (void)setCurrentCard:(UIView *)currentCard
{
//    NSLog(@"setCurrentCard:");
    if ([currentCard isKindOfClass:[_currentCard class]]) return;
    
    CGFloat animationOffset = SEARCH_CARD_ANIMATION_OFFSET;
    
    UIView *oldCard = _currentCard;
    UIView *newCard = currentCard;
    BOOL hasOldCardButNoNewCard = (oldCard && !newCard);
    BOOL hasNewCardAndIsDifferentFromOldCard = (newCard && ![newCard isKindOfClass:[oldCard class]]);
    
//    if (hasOldCardButNoNewCard) NSLog(@"hasOldCardButNoNewCard");
//    if (hasNewCardAndIsDifferentFromOldCard) NSLog(@"hasNewCardAndIsDifferentFromOldCard");
//    NSLog(@"old: %@", oldCard);
//    NSLog(@"new: %@", newCard);
    
    if (hasOldCardButNoNewCard || hasNewCardAndIsDifferentFromOldCard) {
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            oldCard.frame = CGRectMake(0, -animationOffset, oldCard.bounds.size.width, oldCard.bounds.size.height);
            oldCard.alpha = 0;
        } completion:^(BOOL finished) {
            oldCard.frame = CGRectMake(0, 0, oldCard.bounds.size.width, oldCard.bounds.size.height);
            oldCard.hidden = YES;
        }];
    }
    
    if (hasNewCardAndIsDifferentFromOldCard) {
        newCard.frame = CGRectMake(0, -animationOffset, newCard.bounds.size.width, newCard.bounds.size.height);
        newCard.alpha = 0;
        newCard.hidden = NO;
        
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            newCard.alpha = 1;
            newCard.frame = CGRectMake(0, 0, newCard.bounds.size.width, newCard.bounds.size.height);
        } completion:^(BOOL finished) {
            newCard.hidden = NO;
        }];
    }
    
    _currentCard = currentCard;
}

- (void)setSuggesting:(BOOL)suggesting
{
    if (_suggesting == suggesting) return;
    _suggesting = suggesting;
    
    if (!suggesting) self.currentCard = self.searchSuggestionsCard;
}

- (void)setThinking:(BOOL)thinking
{
    _thinking = thinking;
    
    if (thinking) {
        [self.searchField.activityIndicator startAnimating];
        if (!self.suggestedStop) self.currentCard = nil;
    } else {
        [self.searchField.activityIndicator stopAnimating];
    }
}

- (void)showServiceSuggestionWithService:(CFService *)service
{
//    NSLog(@"showing service suggestion for service: %@", service);
    self.serviceSuggestionView.service = service;
    self.currentCard = self.serviceSuggestionView;
}

- (void)showStopSuggestionWithStop:(CFStop *)stop
{
//    NSLog(@"showing stop suggestion for stop: %@", stop);
    [self.delegate searchControllerNeedsStopCardForStop:stop];
    self.suggestedStop = stop;
    self.currentCard = nil;
}

- (void)showMapSearchSuggestionWithString:(NSString *)searchString
{
    self.suggesting = YES;
    self.mapSearchSuggestionView.searchText = searchString;
    self.currentCard = self.mapSearchSuggestionView;
}

- (void)clearServiceSuggestions
{
//    NSLog(@"clearing service suggestions");
    self.thinking = NO;
    if (!self.suggestedStop && [self.searchField.text isEqualToString:@""]) self.suggesting = NO;
}

- (void)clearStopSuggestions
{
//    NSLog(@"clearing stop suggestions");
    [self.delegate searchControllerDidClearStopSuggestions];
    self.suggestedStop = nil;
    self.thinking = NO;
    
    if ([self.searchField.text isEqualToString:@""]) self.suggesting = NO;
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
    
    if (self.suggestedStop) {
        [self.delegate searchControllerRequestedStop:self.suggestedStop];
        [searchField clear];
    } else if (self.currentCard == self.serviceSuggestionView) {
        [self.delegate searchControllerDidSelectService:self.serviceSuggestionView.service direction:CFDirectionOutward];
        [searchField clear];
    } else if (![searchField.text isEqualToString:@""]) {
        [self.delegate searchControllerRequestedLocalSearch:searchField.text];
    }
    
    [self hide];
}

- (void)searchFieldDidEndEditing:(CFSearchField *)searchField
{
    [self.delegate searchControllerDidEndSearching];
    
    searchField.frame = CGRectMake(searchField.frame.origin.x, searchField.frame.origin.y, searchField.superview.bounds.size.width - 70.0, searchField.bounds.size.height);
    
    if (!self.suggesting) {
        [self hide];
    }
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

- (void)mapSearchSuggestionViewTapped
{
    [self searchFieldSearchButtonClicked:self.searchField];
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
