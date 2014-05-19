//
//  CustomPinAnnotationView.m
//  CF
//
//  Created by Radu Dutzan on 5/19/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CustomPinAnnotationView.h"

@implementation CustomPinAnnotationView

// See this for more information: https://github.com/nfarina/calloutview/pull/9
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *calloutMaybe = [self.calloutView hitTest:[self.calloutView convertPoint:point fromView:self] withEvent:event];
    return calloutMaybe ?: [super hitTest:point withEvent:event];
}

@end
