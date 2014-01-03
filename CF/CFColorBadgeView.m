//
//  CFColorBadgeView.m
//  CF
//
//  Created by Radu Dutzan on 1/3/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFColorBadgeView.h"

@interface CFColorBadgeView ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation CFColorBadgeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.frame = self.bounds;
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 1);
        _gradientLayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor blackColor].CGColor];
        _gradientLayer.locations = @[@0.5, @0.5];
        [self.layer addSublayer:_gradientLayer];
    }
    return self;
}

- (void)setBadgeColor:(UIColor *)badgeColor
{
    _badgeColor = badgeColor;
    
    self.gradientLayer.colors = @[(id)badgeColor.CGColor, (id)[UIColor blackColor].CGColor];
}

@end
