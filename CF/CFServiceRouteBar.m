//
//  CFServiceSuggestionView.m
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFServiceRouteBar.h"

@interface CFServiceRouteBar ()

@property (nonatomic, strong) UILabel *serviceLabel;
@property (nonatomic, strong) UITapGestureRecognizer *serviceTapRecognizer;
@property (nonatomic, strong) UIButton *outwardButton;
@property (nonatomic, strong) UIButton *inwardButton;
@property (nonatomic, strong) UIButton *dismissButton;

@end

@implementation CFServiceRouteBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _serviceLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0, 80.0, frame.size.height)];
        _serviceLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:22.0];
        _serviceLabel.textColor = [UIColor colorWithWhite:0 alpha:.8];
        _serviceLabel.userInteractionEnabled = YES;
        [self addSubview:_serviceLabel];
        
        UITapGestureRecognizer *serviceTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nameTapped)];
        [_serviceLabel addGestureRecognizer:serviceTapRecognizer];
        
        CGFloat buttonWidth = floorf((self.frame.size.width - _serviceLabel.bounds.size.width - _serviceLabel.frame.origin.x) / 2);
        
        _outwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _outwardButton.frame = CGRectMake(_serviceLabel.frame.origin.x + _serviceLabel.bounds.size.width, 0, buttonWidth, frame.size.height);
        _outwardButton.titleLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:14.0];
        _outwardButton.titleLabel.numberOfLines = 2;
        _outwardButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, 10.0);
        _outwardButton.clipsToBounds = YES;
        _outwardButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_outwardButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_outwardButton];
        
        _inwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _inwardButton.frame = CGRectMake(_outwardButton.frame.origin.x + _outwardButton.bounds.size.width, 0, _outwardButton.bounds.size.width, frame.size.height);
        _inwardButton.titleLabel.font = _outwardButton.titleLabel.font;
        _inwardButton.titleLabel.numberOfLines = 0;
        _inwardButton.titleEdgeInsets = _outwardButton.titleEdgeInsets;
        _inwardButton.clipsToBounds = YES;
        _inwardButton.contentHorizontalAlignment = _outwardButton.contentHorizontalAlignment;
        [_inwardButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_inwardButton];
        
        _dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _dismissButton.frame = CGRectMake(0, 0, 36.0, self.bounds.size.height);
        _dismissButton.center = CGPointMake(0, _serviceLabel.center.y);
        _dismissButton.alpha = 0;
        [_dismissButton setImage:[UIImage imageNamed:@"button-close"] forState:UIControlStateNormal];
        [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_dismissButton];
        
        CALayer *divider1 = [CALayer layer];
        divider1.frame = CGRectMake(_outwardButton.frame.origin.x, 0, 0.5, frame.size.height);
        divider1.backgroundColor = [UIColor blackColor].CGColor;
        divider1.opacity = 0.2;
        [self.layer addSublayer:divider1];
        
        CALayer *divider2 = [CALayer layer];
        divider2.frame = CGRectMake(_inwardButton.frame.origin.x, 0, divider1.frame.size.width, frame.size.height);
        divider2.backgroundColor = divider1.backgroundColor;
        divider2.opacity = divider1.opacity;
        [self.layer addSublayer:divider2];
    }
    return self;
}

- (void)setService:(CFService *)service
{
    _service = service;
    self.serviceLabel.text = service.name;
    self.outwardDirectionString = service.outwardDirectionName;
    self.inwardDirectionString = service.inwardDirectionName;
}

- (void)setOutwardDirectionString:(NSString *)outwardDirectionString
{
    [self.outwardButton setTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [outwardDirectionString capitalizedString]] forState:UIControlStateNormal];
}

- (void)setInwardDirectionString:(NSString *)inwardDirectionString
{
    [self.inwardButton setTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [inwardDirectionString capitalizedString]] forState:UIControlStateNormal];
}

- (void)buttonTapped:(UIButton *)button
{
    NSUInteger index = ([button isEqual:self.outwardButton]) ? 0 : 1;
    [self.delegate serviceRouteBar:self selectedButtonAtIndex:index service:self.service];
}

- (void)nameTapped
{
    [self.delegate serviceRouteBar:self selectedButtonAtIndex:0 service:self.service];
}

- (void)dismiss
{
    [self.delegate serviceRouteBarDidDismiss:self];
}

- (void)setSelectedDirection:(NSUInteger)selectedDirection
{
    _selectedDirection = selectedDirection;
    
    switch (selectedDirection) {
        case 0:
            self.outwardButton.backgroundColor = self.tintColor;
            self.outwardButton.selected = YES;
            self.inwardButton.backgroundColor = [UIColor clearColor];
            self.inwardButton.selected = NO;
            break;
            
        case 1:
            self.outwardButton.backgroundColor = [UIColor clearColor];
            self.outwardButton.selected = NO;
            self.inwardButton.backgroundColor = self.tintColor;
            self.inwardButton.selected = YES;
            break;
            
        default:
            self.outwardButton.selected = YES;
            self.outwardButton.backgroundColor = [UIColor clearColor];
            self.inwardButton.backgroundColor = [UIColor clearColor];
            self.inwardButton.selected = YES;
            break;
    }
}

- (void)setDismissible:(BOOL)dismissible
{
    if (_dismissible == dismissible) return;
    _dismissible = dismissible;
    
    CGPoint nameTargetCenter;
    CGPoint buttonTargetCenter;
    CGFloat buttonOffset = self.dismissButton.bounds.size.width / 2;
    CGFloat extraPadding = 6.0;
    
    if (dismissible) {
        nameTargetCenter = CGPointMake(self.serviceLabel.center.x + buttonOffset + extraPadding, self.serviceLabel.center.y);
        buttonTargetCenter = CGPointMake(buttonOffset, self.dismissButton.center.y);
    } else {
        nameTargetCenter = CGPointMake(self.serviceLabel.center.x - buttonOffset - extraPadding, self.serviceLabel.center.y);
        buttonTargetCenter = CGPointMake(0.0, self.dismissButton.center.y);
    }
    
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{
        self.serviceLabel.center = nameTargetCenter;
        self.dismissButton.center = buttonTargetCenter;
        self.dismissButton.alpha = dismissible;
    } completion:nil];
    
    self.serviceTapRecognizer.enabled = !dismissible;
}

@end
