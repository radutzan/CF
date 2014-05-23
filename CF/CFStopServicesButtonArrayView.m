//
//  CFStopServicesButtonArrayView.m
//  CF
//
//  Created by Radu Dutzan on 5/19/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFStopServicesButtonArrayView.h"

@implementation CFStopServicesButtonArrayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
        CGFloat colWidth = floor(self.bounds.size.width / 4);
        CGFloat rowHeight = 50.0;
        CGFloat originX = colWidth * modulus;
        CGFloat originY = rowHeight * row;
        
        NSString *serviceName = [obj objectForKey:@"name"];
        
        UIButton *serviceButton = [UIButton buttonWithType:UIButtonTypeSystem];
        serviceButton.frame = CGRectMake(originX, originY, colWidth, rowHeight);
        serviceButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:24.0];
        [serviceButton setTitle:serviceName forState:UIControlStateNormal];
        [serviceButton addTarget:self action:@selector(serviceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:serviceButton];
        
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
