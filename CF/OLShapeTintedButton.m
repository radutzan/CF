//
//  OLShapeTintedButton.m
//  CF
//
//  Created by Radu Dutzan on 2/1/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "OLShapeTintedButton.h"

@implementation OLShapeTintedButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(buttonLifted) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    }
    return self;
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    [super setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:state];
}

- (void)buttonPressed
{
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.25;
    }];
}

- (void)buttonLifted
{
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1;
    }];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.imageView.tintColor = self.tintColor;
}

@end
