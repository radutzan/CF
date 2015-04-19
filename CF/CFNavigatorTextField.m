//
//  CFNavigatorTextField.m
//  CF
//
//  Created by Radu Dutzan on 4/19/15.
//  Copyright (c) 2015 Onda. All rights reserved.
//

#import "CFNavigatorTextField.h"

@implementation CFNavigatorTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:15];
        self.layer.backgroundColor = [UIColor colorWithWhite:0 alpha:.04].CGColor;
        self.layer.cornerRadius = 6.0;
        self.layer.borderColor = [UIColor colorWithWhite:0 alpha:.1].CGColor;
        self.layer.borderWidth = 0.5;
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return [self rectForBounds:bounds];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self rectForBounds:bounds];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return [self rectForBounds:bounds];
}

- (CGRect)rectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 10, 0);
}

@end
