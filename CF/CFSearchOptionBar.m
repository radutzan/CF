//
//  CFSearchOptionBar.m
//  CF
//
//  Created by Radu Dutzan on 4/1/15.
//  Copyright (c) 2015 Onda. All rights reserved.
//

#import "CFSearchOptionBar.h"
#define VERTICAL_MARGIN 10.0

@interface CFSearchOptionBar ()

@property (nonatomic, strong) UIImageView *optionImageView;
@property (nonatomic, strong) UILabel *optionTitleLabel;

@end

@implementation CFSearchOptionBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];

        UITapGestureRecognizer *barTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(barTapped)];
        [self addGestureRecognizer:barTap];
        
        _optionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(13.0, 0, 17.0, frame.size.height)];
        _optionImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_optionImageView];
        
        _optionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(35.0, VERTICAL_MARGIN, frame.size.width - 35.0 - 10.0, frame.size.height - VERTICAL_MARGIN * 2)];
        _optionTitleLabel.numberOfLines = 1;
        _optionTitleLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
        [self addSubview:_optionTitleLabel];
        
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectInset(self.bounds, -0.5, -0.5);
        borderLayer.borderWidth = 0.5;
        borderLayer.borderColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
        [self.layer addSublayer:borderLayer];
    }
    return self;
}

- (void)setOptionImage:(UIImage *)optionImage
{
    if ([_optionImage isEqual:optionImage]) return;
    _optionImage = optionImage;
    
    self.optionImageView.image = [optionImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)setOptionTitle:(NSString *)optionTitle
{
    if ([_optionTitle isEqualToString:optionTitle]) return;
    _optionTitle = optionTitle;
    
    self.optionTitleLabel.text = optionTitle;
}

- (void)barTapped
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchOptionBarTapped:)]) {
        [self.delegate searchOptionBarTapped:self];
    }
}

@end
