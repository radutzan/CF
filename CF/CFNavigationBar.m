//
//  CFNavigationBar.m
//  CF
//
//  Created by Radu Dutzan on 12/8/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFNavigationBar.h"

@implementation CFNavigationBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self.topItem.title isEqualToString:@"Stop Results"] || [self.topItem.title isEqualToString:@""]) {
        for (UIView *subview in self.subviews) {
//            NSLog(@"%@", subview);
            if ([subview isKindOfClass:NSClassFromString(@"_UINavigationBarBackIndicatorView")]) {
                CGPoint center = subview.center;
                center.y = 27.25f;
                subview.center = center;
            }
        }
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    if ([self.topItem.title isEqualToString:@"Stop Results"] || [self.topItem.title isEqualToString:@""]) {
        size.width = self.frame.size.width;
        size.height = 54.0;
        return size;
    } else {
        size.width = self.frame.size.width;
        size.height = 44.0;
        return size;
    }
    
    return [super sizeThatFits:size];
}

@end
