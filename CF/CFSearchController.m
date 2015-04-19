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
#import "CFSearchOptionBar.h"
#import <Mixpanel/Mixpanel.h>

// need a different class name for each card or everything goes to shit
@interface CFPlaceSearchOptionsCard : UIView
@end
@implementation CFPlaceSearchOptionsCard
@end

#define VERTICAL_MARGIN 10.0
#define HORIZONTAL_MARGIN 10.0
#define CORNER_RADIUS 6.0

@interface CFSearchController () <CFServiceRouteBarDelegate, CFSearchFieldDelegate, CFSearchOptionBarDelegate>

@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) CFSearchSuggestionsCard *searchSuggestionsCard;
@property (nonatomic, strong) CFServiceRouteBar *serviceSuggestionView;
@property (nonatomic, strong) CFPlaceSearchOptionsCard *placeSearchOptionsCard;
@property (nonatomic, strong) CFSearchOptionBar *searchInMapOptionBar;
@property (nonatomic, strong) CFSearchOptionBar *getDirectionsOptionBar;

@property (nonatomic, strong) UIView *currentCard;
@property (nonatomic, strong) UIView *currentCardBeforeHiding;
@property (nonatomic, assign) BOOL hiding;
@property (nonatomic, assign) BOOL thinking;
@property (nonatomic, readwrite) BOOL suggesting;
@property (nonatomic, readwrite) CFStop *suggestedStop;

@end

@implementation CFSearchController

NSString *const kSearchInMapOptionIdentifier = @"searchInMap";
NSString *const kGetDirectionsOptionIdentifier = @"getDirections";

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = YES;
        self.alpha = 0;
        
        _overlay = [[UIView alloc] initWithFrame:self.bounds];
        _overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _overlay.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
        [self addSubview:_overlay];
        
        UITapGestureRecognizer *overlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        [_overlay addGestureRecognizer:overlayTap];
        
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, VERTICAL_MARGIN, frame.size.width - HORIZONTAL_MARGIN * 2, frame.size.height - VERTICAL_MARGIN)];
        [self addSubview:_containerView];
        
        _searchSuggestionsCard = [[CFSearchSuggestionsCard alloc] initWithFrame:CGRectMake(0, 0, _containerView.bounds.size.width, 150.0)];
        _searchSuggestionsCard.clipsToBounds = NO;
        _searchSuggestionsCard.hidden = YES;
        _searchSuggestionsCard.alpha = 0;
        [_containerView addSubview:_searchSuggestionsCard];
        
        _serviceSuggestionView = [[CFServiceRouteBar alloc] initWithFrame:CGRectMake(0, 0, _containerView.bounds.size.width, 44.0)];
        _serviceSuggestionView.delegate = self;
        _serviceSuggestionView.hidden = YES;
        _serviceSuggestionView.clipsToBounds = NO;
        _serviceSuggestionView.backgroundColor = [UIColor colorWithWhite:1 alpha:.97];
        [_containerView addSubview:_serviceSuggestionView];
        
        _placeSearchOptionsCard = [[CFPlaceSearchOptionsCard alloc] initWithFrame:CGRectMake(0, 0, _containerView.bounds.size.width, 88.0)];
        _placeSearchOptionsCard.hidden = YES;
        _placeSearchOptionsCard.layer.masksToBounds = YES;
        _placeSearchOptionsCard.layer.cornerRadius = CORNER_RADIUS;
        [_containerView addSubview:_placeSearchOptionsCard];
        
        _searchInMapOptionBar = [[CFSearchOptionBar alloc] initWithFrame:CGRectMake(0, 0, _placeSearchOptionsCard.frame.size.width, 44.0)];
        _searchInMapOptionBar.delegate = self;
        _searchInMapOptionBar.identifier = kSearchInMapOptionIdentifier;
        _searchInMapOptionBar.optionTitle = NSLocalizedString(@"MAP_SEARCH_SUGGESTION_CARD_TEXT", nil);
        _searchInMapOptionBar.optionImage = [UIImage imageNamed:@"search"];
        [_placeSearchOptionsCard addSubview:_searchInMapOptionBar];
        
        _getDirectionsOptionBar = [[CFSearchOptionBar alloc] initWithFrame:CGRectMake(0, _searchInMapOptionBar.bounds.size.height, _placeSearchOptionsCard.frame.size.width, _searchInMapOptionBar.bounds.size.height)];
        _getDirectionsOptionBar.delegate = self;
        _getDirectionsOptionBar.identifier = kGetDirectionsOptionIdentifier;
        _getDirectionsOptionBar.optionTitle = NSLocalizedString(@"GET_DIRECTIONS_TO_HERE", nil);
        _getDirectionsOptionBar.optionImage = [UIImage imageNamed:@"directions"];
        [_placeSearchOptionsCard addSubview:_getDirectionsOptionBar];
        
        _suggesting = NO;
    }
    return self;
}

#pragma mark - View handling

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    if (UIEdgeInsetsEqualToEdgeInsets(_contentInset, contentInset)) return;
    _contentInset = contentInset;
    self.containerView.frame = CGRectMake(HORIZONTAL_MARGIN, contentInset.top + VERTICAL_MARGIN, self.bounds.size.width - HORIZONTAL_MARGIN * 2, self.bounds.size.height - contentInset.top - contentInset.bottom - VERTICAL_MARGIN);
    
    if (self.suggestedStop && !(self.hidden || self.hiding)) [self showStopSuggestionWithStop:self.suggestedStop];
}

- (void)show
{
    self.alpha = 0;
    self.hidden = NO;
    
    if (!self.suggesting) self.currentCard = self.searchSuggestionsCard;
    if (self.suggesting && !self.suggestedStop) self.currentCard = self.currentCardBeforeHiding;
    if (self.suggestedStop) [self showStopSuggestionWithStop:self.suggestedStop];
    
    [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
    }];
}

- (void)hide
{
    if (self.hiding) return;
    self.hiding = YES;
    self.hidden = NO;
    [self.delegate searchControllerWillHide];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
        if (self.searchField.editing) [self.searchField endEditing:YES];
    } completion:^(BOOL finished) {
        self.hiding = NO;
        self.hidden = YES;
        self.currentCardBeforeHiding = self.currentCard;
        self.currentCard = nil;
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
    
    // servicio
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
    
    if (!possibleStopMatch && !possibleServiceMatch) [self clearStopSuggestions];
    
    // not suggesting shit
    if (searchString.length <= 2 || [searchString isEqualToString:@""]) {
        self.suggesting = NO;
        return;
    }
    
    BOOL possibleMatch = (possibleServiceMatch || possibleStopMatch);
    
    // suggest map search
    if (!possibleMatch && (!self.suggesting || !self.thinking) && ![searchString isEqualToString:@""]) {
        [self showMapSearchSuggestionWithString:searchString];
    }
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
            NSLog(@"stop result: %@", result);
            
            NSDictionary *stopData = [result firstObject];
            
            if (!stopData) {
                [self clearStopSuggestions];
                return;
            }
            
            self.suggesting = YES;
            
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
//    NSLog(@"setCurrentCard:%@", [currentCard class]);
    if ([currentCard isKindOfClass:[_currentCard class]]) return;
//    NSLog(@"setCurrentCard:%@ — passed", [currentCard class]);
    
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
        // hide old card
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            oldCard.frame = CGRectMake(0, -animationOffset, oldCard.bounds.size.width, oldCard.bounds.size.height);
            oldCard.alpha = 0;
        } completion:^(BOOL finished) {
            oldCard.frame = CGRectMake(0, 0, oldCard.bounds.size.width, oldCard.bounds.size.height);
            oldCard.hidden = YES;
        }];
    }
    
    if (hasNewCardAndIsDifferentFromOldCard) {
        // show new card
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
    NSLog(@"suggesting: %d", suggesting);
    if (!suggesting) self.currentCard = self.searchSuggestionsCard;
}

- (void)setThinking:(BOOL)thinking
{
    _thinking = thinking;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = thinking;
    
    if (thinking) {
        [self.searchField.activityIndicator startAnimating];
//        if (!self.suggestedStop) self.currentCard = nil;
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
    self.currentCard = self.placeSearchOptionsCard;
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
    
    [UIView animateWithDuration:.2 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{
        searchField.frame = CGRectMake(searchField.frame.origin.x, searchField.frame.origin.y, searchField.superview.bounds.size.width - 90.0, searchField.bounds.size.height);
    } completion:nil];
    
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
    [self hide];
    [self.searchField performSelector:@selector(clear) withObject:nil afterDelay:0.25];
}

- (void)searchOptionBarTapped:(CFSearchOptionBar *)optionBar
{
    if ([optionBar.identifier isEqualToString:kSearchInMapOptionIdentifier]) {
        [self searchFieldSearchButtonClicked:self.searchField];
    }
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
