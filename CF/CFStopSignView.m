//
//  CFStopSignView.m
//  CuantoFaltaiOS
//
//  Created by Radu Dutzan on 2/12/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFStopSignView.h"

#import <QuartzCore/QuartzCore.h>

#define LABEL_HEIGHT 17.0f
#define LABEL_FONT_SIZE 15.0f
#define HORIZONTAL_MARGIN 9.0f

@interface CFStopSignView ()

@property (nonatomic) CGFloat verticallyCenteredLabelY;
@property (nonatomic) CGFloat horizontalMarginWithPictogram;
@property (nonatomic) CGFloat contentViewWidth;

// regular view
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *stopNameSingleLineLabel;
@property (nonatomic, strong) UILabel *stopNameTopLabel;
@property (nonatomic, strong) UILabel *stopNameBottomLabel;
@property (nonatomic, strong) UILabel *stopNumberLabel;
@property (nonatomic, strong) UIImageView *metroPictogram;

// favorite view
@property (nonatomic, strong) UILabel *stopNameFull;

@end

@implementation CFStopSignView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _verticallyCenteredLabelY = floorf((self.bounds.size.height - LABEL_HEIGHT) / 2);
        
        _contentViewWidth = self.bounds.size.width - HORIZONTAL_MARGIN * 2;
        
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, 0, _contentViewWidth, self.bounds.size.height)];
        [self addSubview:_contentView];
        
        _favoriteContentView = [[UIView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, 0, _contentViewWidth, self.bounds.size.height)];
        _favoriteContentView.hidden = YES;
        [self addSubview:_favoriteContentView];
        
        // regular content
        UIImageView *busPictogram = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bus"]];
        busPictogram.frame = CGRectMake(0, ceilf((self.bounds.size.height - busPictogram.bounds.size.height) / 2), busPictogram.bounds.size.width, busPictogram.bounds.size.height);
        [_contentView addSubview:busPictogram];
        
        _horizontalMarginWithPictogram = busPictogram.bounds.size.width + HORIZONTAL_MARGIN;
        
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(_horizontalMarginWithPictogram, 0, self.bounds.size.width - _horizontalMarginWithPictogram - _horizontalMarginWithPictogram, self.bounds.size.height)];
        [_contentView addSubview:_containerView];
        
        // una línea
        _stopNameSingleLineLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _verticallyCenteredLabelY, _containerView.bounds.size.width, LABEL_HEIGHT)];
        _stopNameSingleLineLabel.backgroundColor    = [UIColor clearColor];
        _stopNameSingleLineLabel.font               = [UIFont boldSystemFontOfSize:LABEL_FONT_SIZE];
        _stopNameSingleLineLabel.adjustsFontSizeToFitWidth = YES;
        _stopNameSingleLineLabel.textColor          = [UIColor whiteColor];
        _stopNameSingleLineLabel.autoresizingMask   = UIViewAutoresizingFlexibleWidth;
        _stopNameSingleLineLabel.hidden             = YES;
        //    stopNameSingleLineLabel.backgroundColor = [UIColor yellowColor];
        [_containerView addSubview:_stopNameSingleLineLabel];
        
        // dos líneas
        _stopNameTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (_containerView.bounds.size.height / 2) - LABEL_HEIGHT, _containerView.bounds.size.width, LABEL_HEIGHT)];
        _stopNameTopLabel.backgroundColor           = [UIColor clearColor];
        _stopNameTopLabel.font                      = [UIFont boldSystemFontOfSize:LABEL_FONT_SIZE];
        _stopNameTopLabel.adjustsFontSizeToFitWidth = YES;
        _stopNameTopLabel.textColor                 = [UIColor whiteColor];
        _stopNameTopLabel.autoresizingMask          = UIViewAutoresizingFlexibleWidth;
        _stopNameTopLabel.hidden                    = YES;
        //    stopNameTopLabel.backgroundColor = [UIColor cyanColor];
        [_containerView addSubview:_stopNameTopLabel];
        
        _stopNameBottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (_containerView.bounds.size.height / 2) + 1.0, _containerView.bounds.size.width, LABEL_HEIGHT)];
        _stopNameBottomLabel.backgroundColor        = [UIColor clearColor];
        _stopNameBottomLabel.font                   = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
        _stopNameBottomLabel.adjustsFontSizeToFitWidth = YES;
        _stopNameBottomLabel.textColor              = [UIColor whiteColor];
        _stopNameBottomLabel.autoresizingMask       = UIViewAutoresizingFlexibleWidth;
        _stopNameBottomLabel.hidden                 = YES;
        //    stopNameBottomLabel.backgroundColor = [UIColor cyanColor];
        [_containerView addSubview:_stopNameBottomLabel];
        
        // código de parada
        _stopCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_contentView.bounds.size.width - 65.0 - HORIZONTAL_MARGIN, _verticallyCenteredLabelY, 65.0, LABEL_HEIGHT)];
        _stopCodeLabel.backgroundColor              = [UIColor clearColor];
        _stopCodeLabel.font                         = [UIFont fontWithName:@"HelveticaNeue-Thin" size:LABEL_FONT_SIZE];
        _stopCodeLabel.textAlignment                = NSTextAlignmentRight;
        _stopCodeLabel.textColor                    = [UIColor colorWithWhite:1 alpha:1];
        _stopCodeLabel.alpha                        = 0.5;
        [_contentView addSubview:_stopCodeLabel];
        
        _stopNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(_horizontalMarginWithPictogram - 5.0, 0.0, 0.0, self.bounds.size.height)];
        _stopNumberLabel.backgroundColor        = [UIColor clearColor];
        _stopNumberLabel.numberOfLines          = 1;
        _stopNumberLabel.adjustsFontSizeToFitWidth = YES;
        _stopNumberLabel.minimumScaleFactor     = 0.5;
        _stopNumberLabel.contentMode            = UIViewContentModeCenter;
        _stopNumberLabel.font                   = [UIFont fontWithName:@"HelveticaNeue-Light" size:23];
        _stopNumberLabel.textColor              = [UIColor whiteColor];
        _stopNumberLabel.textAlignment          = NSTextAlignmentLeft;
        _stopNumberLabel.hidden                 = YES;
        [_contentView addSubview:_stopNumberLabel];
        
        _metroPictogram = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"metro"]];
        _metroPictogram.frame              = CGRectMake(self.horizontalMarginWithPictogram, ceilf((self.bounds.size.height - _metroPictogram.bounds.size.height) / 2), _metroPictogram.bounds.size.width, _metroPictogram.bounds.size.height);
        _metroPictogram.hidden             = YES;
        [_contentView addSubview:_metroPictogram];
    }
    return self;
}

- (void)layoutSubviews
{
    self.stopNameSingleLineLabel.frame = CGRectMake(0, self.verticallyCenteredLabelY, self.containerView.bounds.size.width, LABEL_HEIGHT);
    self.stopNameTopLabel.frame = CGRectMake(0, (self.containerView.bounds.size.height / 2) - LABEL_HEIGHT, self.containerView.bounds.size.width, LABEL_HEIGHT);
    self.stopNameBottomLabel.frame = CGRectMake(0, (self.containerView.bounds.size.height / 2) + 1.0, self.containerView.bounds.size.width, LABEL_HEIGHT);
    self.stopCodeLabel.frame = CGRectMake(self.contentView.bounds.size.width - 65.0, self.verticallyCenteredLabelY, 65.0, LABEL_HEIGHT);
}

- (void)setTintColor:(UIColor *)tintColor
{
    if (!self.tintColor) self.tintColor = [UIColor whiteColor];
    
}

- (void)setStop:(CFStop *)stop
{
    _stop = stop;
    
    if (stop.isFavorite) {
        self.contentView.hidden = YES;
        self.favoriteContentView.hidden = NO;
    } else {
        self.contentView.hidden = NO;
        self.favoriteContentView.hidden = YES;
    }
    
    // epic reset
    CGRect newContainerFrame = CGRectMake(self.horizontalMarginWithPictogram, 0, self.contentView.bounds.size.width - self.horizontalMarginWithPictogram * 2, self.bounds.size.height);
    
    self.stopNameSingleLineLabel.hidden = YES;
    self.stopNameTopLabel.hidden = YES;
    self.stopNameBottomLabel.hidden = YES;
    self.stopNumberLabel.hidden = YES;
    self.metroPictogram.hidden = YES;
    
    self.stopCodeLabel.text = stop.code;
    
    if (stop.intersection) {
        self.stopNameTopLabel.text = stop.street;
        self.stopNameBottomLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"AND_BUS_STOP", nil), stop.intersection];
        
        self.stopNameTopLabel.hidden = NO;
        self.stopNameBottomLabel.hidden = NO;
        
    } else {
        self.stopNameSingleLineLabel.hidden = NO;
        self.stopNameSingleLineLabel.text = stop.street;
    }
    
    // número de parada
    if (stop.number > 0) {
        self.stopNumberLabel.text = [NSString stringWithFormat:@"%d", stop.number];
        [self.stopNumberLabel sizeToFit];
        self.stopNumberLabel.frame = CGRectMake(self.stopNumberLabel.frame.origin.x, self.stopNumberLabel.frame.origin.y, self.stopNumberLabel.frame.size.width, self.bounds.size.height + 2.0);
        self.stopNumberLabel.hidden = NO;
        
        newContainerFrame.origin.x += self.stopNumberLabel.bounds.size.width + HORIZONTAL_MARGIN - 3.0;
        newContainerFrame.size.width -= self.stopNumberLabel.bounds.size.width;
    }
    
    // es metro
    if ([stop isMetro]) {
        newContainerFrame.origin.x += self.metroPictogram.bounds.size.width + 4.0;
        newContainerFrame.size.width -= (self.metroPictogram.bounds.size.width + HORIZONTAL_MARGIN);
        
        // tiene número
        if (stop.number > 0) {
            self.metroPictogram.frame = CGRectMake(self.horizontalMarginWithPictogram + self.stopNumberLabel.bounds.size.width + HORIZONTAL_MARGIN - 3.0, self.metroPictogram.frame.origin.y, self.metroPictogram.bounds.size.width, self.metroPictogram.bounds.size.height);
        }
        
        self.metroPictogram.hidden = NO;
    }
    
    self.containerView.frame = newContainerFrame;
    
    [self setNeedsLayout];
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    _accessoryView = accessoryView;
    
    if (accessoryView) {
        _accessoryView.frame = CGRectMake(self.bounds.size.width - HORIZONTAL_MARGIN - _accessoryView.bounds.size.width, floorf((self.bounds.size.height - _accessoryView.bounds.size.height) / 2 ), _accessoryView.bounds.size.width, _accessoryView.bounds.size.height);
        
        [self addSubview:_accessoryView];
        
        self.contentViewWidth = self.bounds.size.width - _accessoryView.bounds.size.width - HORIZONTAL_MARGIN * 2 + 4.0;
    }
}

- (void)setContentViewWidth:(CGFloat)contentViewWidth
{
    _contentViewWidth = contentViewWidth;
    
    self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, contentViewWidth, self.contentView.frame.size.height);
    self.favoriteContentView.frame = CGRectMake(self.favoriteContentView.frame.origin.x, self.favoriteContentView.frame.origin.y, contentViewWidth, self.favoriteContentView.frame.size.height);
    
    [self setNeedsLayout];
}

@end
