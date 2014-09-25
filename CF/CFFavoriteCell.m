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
        self.favoriteNameLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:19.0];
        self.favoriteNameLabel.textColor = [UIColor colorWithWhite:0 alpha:0.8];
        [self.containerView addSubview:self.favoriteNameLabel];
        
        self.nameLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:11.0];
        self.nameLabel.alpha = 0.6;
        self.nameLabel.numberOfLines = 1;
        
        self.favoriteBadge = [[UIImageView alloc] initWithImage:[UIImage starImageWithSize:CGSizeMake(20.0, 20.0) filled:YES]];
        self.favoriteBadge.center = CGPointMake(self.favoriteBadge.center.x, self.center.y);
        self.favoriteBadge.tintColor = [UIColor colorWithWhite:0 alpha:.2];
        self.favoriteBadge.hidden = YES;
        [self.containerView addSubview:self.favoriteBadge];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.favoriteNameLabel.frame = CGRectMake(0, 9.0, self.contentView.bounds.size.width, 22.0);
    self.nameLabel.frame = CGRectMake(0, 33.0, self.contentView.bounds.size.width, 12.0);
    
    if (!self.favoriteBadge.hidden) {
        CGFloat xDisplacement = self.favoriteBadge.bounds.size.width + 9.0;
        self.favoriteNameLabel.frame = CGRectMake(xDisplacement, 9.0, self.contentView.bounds.size.width - xDisplacement, 22.0);
        self.nameLabel.frame = CGRectMake(xDisplacement, 33.0, self.contentView.bounds.size.width - xDisplacement, 12.0);
    }
    
    self.numberLabel.hidden = YES;
    self.metroBadge.hidden = YES;
//    self.codeLabel.hidden = YES;
}

@end
