//
//  CFResultCell.m
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFResultCell.h"

@implementation CFResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.contentView.bounds.size.width, 52.0);
        
        _directionLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0.0, 90.0, self.contentView.bounds.size.height)];
        _directionLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _directionLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _directionLabel.numberOfLines = 0;
        [self.contentView addSubview:_directionLabel];
        
        _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 9.0, 105.0, 20.0)];
        _distanceLabel.font = [UIFont systemFontOfSize:17.0];
        _distanceLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_distanceLabel];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 29.0, 105.0, 14.0)];
        _timeLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _timeLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        [self.contentView addSubview:_timeLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
