//
//  OLTextField.m
//  MMTmini
//
//  Created by Radu Dutzan on 8/13/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "OLTextField.h"

@implementation OLTextField

- (void)drawPlaceholderInRect:(CGRect)rect
{
    if (self.placeholderTextColor) {
        [self.placeholderTextColor setFill];
    } else {
        [super drawPlaceholderInRect:rect];
        return;
    }
    
    [[self placeholder] drawInRect:rect withAttributes:@{NSFontAttributeName: self.font, NSForegroundColorAttributeName: self.placeholderTextColor}];
}

@end
