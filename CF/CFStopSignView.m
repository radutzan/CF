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

@interface CFStopSignView () <UITextFieldDelegate>

@property (nonatomic) CGFloat verticallyCenteredLabelY;
@property (nonatomic) CGFloat horizontalMarginWithPictogram;
@property (nonatomic) CGFloat contentViewWidth;

// regular view
@property (nonatomic, strong) UILabel *stopNameLabel;
@property (nonatomic, strong) UILabel *stopNumberLabel;
@property (nonatomic, strong) UIImageView *metroPictogram;

// favorite view
@property (nonatomic, strong) UILabel *stopFullNameLabel;

@end

@implementation CFStopSignView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _verticallyCenteredLabelY = floorf((frame.size.height - LABEL_HEIGHT) / 2);
        
        _contentViewWidth = frame.size.width - HORIZONTAL_MARGIN * 2;
        
        _busPictogram = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bus"]];
        _busPictogram.frame = CGRectMake(HORIZONTAL_MARGIN + 1.0, ceilf((frame.size.height - _busPictogram.bounds.size.height) / 2), _busPictogram.bounds.size.width, _busPictogram.bounds.size.height);
        [self addSubview:_busPictogram];
        
        _horizontalMarginWithPictogram = _busPictogram.bounds.size.width + HORIZONTAL_MARGIN;
        
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN + _horizontalMarginWithPictogram, 0, _contentViewWidth - _horizontalMarginWithPictogram, frame.size.height)];
        [self addSubview:_contentView];
        
        _favoriteContentView = [[UIView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN + _horizontalMarginWithPictogram, 0, _contentViewWidth - _horizontalMarginWithPictogram, frame.size.height)];
        _favoriteContentView.hidden = YES;
        _favoriteContentView.userInteractionEnabled = NO;
        [self addSubview:_favoriteContentView];
        
        [self initRegularContentView];
        [self initFavoriteContentView];
    }
    return self;
}

- (void)initRegularContentView
{
    // the one and only label
    _stopNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, _contentView.bounds.size.height)];
    _stopNameLabel.backgroundColor    = [UIColor clearColor];
    _stopNameLabel.adjustsFontSizeToFitWidth = YES;
    _stopNameLabel.font               = [UIFont fontWithName:DEFAULT_FONT_NAME_BOLD size:LABEL_FONT_SIZE];
    _stopNameLabel.textColor          = [UIColor whiteColor];
    _stopNameLabel.autoresizingMask   = UIViewAutoresizingFlexibleWidth;
    _stopNameLabel.hidden             = NO;
    _stopNameLabel.numberOfLines      = 2;
    //    stopNameSingleLineLabel.backgroundColor = [UIColor yellowColor];
    [_contentView addSubview:_stopNameLabel];
    
    // código de parada
    _stopCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_contentView.bounds.size.width - 65.0 - HORIZONTAL_MARGIN, _verticallyCenteredLabelY, 65.0, LABEL_HEIGHT)];
    _stopCodeLabel.backgroundColor    = [UIColor clearColor];
    _stopCodeLabel.font               = [UIFont fontWithName:@"AvenirNext-UltraLight" size:LABEL_FONT_SIZE];
    _stopCodeLabel.textAlignment      = NSTextAlignmentRight;
    _stopCodeLabel.textColor          = [UIColor colorWithWhite:1 alpha:1];
    _stopCodeLabel.alpha              = 0.5;
    [_contentView addSubview:_stopCodeLabel];
    
    _stopNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(-5.0, 0.0, 0.0, self.bounds.size.height)];
    _stopNumberLabel.backgroundColor  = [UIColor clearColor];
    _stopNumberLabel.numberOfLines    = 1;
    _stopNumberLabel.adjustsFontSizeToFitWidth = YES;
    _stopNumberLabel.minimumScaleFactor = 0.5;
    _stopNumberLabel.contentMode      = UIViewContentModeCenter;
    _stopNumberLabel.font             = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:23];
    _stopNumberLabel.textColor        = [UIColor whiteColor];
    _stopNumberLabel.textAlignment    = NSTextAlignmentLeft;
    _stopNumberLabel.hidden           = YES;
    [_contentView addSubview:_stopNumberLabel];
    
    _metroPictogram = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"metro"]];
    _metroPictogram.frame             = CGRectMake(0, ceilf((self.bounds.size.height - _metroPictogram.bounds.size.height) / 2), _metroPictogram.bounds.size.width, _metroPictogram.bounds.size.height);
    _metroPictogram.hidden            = YES;
    [_contentView addSubview:_metroPictogram];
}

- (void)initFavoriteContentView
{
    _favoriteNameField = [[OLTextField alloc] initWithFrame:CGRectMake(0, 10.0, _favoriteContentView.bounds.size.width, 20.0)];
    _favoriteNameField.placeholder    = NSLocalizedString(@"NAME_YOUR_FAVORITE", nil);
    _favoriteNameField.textColor      = [UIColor whiteColor];
    _favoriteNameField.placeholderTextColor = [UIColor colorWithWhite:1 alpha:0.3];
    _favoriteNameField.font           = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:18.0];
    _favoriteNameField.returnKeyType  = UIReturnKeyDone;
    _favoriteNameField.keyboardAppearance = UIKeyboardAppearanceDark;
    _favoriteNameField.delegate       = self;
    [_favoriteContentView addSubview:_favoriteNameField];
    
    _stopFullNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 32.0, _favoriteContentView.bounds.size.width, 12.0)];
    _stopFullNameLabel.font           = [UIFont fontWithName:DEFAULT_FONT_NAME_BOLD size:11.0];
    _stopFullNameLabel.textColor      = [UIColor colorWithWhite:1 alpha:0.6];
    [_favoriteContentView addSubview:_stopFullNameLabel];
}

- (void)layoutSubviews
{
    self.stopCodeLabel.frame = CGRectMake(self.contentView.bounds.size.width - 65.0, self.verticallyCenteredLabelY, 65.0, LABEL_HEIGHT);
    
    if (self.busPictogram.hidden)
        self.contentViewWidth = self.bounds.size.width - HORIZONTAL_MARGIN * 2;
    else
        self.contentViewWidth = self.bounds.size.width - (HORIZONTAL_MARGIN * 3) + _busPictogram.bounds.size.width;
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
    
    if (stop.favoriteName) {
        self.favoriteNameField.text = stop.favoriteName;
    } else {
        self.favoriteNameField.text = @"";
    }
    self.stopFullNameLabel.text = stop.name;
    
    // reset
    CGRect newLabelFrame = CGRectMake(0, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
    
    self.stopNumberLabel.hidden = YES;
    self.metroPictogram.hidden = YES;
    
    self.stopCodeLabel.text = stop.code;
    
    if (stop.intersection) {
        NSRange firstLineRange = NSMakeRange(0, [stop.street length]);
        
        UIFont *boldFont = [UIFont fontWithName:DEFAULT_FONT_NAME_BOLD size:LABEL_FONT_SIZE];
        UIFont *regularFont = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:LABEL_FONT_SIZE];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName, nil];
        NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil];
        NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
        paragrahStyle.maximumLineHeight = 18.0;
        
        NSString *fullString = [NSString stringWithFormat:@"%@\n%@ %@", stop.street, NSLocalizedString(@"AND_BUS_STOP", nil), stop.intersection];
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:fullString attributes:attrs];
        [attributedText setAttributes:subAttrs range:firstLineRange];
        [attributedText addAttribute:NSParagraphStyleAttributeName value:paragrahStyle range:NSMakeRange(0, fullString.length)];
        
        [self.stopNameLabel setAttributedText:attributedText];
        newLabelFrame.origin.y += 2.0;
        
    } else {
        self.stopNameLabel.text = stop.street;
    }
    
    // número de parada
    if (stop.number > 0) {
        self.stopNumberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)stop.number];
        [self.stopNumberLabel sizeToFit];
        self.stopNumberLabel.frame = CGRectMake(self.stopNumberLabel.frame.origin.x, self.stopNumberLabel.frame.origin.y, self.stopNumberLabel.frame.size.width, self.bounds.size.height + 2.0);
        self.stopNumberLabel.hidden = NO;
        
        newLabelFrame.origin.x += self.stopNumberLabel.bounds.size.width + HORIZONTAL_MARGIN - 6.0;
        newLabelFrame.size.width -= newLabelFrame.origin.x;
    }
    
    // es metro
    if ([stop isMetro]) {
        newLabelFrame.origin.x += self.metroPictogram.bounds.size.width + 4.0;
        newLabelFrame.size.width -= (self.metroPictogram.bounds.size.width + HORIZONTAL_MARGIN);
        
        // tiene número
        if (stop.number > 0) {
            self.metroPictogram.frame = CGRectMake(self.stopNumberLabel.bounds.size.width + HORIZONTAL_MARGIN - 6.0, self.metroPictogram.frame.origin.y, self.metroPictogram.bounds.size.width, self.metroPictogram.bounds.size.height);
        }
        
        self.metroPictogram.hidden = NO;
    }
    
    self.stopNameLabel.frame = newLabelFrame;
    
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
    
//    [self setNeedsLayout];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.delegate stopSignView:self didEditFavoriteNameWithString:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    
    return NO;
}

@end
