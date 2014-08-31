//
//  CFStopCell.m
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFStopCell.h"

@interface CFStopCell ()


@end

@implementation CFStopCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.frame = CGRectMake(0, 0, self.bounds.size.width, CELL_HEIGHT);
        self.containerView = [[UIView alloc] initWithFrame:CGRectMake(15.0, 0, self.bounds.size.width - 40.0, CELL_HEIGHT)];
        [self.contentView addSubview:self.containerView];
        
        self.contentInsets = UIEdgeInsetsMake(0, 15.0, 0, 0.0);
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.containerView.bounds.size.width - HORIZONTAL_MARGIN * 2, self.containerView.bounds.size.height)];
        self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.nameLabel.numberOfLines = 2;
        self.nameLabel.font = [UIFont boldSystemFontOfSize:15.0];
        self.nameLabel.textColor = [UIColor colorWithWhite:0 alpha:0.8];
        [self.containerView addSubview:self.nameLabel];
        
        self.codeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.containerView.bounds.size.width - 60.0, 0, 60.0, self.containerView.bounds.size.height)];
        self.codeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15.0];
        self.codeLabel.textAlignment = NSTextAlignmentRight;
        self.codeLabel.textColor = [UIColor colorWithWhite:0 alpha:0.5];
        [self.containerView addSubview:self.codeLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.containerView.frame = CGRectMake(self.contentInsets.left, 0, self.contentView.bounds.size.width - self.contentInsets.left - self.contentInsets.right, CELL_HEIGHT);
    self.codeLabel.frame = CGRectMake(self.containerView.bounds.size.width - 60.0, 0, 60.0, self.containerView.bounds.size.height);
    
    CGFloat nameLabelStartPosition = 0;
    
    if (!self.numberLabel.hidden) {
        self.numberLabel.frame = CGRectMake(nameLabelStartPosition, self.numberLabel.frame.origin.y, self.numberLabel.bounds.size.width, self.numberLabel.bounds.size.height);
        
        nameLabelStartPosition += self.numberLabel.frame.size.width + HORIZONTAL_MARGIN;
    }
    
    if (!self.metroBadge.hidden) {
        self.metroBadge.frame = CGRectMake(nameLabelStartPosition, 0, self.metroBadge.bounds.size.width, self.metroBadge.bounds.size.height);
        self.metroBadge.tintColor = self.nameLabel.textColor;
        
        nameLabelStartPosition += self.metroBadge.frame.size.width + HORIZONTAL_MARGIN;
    }
    
    self.nameLabel.frame = CGRectMake(nameLabelStartPosition, 0, self.containerView.bounds.size.width - nameLabelStartPosition, self.containerView.bounds.size.height);
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
    _contentInsets = contentInsets;
    
    self.containerView.frame = CGRectMake(contentInsets.left, 0, self.contentView.bounds.size.width - contentInsets.left - contentInsets.right, CELL_HEIGHT);
    [self layoutIfNeeded];
}

- (UILabel *)numberLabel
{
    if (!_numberLabel) {
        CGFloat originY = (self.containerView.bounds.size.height - 26.0) / 2;
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, originY, 26.0, 26.0)];
        _numberLabel.font = [UIFont systemFontOfSize:15];
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        _numberLabel.textColor = self.nameLabel.textColor;
        _numberLabel.layer.borderColor = self.nameLabel.textColor.CGColor;
        _numberLabel.layer.borderWidth = 1.0;
        _numberLabel.layer.cornerRadius = 2.0;
        _numberLabel.hidden = YES;
        [self.containerView addSubview:_numberLabel];
    }
    
    return _numberLabel;
}

- (UIImageView *)metroBadge
{
    if (!_metroBadge) {
        UIImage *metroImage = [UIImage imageNamed:@"metro"];
        metroImage = [metroImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        _metroBadge = [[UIImageView alloc] initWithImage:metroImage];
        _metroBadge.contentMode = UIViewContentModeCenter;
        _metroBadge.frame = CGRectMake(0, 0, _metroBadge.bounds.size.width, self.containerView.bounds.size.height);
        _metroBadge.tintColor = self.nameLabel.textColor;
        _metroBadge.hidden = YES;
        [self.containerView addSubview:_metroBadge];
    }
    
    return _metroBadge;
}

- (void)prepareForReuse
{
    [self.numberLabel removeFromSuperview];
    [self.metroBadge removeFromSuperview];
    self.numberLabel = nil;
    self.metroBadge = nil;
    self.contentInsets = UIEdgeInsetsMake(0, 15.0, 0, 0.0);
}

@end
