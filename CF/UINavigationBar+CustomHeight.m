//
//  UINavigationBar+CustomHeight.m
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "UINavigationBar+CustomHeight.h"

@implementation UINavigationBar (CustomHeight)

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = CGSizeMake(self.frame.size.width, 54.0);
    return newSize;
}

@end
