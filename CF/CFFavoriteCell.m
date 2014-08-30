//
//  CFFavoriteCell.m
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFFavoriteCell.h"

@implementation CFFavoriteCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.favoriteNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 9.0, self.contentView.bounds.size.width, 22.0)];
        self.favoriteNameLabel.font = [UIFont systemFontOfSize:19.0];
        self.favoriteNameLabel.textColor = [UIColor colorWithWhite:0 alpha:0.8];
        [self.containerView addSubview:self.favoriteNameLabel];
        
        self.nameLabel.font = [UIFont boldSystemFontOfSize:11.0];
        self.nameLabel.alpha = 0.6;
        self.nameLabel.numberOfLines = 1;
        self.nameLabel.frame = CGRectMake(0, 32.0, self.contentView.bounds.size.width, 12.0);
    }
    return self;
}

- (void)layoutSubviews
{
    self.numberLabel.hidden = YES;
    self.metroBadge.hidden = YES;
    self.codeLabel.hidden = YES;
}

@end
