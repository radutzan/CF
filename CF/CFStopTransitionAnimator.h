//
//  CFStopTransitionAnimator.h
//  CF
//
//  Created by Radu Dutzan on 7/17/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CFStopTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL presenting;
@property (nonatomic, assign) CGRect originRect;
@property (nonatomic, assign) CGFloat initialVelocity;

@end
