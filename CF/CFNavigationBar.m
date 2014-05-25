//
//  CFNavigationBar.m
//  CF
//
//  Created by Radu Dutzan on 12/8/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFNavigationBar.h"

@interface CFNavigationBar ()

@property (nonatomic, assign) BOOL inStopResult;

@end

@implementation CFNavigationBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated
{
    [super pushNavigationItem:item animated:animated];
    
    NSLog(@"pushed: %@", item.title);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.inStopResult = [self.topItem.title isEqualToString:@"Stop Results"];
    CGFloat backButtonCenterY = (self.inStopResult) ? 27.25f : 22.25f;
    __block BOOL shitBeWeird = NO;
    
    UIView *backButton;
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UINavigationBarBackIndicatorView")]) {
            backButton = subview;
        }
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        CGFloat navBarHeight = (self.inStopResult) ? 54.0 : 44.0;
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, navBarHeight);
        
        CGPoint center = backButton.center;
        shitBeWeird = (backButton.center.y > 30.0);
        center.y = backButtonCenterY;
        if (!shitBeWeird) backButton.center = center;
    }];
    
    // don't animate if shit becomes weird
    if (shitBeWeird) backButton.center = CGPointMake(backButton.center.x, backButtonCenterY);
}

//- (CGSize)sizeThatFits:(CGSize)size
//{
//    if (self.inStopResult) {
//        size.width = self.frame.size.width;
//        size.height = 54.0;
//        NSLog(@"navbar size in stop");
//        return size;
//    } else {
//        size.width = self.frame.size.width;
//        size.height = 44.0;
//        NSLog(@"navbar size not in stop");
//        return size;
//    }
//    
//    NSLog(@"you should never see this nslog");
//    return [super sizeThatFits:size];
//}

@end
