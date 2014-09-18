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

@property (nonatomic, strong) UILabel *mapSearchLabel;
@property (nonatomic, strong) UIView *backgroundView;

@end

@implementation CFMapSearchSuggestionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if (NSClassFromString(@"UIVisualEffectView")) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
            
            _backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            _backgroundView.frame = self.bounds;
            [self addSubview:_backgroundView];
        } else {
            _backgroundView = [[UINavigationBar alloc] initWithFrame:self.bounds];
            [self addSubview:_backgroundView];
        }
        
        UITapGestureRecognizer *mapSearchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
        [_backgroundView addGestureRecognizer:mapSearchTap];
        
        UIImageView *searchIconImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        searchIconImageView.tintColor = [UIColor colorWithWhite:0 alpha:.5];
        searchIconImageView.frame = CGRectOffset(searchIconImageView.frame, 15.0, VERTICAL_MARGIN + 5.0);
        [_backgroundView addSubview:searchIconImageView];
        
        _mapSearchLabel = [[UILabel alloc] initWithFrame:CGRectMake(35.0, VERTICAL_MARGIN, frame.size.width - 35.0 - 10.0, 20.0)];
        _mapSearchLabel.numberOfLines = 0;
        _mapSearchLabel.text = NSLocalizedString(@"MAP_SEARCH_SUGGESTION_CARD_TEXT", nil);
        _mapSearchLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
        [_backgroundView addSubview:_mapSearchLabel];
    }
    return self;
}

- (void)setSearchText:(NSString *)searchText
{
    self.mapSearchLabel.text = [NSString stringWithFormat:NSLocalizedString(@"MAP_SEARCH_SUGGESTION_CARD_TEXT", nil), searchText];
    self.mapSearchLabel.textColor = self.tintColor;
    self.mapSearchLabel.frame = CGRectMake(self.mapSearchLabel.frame.origin.x, VERTICAL_MARGIN, self.bounds.size.width - self.mapSearchLabel.frame.origin.x - 10.0, 20.0);
    [self.mapSearchLabel sizeToFit];
    
    self.backgroundView.frame = CGRectMake(self.backgroundView.frame.origin.x, self.backgroundView.frame.origin.y, self.backgroundView.bounds.size.width, self.mapSearchLabel.bounds.size.height + VERTICAL_MARGIN * 2);
}

- (void)viewTapped
{
    [self.delegate mapSearchSuggestionViewTapped];
}

@end
