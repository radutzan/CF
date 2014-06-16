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

@implementation CFSearchSuggestionsCard

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UINavigationBar *backgroundView = [[UINavigationBar alloc] initWithFrame:self.bounds];
        backgroundView.barStyle = UIBarStyleBlack;
//        UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
//        backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:.7];
        [self addSubview:backgroundView];
        
        CGFloat contentWidth = self.bounds.size.width - HORIZONTAL_MARGIN * 2;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, TOP_MARGIN, contentWidth, 0.0)];
//        titleLabel.text = @"Search";
//        [self addSubview:titleLabel];
        
        NSArray *contentArray = @[@{@"name": @"Stop Code", @"example": @"PA420, PB34, PC70…"},
                                  @{@"name": @"Service", @"example": @"503, C04, 112…"},
                                  @{@"name": @"Place", @"example": @"Plaza de Armas, Los Navegantes 1919…"}];
        
        CGFloat topGuide = TOP_MARGIN + titleLabel.bounds.size.height + VERTICAL_SPACING;
        
        for (NSDictionary *suggestion in contentArray) {
            UILabel *suggestionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN, topGuide, 90, 20.0)];
            suggestionTitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
            suggestionTitleLabel.textColor = [UIColor whiteColor];
            suggestionTitleLabel.text = suggestion[@"name"];
            suggestionTitleLabel.textAlignment = NSTextAlignmentRight;
            [self addSubview:suggestionTitleLabel];
            
            UILabel *suggestionExampleLabel = [[UILabel alloc] initWithFrame:CGRectMake(HORIZONTAL_MARGIN + suggestionTitleLabel.bounds.size.width + 10.0, topGuide, contentWidth - suggestionTitleLabel.bounds.size.width + 10.0, 20.0)];
            suggestionExampleLabel.font = [UIFont systemFontOfSize:16.0];
            suggestionExampleLabel.textColor = [UIColor colorWithWhite:1 alpha:.6];
            suggestionExampleLabel.text = suggestion[@"example"];
            suggestionExampleLabel.numberOfLines = 0;
            [suggestionExampleLabel sizeToFit];
            [self addSubview:suggestionExampleLabel];
            
            topGuide += suggestionExampleLabel.bounds.size.height + VERTICAL_SPACING;
        }
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, topGuide - VERTICAL_SPACING + TOP_MARGIN);
    }
    return self;
}

@end
