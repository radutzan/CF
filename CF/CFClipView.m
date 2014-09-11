//
//  CFClipView.m
//  CF
//
//  Created by Radu Dutzan on 1/3/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFClipView.h"

@implementation CFClipView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [CFForwardingTouchScrollView new];
        [self addSubview:_scrollView];
        
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.frame = self.bounds;
        _gradientLayer.colors = @[(id)[UIColor colorWithWhite:0 alpha:1].CGColor, (id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:1].CGColor];
        _gradientLayer.locations = @[@0, @0.1, @0.9, @1];
        _gradientLayer.startPoint = CGPointMake(0, 0.5);
        _gradientLayer.endPoint = CGPointMake(1.0, 0.5);
//        self.layer.mask = gradient;
        
        [self.layer insertSublayer:_gradientLayer above:_scrollView.layer];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([self pointInside:point withEvent:event]) {
        return self.scrollView;
    }
    return nil;
}

@end
