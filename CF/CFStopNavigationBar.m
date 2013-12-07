//
//  CFStopNavigationBar.m
//  CF
//
//  Created by Radu Dutzan on 12/3/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFStopNavigationBar.h"

@implementation CFStopNavigationBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor purpleColor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    for (UIView *subview in self.subviews) {
        NSLog(@"%@", subview);
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
