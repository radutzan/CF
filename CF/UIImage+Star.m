//
//  UIImage+Star.m
//  CF
//
//  Created by Radu Dutzan on 9/16/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "UIImage+Star.h"

@implementation UIImage (CFStar)

+ (UIImage *)starImageWithSize:(CGSize)size filled:(BOOL)filled
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    UIBezierPath* starPath = UIBezierPath.bezierPath;
    [starPath moveToPoint: CGPointMake(15, 1)];
    [starPath addLineToPoint: CGPointMake(18.68, 10.94)];
    [starPath addLineToPoint: CGPointMake(29.27, 11.36)];
    [starPath addLineToPoint: CGPointMake(20.95, 17.93)];
    [starPath addLineToPoint: CGPointMake(23.82, 28.14)];
    [starPath addLineToPoint: CGPointMake(15, 22.25)];
    [starPath addLineToPoint: CGPointMake(6.18, 28.14)];
    [starPath addLineToPoint: CGPointMake(9.05, 17.93)];
    [starPath addLineToPoint: CGPointMake(0.73, 11.36)];
    [starPath addLineToPoint: CGPointMake(11.32, 10.94)];
    [starPath closePath];
    
    [starPath applyTransform:CGAffineTransformMakeScale(size.width / 30, size.height / 30)];
    
    if (filled) {
        [[UIColor blackColor] setFill];
        [starPath fill];
    } else {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(context, 2.0);
        
        CGPathRef path = starPath.CGPath;
        CGContextAddPath(context, path);
        CGContextClip(context);
        CGContextAddPath(context, path);
        CGContextDrawPath(context, kCGPathStroke);
    }
    
    UIImage *starImage = [UIGraphicsGetImageFromCurrentImageContext() imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    UIGraphicsEndImageContext();
    
    return starImage;
}

@end
