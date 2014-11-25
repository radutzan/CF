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
    if (!self.placeholderTextColor) {
        [super drawPlaceholderInRect:rect];
        return;
    }
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName: self.placeholderTextColor, NSFontAttributeName: self.font};
    CGRect boundingRect = [self.placeholder boundingRectWithSize:rect.size options:0 attributes:attributes context:nil];
    [self.placeholder drawAtPoint:CGPointMake(0, (rect.size.height / 2) - boundingRect.size.height / 2) withAttributes:attributes];
}

@end
