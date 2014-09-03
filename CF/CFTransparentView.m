//
//  CFTransparentView.m
//  CF
//
//  Created by Radu Dutzan on 9/3/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFTransparentView.h"

@implementation CFTransparentView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    id hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil;
    else return hitView;
}

@end
