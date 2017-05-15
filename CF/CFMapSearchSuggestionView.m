//
//  CFMapSearchSuggestionView.m
//  CF
//
//  Created by Radu Dutzan on 9/18/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFMapSearchSuggestionView.h"

#define VERTICAL_MARGIN 10.0

@interface CFMapSearchSuggestionView ()

@property (nonatomic, strong) UILabel *searchTextLabel;
@property (nonatomic, strong) UILabel *actionDescriptionLabel;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) CALayer *borderLayer;

@end

@implementation CFMapSearchSuggestionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.backgroundColor = [UIApplication sharedApplication].keyWindow.tintColor;
        [self addSubview:_backgroundView];
        
        UITapGestureRecognizer *mapSearchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
        [_backgroundView addGestureRecognizer:mapSearchTap];
        
        UIImageView *searchIconImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        searchIconImageView.tintColor = [UIColor colorWithWhite:1 alpha:.7];
        searchIconImageView.frame = CGRectOffset(searchIconImageView.frame, 15.0, VERTICAL_MARGIN + 5.0);
        [_backgroundView addSubview:searchIconImageView];
        
        _searchTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(35.0, VERTICAL_MARGIN, frame.size.width - 35.0 - 10.0, 20.0)];
        _searchTextLabel.numberOfLines = 0;
        _searchTextLabel.text = @"";
        _searchTextLabel.textColor = [UIColor whiteColor];
        _searchTextLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];//fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
        [_backgroundView addSubview:_searchTextLabel];
        
        _actionDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _actionDescriptionLabel.text = [NSLocalizedString(@"MAP_SEARCH_SUGGESTION_CARD_TEXT", nil) uppercaseString];
        _actionDescriptionLabel.textColor = [UIColor colorWithWhite:1 alpha:.7];
        _actionDescriptionLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];//fontWithName:@"AvenirNextCondensed-Medium" size:12.0];
        [_backgroundView addSubview:_actionDescriptionLabel];
        
        _borderLayer = [CALayer layer];
        _borderLayer.frame = CGRectInset(_backgroundView.frame, -0.5, -0.5);
        _borderLayer.borderWidth = 0.5;
        _borderLayer.borderColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
        [self.layer addSublayer:_borderLayer];
    }
    return self;
}

- (void)setSearchText:(NSString *)searchText
{
    CGFloat maxLabelWidth = self.bounds.size.width - self.searchTextLabel.frame.origin.x - 10.0;
    
    self.searchTextLabel.text = searchText;
    self.searchTextLabel.frame = CGRectMake(self.searchTextLabel.frame.origin.x, VERTICAL_MARGIN, maxLabelWidth, 20.0);
    [self.searchTextLabel sizeToFit];
    
    self.actionDescriptionLabel.frame = CGRectMake(self.searchTextLabel.frame.origin.x, VERTICAL_MARGIN + self.searchTextLabel.bounds.size.height + 1.0, maxLabelWidth, 12.0);
    
    self.backgroundView.frame = CGRectMake(self.backgroundView.frame.origin.x, self.backgroundView.frame.origin.y, self.backgroundView.bounds.size.width, self.searchTextLabel.bounds.size.height + self.actionDescriptionLabel.bounds.size.height + VERTICAL_MARGIN * 2);
    _borderLayer.frame = CGRectInset(_backgroundView.frame, -0.5, -0.5);
}

- (void)viewTapped
{
    [self.delegate mapSearchSuggestionViewTapped];
}

@end
