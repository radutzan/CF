//
//  CFBackgroundlessSystemButton.m
//  CF
//
//  Created by Radu Dutzan on 1/5/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFBackgroundlessSystemButton.h"

@implementation CFBackgroundlessSystemButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected) [self performSelector:@selector(killBackground) withObject:nil afterDelay:0.01];
}

- (void)killBackground
{
    if (self.selected) {
        BOOL didKillImageView = NO;
        for (UIView *view in self.subviews) {
            if ([view isKindOfClass:[UIImageView class]] && !didKillImageView) {
                view.hidden = YES;
                didKillImageView = YES;
            }
        }
    }
}

@end
