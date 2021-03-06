//
//  CFClipView.h
//  CF
//
//  Created by Radu Dutzan on 1/3/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFForwardingTouchScrollView.h"

@interface CFClipView : UIView

@property (nonatomic, strong) CFForwardingTouchScrollView *scrollView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end
