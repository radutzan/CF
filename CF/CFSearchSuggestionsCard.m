//
//  CFSearchSuggestionsCard.m
//  CF
//
//  Created by Radu Dutzan on 6/14/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFSearchSuggestionsCard.h"

#define TOP_MARGIN 10.0
#define VERTICAL_SPACING 12.0
#define HORIZONTAL_MARGIN 12.0

@interface CFSearchSuggestionsCard ()

@property (nonatomic, strong) UIView *backgroundView;

@end

@implementation CFSearchSuggestionsCard

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.backgroundColor = [UIApplication sharedApplication].keyWindow.tintColor;
        [self addSubview:_backgroundView];
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, TOP_MARGIN, 320 - HORIZONTAL_MARGIN * 2, self.bounds.size.height - TOP_MARGIN * 2)];
        containerView.center = _backgroundView.center;
        [self addSubview:containerView];
        
        NSArray *contentArray = @[
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_STOP_CODE_TITLE", nil),
    @"example": @"PA420, PB34, PC70…"},
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_SERVICE_TITLE", nil),
    @"example": @"503, C04, 112…"},
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_PLACE_TITLE", nil),
    @"example": @"“Plaza de Armas”, \n“Los Navegantes 1919”…"}];
        
        CGFloat topGuide = VERTICAL_SPACING - 2;
        CGFloat titleWidth = 70.0;
        BOOL hasExtraRoom = (self.bounds.size.width > 320);
        NSString *suggestionTitleLabelFontName = (hasExtraRoom) ? DEFAULT_FONT_NAME_MEDIUM : @"AvenirNextCondensed-Medium";
        
        for (NSDictionary *suggestion in contentArray) {
            UILabel *suggestionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, topGuide, titleWidth, 20.0)];
            suggestionTitleLabel.font = [UIFont fontWithName:suggestionTitleLabelFontName size:17.0];
            suggestionTitleLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
            suggestionTitleLabel.text = suggestion[@"name"];
            suggestionTitleLabel.textAlignment = NSTextAlignmentRight;
            [containerView addSubview:suggestionTitleLabel];
            
            UILabel *suggestionExampleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN + titleWidth, topGuide - 1.0, containerView.bounds.size.width - titleWidth + 10.0, 20.0)];
            suggestionExampleLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:17.0];
            suggestionExampleLabel.text = suggestion[@"example"];
            suggestionExampleLabel.numberOfLines = 0;
            [suggestionExampleLabel sizeToFit];
            suggestionExampleLabel.textColor = [UIColor colorWithWhite:1 alpha:.7];
            [containerView addSubview:suggestionExampleLabel];
            
            topGuide += ceilf(suggestionExampleLabel.bounds.size.height) + VERTICAL_SPACING;
        }
        
        _backgroundView.frame = CGRectMake(0, 0, self.bounds.size.width, topGuide + TOP_MARGIN * 2 - 6);
        
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectInset(_backgroundView.frame, -0.5, -0.5);
        borderLayer.borderWidth = 0.5;
        borderLayer.borderColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
        [self.layer addSublayer:borderLayer];
    }
    return self;
}

@end
