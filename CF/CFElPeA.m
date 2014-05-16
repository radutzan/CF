//
//  CFElPeA.m
//  CF
//
//  Created by Radu Dutzan on 5/16/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFElPeA.h"

@implementation CFElPeA

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectOffset(bounds, 0, 2.0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectOffset(bounds, 0, 2.0);
}

@end
