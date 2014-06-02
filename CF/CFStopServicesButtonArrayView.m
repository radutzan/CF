//
//  CFStopServicesButtonArrayView.m
//  CF
//
//  Created by Radu Dutzan on 5/19/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFStopServicesButtonArrayView.h"

#define DIVIDER_BACKGROUND_COLOR [UIColor colorWithWhite:1 alpha:.3]
#define ROW_HEIGHT 50.0
#define COLUMN_WIDTH floor(self.bounds.size.width / 4)

@interface CFStopServicesButtonArrayView ()

@property (nonatomic, assign) NSUInteger rows;

@end

@implementation CFStopServicesButtonArrayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CALayer *horizontalDivider1 = [CALayer layer];
        horizontalDivider1.frame = CGRectMake(0, 0, frame.size.width, 0.5);
        horizontalDivider1.backgroundColor = DIVIDER_BACKGROUND_COLOR.CGColor;
        [self.layer addSublayer:horizontalDivider1];
    }
    return self;
}

- (void)setServices:(NSArray *)services
{
    _services = services;
    
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    [services enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger row = floor(idx / 4);
        CGFloat modulus = idx % 4;
        CGFloat colWidth = COLUMN_WIDTH;
        CGFloat rowHeight = ROW_HEIGHT;
        CGFloat originX = colWidth * modulus;
        CGFloat originY = rowHeight * row;
        
        NSString *serviceName = [obj objectForKey:@"name"];
        
        UIButton *serviceButton = [UIButton buttonWithType:UIButtonTypeSystem];
        serviceButton.frame = CGRectMake(originX, originY, colWidth, rowHeight);
        serviceButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:24.0];
        serviceButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, 10.0);
        serviceButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        serviceButton.tintColor = [UIColor whiteColor];
        [serviceButton setTitle:serviceName forState:UIControlStateNormal];
        [serviceButton addTarget:self action:@selector(serviceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:serviceButton];
        self.rows = row + 1;
        
        if ([obj isEqual:[services lastObject]]) {
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.bounds.size.width, rowHeight * (row + 1));
        }
    }];
}

- (void)serviceButtonTapped:(UIButton *)sender
{
    [self.delegate servicesButtonArrayViewDidSelectService:[sender titleForState:UIControlStateNormal]];
}

@end
