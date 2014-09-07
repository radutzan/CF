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
#define HORIZONTAL_MARGIN 10.0

@interface CFSearchSuggestionsCard ()

@property (nonatomic, strong) UIVisualEffectView *vibrancyEffectView;

@end

@implementation CFSearchSuggestionsCard

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *backgroundView;
        if (NSClassFromString(@"UIVisualEffectView")) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];

            backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            backgroundView.frame = self.bounds;
            [self addSubview:backgroundView];
            
            UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
            _vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
            _vibrancyEffectView.frame = backgroundView.bounds;
            _vibrancyEffectView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            UIVisualEffectView *castedBackgroundView = (UIVisualEffectView *)backgroundView;
            [castedBackgroundView.contentView addSubview:_vibrancyEffectView];
        } else {
            backgroundView = [[UINavigationBar alloc] initWithFrame:self.bounds];
//            backgroundView.backgroundColor = [UIColor colorWithWhite:.97 alpha:.9];
            [self addSubview:backgroundView];
        }
        
        NSArray *contentArray = @[
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_STOP_CODE_TITLE", nil),
    @"example": @"PA420, PB34, PC70…"},
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_SERVICE_TITLE", nil),
    @"example": @"503, C04, 112…"},
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_PLACE_TITLE", nil),
    @"example": @"“Plaza de Armas”, \n“Los Navegantes 1919”…"}];
        
        CGFloat contentWidth = self.bounds.size.width - HORIZONTAL_MARGIN * 2;
        CGFloat topGuide = TOP_MARGIN + VERTICAL_SPACING;
        CGFloat titleWidth = 70.0;
        
        for (NSDictionary *suggestion in contentArray) {
            UILabel *suggestionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, topGuide, titleWidth, 20.0)];
            suggestionTitleLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:17.0];
            suggestionTitleLabel.textColor = [UIColor colorWithWhite:0 alpha:.8];
            suggestionTitleLabel.text = suggestion[@"name"];
            suggestionTitleLabel.textAlignment = NSTextAlignmentRight;
            [self addSubview:suggestionTitleLabel];
            
            UILabel *suggestionExampleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN + suggestionTitleLabel.bounds.size.width + 10.0, topGuide - 1.0, contentWidth - titleWidth + 10.0, 20.0)];
            suggestionExampleLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:17.0];
            suggestionExampleLabel.text = suggestion[@"example"];
            suggestionExampleLabel.numberOfLines = 0;
            [suggestionExampleLabel sizeToFit];
            if (_vibrancyEffectView) {
                [_vibrancyEffectView.contentView addSubview:suggestionExampleLabel];
            } else {
                suggestionExampleLabel.textColor = [UIColor colorWithWhite:0 alpha:.45];
                [self addSubview:suggestionExampleLabel];
            }
            
            topGuide += ceilf(suggestionExampleLabel.bounds.size.height) + VERTICAL_SPACING;
        }
        
        backgroundView.frame = CGRectMake(0, 0, self.bounds.size.width, topGuide + TOP_MARGIN);
    }
    return self;
}

@end
