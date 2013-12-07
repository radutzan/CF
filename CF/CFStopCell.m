//
//  CFStopCell.m
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFStopCell.h"

@implementation CFStopCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.frame = CGRectMake(0, 0, self.bounds.size.width, CELL_HEIGHT);
        self.contentView.frame = CGRectMake(15.0, 0, self.contentView.bounds.size.width - 40.0, CELL_HEIGHT);
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width - HORIZONTAL_MARGIN * 2, self.contentView.bounds.size.height)];
        self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.nameLabel.numberOfLines = 2;
        self.nameLabel.font = [UIFont systemFontOfSize:15.0];
        [self.contentView addSubview:self.nameLabel];
        
        self.codeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width - 60.0, 0, 60.0, self.contentView.bounds.size.height)];
        self.codeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15.0];
        self.codeLabel.textAlignment = NSTextAlignmentRight;
        self.codeLabel.textColor = [UIColor colorWithWhite:0 alpha:0.5];
        [self.contentView addSubview:self.codeLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat nameLabelStartPosition = 0;
    
    if (!self.numberLabel.hidden) {
        self.numberLabel.frame = CGRectMake(nameLabelStartPosition, self.numberLabel.frame.origin.y, self.numberLabel.bounds.size.width, self.numberLabel.bounds.size.height);
        
        nameLabelStartPosition += self.numberLabel.frame.size.width + HORIZONTAL_MARGIN;
    }
    
    if (!self.metroBadge.hidden) {
        self.metroBadge.frame = CGRectMake(nameLabelStartPosition, 0, self.metroBadge.bounds.size.width, self.metroBadge.bounds.size.height);
        
        nameLabelStartPosition += self.metroBadge.frame.size.width + HORIZONTAL_MARGIN;
    }
    
    self.nameLabel.frame = CGRectMake(nameLabelStartPosition, 0, self.contentView.bounds.size.width - nameLabelStartPosition, self.contentView.bounds.size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UILabel *)numberLabel
{
    if (!_numberLabel) {
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 13.0, 26.0, 26.0)];
        _numberLabel.font = [UIFont systemFontOfSize:15];
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        _numberLabel.layer.borderColor = [UIColor blackColor].CGColor;
        _numberLabel.layer.borderWidth = 1.0;
        _numberLabel.layer.cornerRadius = 2.0;
        _numberLabel.hidden = YES;
        [self.contentView addSubview:_numberLabel];
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
        _metroBadge.frame = CGRectMake(0, 0, _metroBadge.bounds.size.width, self.contentView.bounds.size.height);
        _metroBadge.tintColor = self.nameLabel.textColor;
        _metroBadge.hidden = YES;
        [self.contentView addSubview:_metroBadge];
    }
    
    return _metroBadge;
}

- (void)prepareForReuse
{
    [self.numberLabel removeFromSuperview];
    [self.metroBadge removeFromSuperview];
    self.numberLabel = nil;
    self.metroBadge = nil;
}

@end
