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
        _scrollView = [UIScrollView new];
        [self addSubview:_scrollView];
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = @[(id)[UIColor colorWithWhite:0 alpha:1].CGColor, (id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:1].CGColor];
        gradient.locations = @[@0, @0.1, @0.9, @1];
        gradient.startPoint = CGPointMake(0, 0.5);
        gradient.endPoint = CGPointMake(1.0, 0.5);
//        self.layer.mask = gradient;
        
        [self.layer insertSublayer:gradient above:_scrollView.layer];
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
