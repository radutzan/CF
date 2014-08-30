//
//  CFSearchSuggestionsCard.m
//  CF
//
//  Created by Radu Dutzan on 6/14/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFSearchSuggestionsCard.h"

#define TOP_MARGIN 15.0
#define VERTICAL_SPACING 10.0
#define HORIZONTAL_MARGIN 10.0

@interface CFSearchSuggestionsCard ()

@property (nonatomic, strong) UIVisualEffectView *vibrancyEffectView;

@end

@implementation CFSearchSuggestionsCard

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if (NSClassFromString(@"UIVisualEffectView")) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];

            UIVisualEffectView *backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            backgroundView.frame = self.bounds;
            [self addSubview:backgroundView];
            
            UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
            _vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
            _vibrancyEffectView.frame = self.bounds;
            [backgroundView.contentView addSubview:_vibrancyEffectView];
        } else {
            UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
            backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:.8];
            [self addSubview:backgroundView];
        }
        
        CGFloat contentWidth = self.bounds.size.width - HORIZONTAL_MARGIN * 2;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, TOP_MARGIN, contentWidth, 0.0)];
//        titleLabel.text = @"Search";
//        [self addSubview:titleLabel];
        
        NSArray *contentArray = @[
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_STOP_CODE_TITLE", nil),
    @"example": @"PA420, PB34, PC70…"},
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_SERVICE_TITLE", nil),
    @"example": @"503, C04, 112…"},
  @{@"name": NSLocalizedString(@"SEARCH_SUGGESTION_CARD_PLACE_TITLE", nil),
    @"example": @"“Plaza de Armas”, \n“Los Navegantes 1919”…"}];
        
        CGFloat topGuide = TOP_MARGIN + titleLabel.bounds.size.height + VERTICAL_SPACING;
        
        for (NSDictionary *suggestion in contentArray) {
            UILabel *suggestionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, topGuide, 90, 20.0)];
            suggestionTitleLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_BOLD size:16.0];
            suggestionTitleLabel.textColor = [UIColor whiteColor];
            suggestionTitleLabel.text = suggestion[@"name"];
            suggestionTitleLabel.textAlignment = NSTextAlignmentRight;
            [self addSubview:suggestionTitleLabel];
            
            UILabel *suggestionExampleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN + suggestionTitleLabel.bounds.size.width + 10.0, topGuide - 1.0, contentWidth - suggestionTitleLabel.bounds.size.width + 10.0, 20.0)];
            suggestionExampleLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:16.0];
            suggestionExampleLabel.text = suggestion[@"example"];
            suggestionExampleLabel.numberOfLines = 0;
            [suggestionExampleLabel sizeToFit];
            if (_vibrancyEffectView) {
                [_vibrancyEffectView.contentView addSubview:suggestionExampleLabel];
            } else {
                suggestionExampleLabel.textColor = [UIColor colorWithWhite:1 alpha:.6];
                [self addSubview:suggestionExampleLabel];
            }
            
            topGuide += suggestionExampleLabel.bounds.size.height + VERTICAL_SPACING;
        }
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, topGuide - VERTICAL_SPACING + TOP_MARGIN);
    }
    return self;
}

@end
