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
@property (nonatomic, strong) UIButton *outwardButton;
@property (nonatomic, strong) UIButton *inwardButton;

@end

@implementation CFServiceRouteBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _serviceLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0, 80.0, frame.size.height)];
        _serviceLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:26.0];
        _serviceLabel.textColor = [UIColor colorWithWhite:0 alpha:.8];
        [self addSubview:_serviceLabel];
        
        CGFloat buttonWidth = floorf((self.frame.size.width - _serviceLabel.bounds.size.width - _serviceLabel.frame.origin.x) / 2);
        
        _outwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _outwardButton.frame = CGRectMake(_serviceLabel.frame.origin.x + _serviceLabel.bounds.size.width, 0, buttonWidth, frame.size.height);
        _outwardButton.titleLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:14.0];
        _outwardButton.titleLabel.numberOfLines = 2;
        _outwardButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, 10.0);
        _outwardButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_outwardButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_outwardButton];
        
        _inwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _inwardButton.frame = CGRectMake(_outwardButton.frame.origin.x + _outwardButton.bounds.size.width, 0, _outwardButton.bounds.size.width, frame.size.height);
        _inwardButton.titleLabel.font = _outwardButton.titleLabel.font;
        _inwardButton.titleLabel.numberOfLines = 0;
        _inwardButton.titleEdgeInsets = _outwardButton.titleEdgeInsets;
        _inwardButton.contentHorizontalAlignment = _outwardButton.contentHorizontalAlignment;
        [_inwardButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_inwardButton];
        
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
    self.serviceLabel.text = [service.name uppercaseString];
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
    [self.delegate serviceRouteBarSelectedButtonAtIndex:index service:self.service];
}

@end
