//
//  CFStopSignView.h
//  CuantoFaltaiOS
//
//  Created by Radu Dutzan on 2/12/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFStop.h"

@interface CFStopSignView : UIView

@property (nonatomic, strong) CFStop *stop;
@property (nonatomic, strong) UILabel *stopCodeLabel;
@property (nonatomic, strong) UIView *accessoryView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *favoriteContentView;

// favorite view
@property (nonatomic, strong) UITextField *favoriteNameField;

@end
