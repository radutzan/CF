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
@property (nonatomic, strong) CALayer *estimationIndicators;
@property (nonatomic, strong) CALayer *currentIndicator;

@end

@implementation CFResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.contentView.bounds.size.width, 52.0);
        
        _directionLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0.0, 90.0, self.contentView.bounds.size.height)];
        _directionLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _directionLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        _directionLabel.numberOfLines = 0;
        _directionLabel.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:_directionLabel];
        
        _estimationContainer = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 0, 105.0, self.contentView.bounds.size.height)];
        _estimationContainer.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:_estimationContainer];
        
        _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 9.0, 105.0, 20.0)];
        _distanceLabel.font = [UIFont systemFontOfSize:17.0];
        _distanceLabel.textColor = [UIColor whiteColor];
        _distanceLabel.backgroundColor = [UIColor blackColor];
        [_estimationContainer addSubview:_distanceLabel];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 29.0, 105.0, 14.0)];
        _timeLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.alpha = 0.5;
        _timeLabel.backgroundColor = [UIColor blackColor];
        [_estimationContainer addSubview:_timeLabel];
        
        _noInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 0, 105.0, self.contentView.bounds.size.height)];
        _noInfoLabel.font = [UIFont italicSystemFontOfSize:13.0];
        _noInfoLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
        _noInfoLabel.text = NSLocalizedString(@"NO_INFO", nil);
        _noInfoLabel.numberOfLines = 0;
        _noInfoLabel.backgroundColor = [UIColor blackColor];
        
        _toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _toggleButton.frame = CGRectMake(200.0, 0, 105.0, self.contentView.bounds.size.height);
        [_toggleButton addTarget:self action:@selector(estimationsTapped) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
        [_toggleButton addTarget:self action:@selector(toggleEstimations) forControlEvents:UIControlEventTouchUpInside];
        [_toggleButton addTarget:self action:@selector(estimationsTapCancelled) forControlEvents:UIControlEventTouchCancel|UIControlEventTouchDragExit];
        
        _estimationIndicators = [CALayer new];
        _estimationIndicators.frame = CGRectMake(200.0, 0, 10.0, self.contentView.bounds.size.height);
        
        CALayer *indicator1 = [CALayer new];
        indicator1.frame = CGRectMake(0, 16, 6.0, 6.0);
        indicator1.cornerRadius = 3.0;
        indicator1.borderColor = [UIColor colorWithHue:130.0/360.0 saturation:0.9 brightness:0.9 alpha:1].CGColor;
        indicator1.borderWidth = 0.5;
        [_estimationIndicators addSublayer:indicator1];
        
        CALayer *indicator2 = [CALayer new];
        indicator2.frame = CGRectMake(0, 30, 6.0, 6.0);
        indicator2.cornerRadius = 3.0;
        indicator2.borderColor = [UIColor colorWithHue:130.0/360.0 saturation:0.9 brightness:0.9 alpha:1].CGColor;
        indicator2.borderWidth = 0.5;
        [_estimationIndicators addSublayer:indicator2];
        
        _currentIndicator = [CALayer new];
        _currentIndicator.frame = CGRectMake(0, indicator1.frame.origin.y, 6.0, 6.0);
        _currentIndicator.cornerRadius = 3.0;
        _currentIndicator.backgroundColor = [UIColor colorWithHue:130.0/360.0 saturation:0.9 brightness:0.9 alpha:1].CGColor;
        [_estimationIndicators addSublayer:_currentIndicator];
    }
    return self;
}

- (void)setEstimations:(NSArray *)estimations
{
    _estimations = estimations;
    
    [self.estimationIndicators removeFromSuperlayer];
    [self.toggleButton removeFromSuperview];
    self.distanceLabel.textColor = [UIColor whiteColor];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.estimationContainer.frame = CGRectMake(200.0, 0, 105.0, self.contentView.bounds.size.height);
    
    if (estimations.count == 0) {
        self.distanceLabel.text = @"";
        self.timeLabel.text = @"";
        [self.contentView addSubview:self.noInfoLabel];
    } else {
        [self.noInfoLabel removeFromSuperview];
        self.distanceLabel.text = [[estimations firstObject] objectForKey:@"distance"];
        self.timeLabel.text = [[estimations firstObject] objectForKey:@"eta"];
    }
    
    if (estimations.count > 1) {
        [self.contentView.layer addSublayer:self.estimationIndicators];
        [self.contentView addSubview:self.toggleButton];
        self.estimationContainer.frame = CGRectMake(213.0, 0, 90.0, self.contentView.bounds.size.height);
        [UIView animateWithDuration:0.1 animations:^{
            self.currentIndicator.frame = CGRectMake(0, 16.0, self.currentIndicator.bounds.size.width, self.currentIndicator.bounds.size.height);
        }];
//        self.distanceLabel.textColor = self.tintColor;
//        self.timeLabel.textColor = self.tintColor;
    }
}

- (void)estimationsTapped
{
    [UIView animateWithDuration:0.1 animations:^{
        self.estimationContainer.alpha = 0.5;
    }];
}

- (void)estimationsTapCancelled
{
    [UIView animateWithDuration:0.1 animations:^{
        self.estimationContainer.alpha = 1;
    }];
}

- (void)toggleEstimations
{
    NSString *firstEstimationDistance = [[self.estimations firstObject] objectForKey:@"distance"];
    NSString *firstEstimationTime = [[self.estimations firstObject] objectForKey:@"eta"];
    NSString *secondEstimationDistance = [[self.estimations lastObject] objectForKey:@"distance"];
    NSString *secondEstimationTime = [[self.estimations lastObject] objectForKey:@"eta"];
    
    [UIView animateWithDuration:0.1 animations:^{
        self.estimationContainer.alpha = 0;
    } completion:^(BOOL finished) {
        CGFloat indicatorY = 0;
        
        if ([self.distanceLabel.text isEqualToString:firstEstimationDistance]
            && [self.timeLabel.text isEqualToString:firstEstimationTime]) {
            self.distanceLabel.text = secondEstimationDistance;
            self.timeLabel.text = secondEstimationTime;
            indicatorY = 30.0;
        } else {
            self.distanceLabel.text = firstEstimationDistance;
            self.timeLabel.text = firstEstimationTime;
            indicatorY = 16.0;
        }
        
        [UIView animateWithDuration:0.1 animations:^{
            self.estimationContainer.alpha = 1;
            self.currentIndicator.frame = CGRectMake(0, indicatorY, self.currentIndicator.bounds.size.width, self.currentIndicator.bounds.size.height);
        }];
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [self.estimationIndicators removeFromSuperlayer];
    [self.toggleButton removeFromSuperview];
    [self.noInfoLabel removeFromSuperview];
    self.distanceLabel.textColor = [UIColor whiteColor];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.estimationContainer.frame = CGRectMake(200.0, 0, 105.0, self.contentView.bounds.size.height);
}

@end
