//
//  CFResultCell.m
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFResultCell.h"

@interface CFResultCell ()

@property (nonatomic, strong) UIView *estimationContainer;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *distanceLabel;
@property (nonatomic, strong) UILabel *noInfoLabel;
@property (nonatomic, strong) UIButton *toggleButton;

@end

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
        
        _estimationContainer = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 0, 105.0, self.contentView.bounds.size.height)];
        [self.contentView addSubview:_estimationContainer];
        
        _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 9.0, 105.0, 20.0)];
        _distanceLabel.font = [UIFont systemFontOfSize:17.0];
        _distanceLabel.textColor = [UIColor whiteColor];
        [_estimationContainer addSubview:_distanceLabel];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 29.0, 105.0, 14.0)];
        _timeLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _timeLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        [_estimationContainer addSubview:_timeLabel];
        
        _noInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 0, 105.0, self.contentView.bounds.size.height)];
        _noInfoLabel.font = [UIFont systemFontOfSize:15.0];
        _noInfoLabel.textColor = [UIColor whiteColor];
        _noInfoLabel.hidden = YES;
        _noInfoLabel.text = NSLocalizedString(@"NO_INFO", nil);
        _noInfoLabel.numberOfLines = 0;
        [self.contentView addSubview:_noInfoLabel];
        
        _toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _toggleButton.frame = CGRectMake(200.0, 0, 105.0, self.contentView.bounds.size.height);
        _toggleButton.hidden = YES;
        [_toggleButton addTarget:self action:@selector(toggleEstimations) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_toggleButton];
    }
    return self;
}

- (void)setEstimations:(NSArray *)estimations
{
    _estimations = estimations;
    
    self.toggleButton.hidden = YES;
    
    if (estimations.count == 0) {
        self.distanceLabel.text = @"";
        self.timeLabel.text = @"";
        self.noInfoLabel.hidden = NO;
    } else {
        self.noInfoLabel.hidden = YES;
        self.distanceLabel.text = [[estimations firstObject] objectForKey:@"distance"];
        self.timeLabel.text = [[estimations firstObject] objectForKey:@"eta"];
    }
    
    if (estimations.count > 1) {
        self.toggleButton.hidden = NO;
    }
}

- (void)toggleEstimations
{
    NSString *firstEstimationDistance = [[self.estimations firstObject] objectForKey:@"distance"];
    NSString *firstEstimationTime = [[self.estimations firstObject] objectForKey:@"eta"];
    NSString *secondEstimationDistance = [[self.estimations lastObject] objectForKey:@"distance"];
    NSString *secondEstimationTime = [[self.estimations lastObject] objectForKey:@"eta"];
    
    if ([self.distanceLabel.text isEqualToString:firstEstimationDistance]
        && [self.timeLabel.text isEqualToString:firstEstimationTime]) {
        self.distanceLabel.text = secondEstimationDistance;
        self.timeLabel.text = secondEstimationTime;
    } else {
        self.distanceLabel.text = firstEstimationDistance;
        self.timeLabel.text = firstEstimationTime;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
