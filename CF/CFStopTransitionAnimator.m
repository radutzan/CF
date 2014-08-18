//
//  CFStopTransitionAnimator.m
//  CF
//
//  Created by Radu Dutzan on 7/17/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFStopTransitionAnimator.h"

@implementation CFStopTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.82f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *overlayView = [[UIView alloc] initWithFrame:fromViewController.view.bounds];
    overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:.5];
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        [fromViewController.view addSubview:overlayView];
        overlayView.alpha = 0;
        
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        
        toViewController.view.center = fromViewController.view.center;
        toViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:0 animations:^{
            fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            overlayView.alpha = 1;
            toViewController.view.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        toViewController.view.userInteractionEnabled = YES;
        
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            overlayView.alpha = 0;
            fromViewController.view.center = CGPointMake(fromViewController.view.center.x * 2, fromViewController.view.center.y);
        } completion:^(BOOL finished) {
            [overlayView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
