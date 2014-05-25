//
//  CFForwardingTouchScrollView.m
//  CF
//
//  Created by Radu Dutzan on 5/25/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFForwardingTouchScrollView.h"

@implementation CFForwardingTouchScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.dragging)
        [self.superview touchesCancelled: touches withEvent:event];
    else
        [super touchesCancelled: touches withEvent: event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.dragging)
        [self.superview touchesMoved: touches withEvent:event];
    else
        [super touchesMoved: touches withEvent: event];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.dragging)
        [self.superview touchesBegan: touches withEvent:event];
    else
        [super touchesBegan: touches withEvent: event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.dragging)
        [self.superview touchesEnded: touches withEvent:event];
    else
        [super touchesEnded: touches withEvent: event];
}

@end
