//
//  CFResultCell.m
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFResultCell.h"
#import "CFClipView.h"
#import "CFColorBadgeView.h"

#define SECOND_ESTIMATION_ALPHA 0.35

@interface CFResultCell () <UIScrollViewDelegate>

@property (nonatomic, strong) CFClipView *estimationContainer;
@property (nonatomic, strong) CFColorBadgeView *colorBadge;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *distanceLabel;
@property (nonatomic, strong) UILabel *secondTimeLabel;
@property (nonatomic, strong) UILabel *secondDistanceLabel;
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
        self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.contentView.bounds.size.width, 60.0);
        
        CALayer *separatorLayer = [CALayer new];
        separatorLayer.frame = CGRectMake(0, self.contentView.bounds.size.height - 0.5, self.contentView.bounds.size.width, 0.5);
        separatorLayer.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1].CGColor;
        [self.layer insertSublayer:separatorLayer above:self.contentView.layer];
        
        _colorBadge = [[CFColorBadgeView alloc] initWithFrame:CGRectMake(0, 0, 10.0, 10.0)];
        [self.contentView addSubview:_colorBadge];
        
        _serviceLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 80.0, 25.0)];
        _serviceLabel.textColor = [UIColor whiteColor];
        _serviceLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25.0];
        _serviceLabel.backgroundColor = [UIColor blackColor];
        
        _directionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 35.0, 110.0, 17.0)];
        _directionLabel.font = [UIFont systemFontOfSize:11.0];
        _directionLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        _directionLabel.numberOfLines = 1;
        _directionLabel.backgroundColor = [UIColor blackColor];
        
        _estimationContainer = [[CFClipView alloc] initWithFrame:CGRectMake(110.0, 0, 185.0, self.contentView.bounds.size.height)];
        _estimationContainer.backgroundColor = [UIColor blackColor];
        _estimationContainer.scrollView.frame = CGRectMake(50.0, 0, 95.0, self.contentView.bounds.size.height);
        _estimationContainer.scrollView.delegate = self;
        _estimationContainer.scrollView.contentSize = CGSizeMake(_estimationContainer.scrollView.bounds.size.width, _estimationContainer.bounds.size.height);
        _estimationContainer.scrollView.pagingEnabled = YES;
        _estimationContainer.scrollView.showsHorizontalScrollIndicator = NO;
        _estimationContainer.scrollView.clipsToBounds = NO;
        _estimationContainer.scrollView.alwaysBounceHorizontal = YES;
        _estimationContainer.clipsToBounds = YES;
        [self.contentView addSubview:_estimationContainer];
        [self.contentView addSubview:_serviceLabel];
        [self.contentView addSubview:_directionLabel];
        
        _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 12.0, _estimationContainer.scrollView.bounds.size.width, 20.0)];
        _distanceLabel.font = [UIFont systemFontOfSize:20.0];
        _distanceLabel.textColor = [UIColor whiteColor];
        _distanceLabel.backgroundColor = [UIColor blackColor];
        [_estimationContainer.scrollView addSubview:_distanceLabel];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35.0, _estimationContainer.scrollView.bounds.size.width, 14.0)];
        _timeLabel.font = [UIFont boldSystemFontOfSize:14.0];
        _timeLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
        _timeLabel.alpha = 1;
        _timeLabel.backgroundColor = [UIColor blackColor];
        [_estimationContainer.scrollView addSubview:_timeLabel];
        
        _secondDistanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(_estimationContainer.scrollView.bounds.size.width, _distanceLabel.frame.origin.y, _estimationContainer.bounds.size.width, _distanceLabel.bounds.size.height)];
        _secondDistanceLabel.font = _distanceLabel.font;
        _secondDistanceLabel.textColor = _distanceLabel.textColor;
        _secondDistanceLabel.alpha = SECOND_ESTIMATION_ALPHA;
        _secondDistanceLabel.backgroundColor = _distanceLabel.backgroundColor;
        
        _secondTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_estimationContainer.scrollView.bounds.size.width, _timeLabel.frame.origin.y, _estimationContainer.bounds.size.width, _timeLabel.bounds.size.height)];
        _secondTimeLabel.font = _timeLabel.font;
        _secondTimeLabel.textColor = _timeLabel.textColor;
        _secondTimeLabel.alpha = SECOND_ESTIMATION_ALPHA;
        _secondTimeLabel.backgroundColor = _timeLabel.backgroundColor;
        
        _noInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(160.0, 0, 125.0, self.contentView.bounds.size.height)];
        _noInfoLabel.font = [UIFont italicSystemFontOfSize:15.0];
        _noInfoLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
        _noInfoLabel.text = NSLocalizedString(@"NO_INFO", nil);
        _noInfoLabel.numberOfLines = 0;
        _noInfoLabel.backgroundColor = [UIColor blackColor];
        
        _toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _toggleButton.frame = _estimationContainer.frame;
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
    
    self.estimationContainer.scrollView.contentSize = CGSizeMake(self.estimationContainer.scrollView.bounds.size.width, self.estimationContainer.bounds.size.height);
    [self.secondDistanceLabel removeFromSuperview];
    [self.secondTimeLabel removeFromSuperview];
    [self.toggleButton removeFromSuperview];
    
    if (estimations.count == 0) {
        [self.estimationContainer removeFromSuperview];
        [self.contentView addSubview:self.noInfoLabel];
    } else {
        [self.noInfoLabel removeFromSuperview];
        if (!self.estimationContainer.superview) [self.contentView addSubview:self.estimationContainer];
        self.distanceLabel.text = [[estimations firstObject] objectForKey:@"distance"];
        self.timeLabel.text = [[estimations firstObject] objectForKey:@"eta"];
    }
    
    if (estimations.count > 1) {
        self.estimationContainer.scrollView.contentSize = CGSizeMake(self.estimationContainer.scrollView.bounds.size.width * 2, self.estimationContainer.bounds.size.height);
        [self.estimationContainer.scrollView addSubview:self.secondDistanceLabel];
        [self.estimationContainer.scrollView addSubview:self.secondTimeLabel];
        
        self.secondDistanceLabel.text = [[estimations lastObject] objectForKey:@"distance"];
        self.secondTimeLabel.text = [[estimations lastObject] objectForKey:@"eta"];
//        [self.contentView.layer addSublayer:self.estimationIndicators];
//        self.estimationContainer.frame = CGRectMake(213.0, 0, 90.0, self.contentView.bounds.size.height);
//        [UIView animateWithDuration:0.1 animations:^{
//            self.currentIndicator.frame = CGRectMake(0, 16.0, self.currentIndicator.bounds.size.width, self.currentIndicator.bounds.size.height);
//        }];
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
    [UIView animateWithDuration:0.1 animations:^{
        self.estimationContainer.alpha = 1;
        self.estimationContainer.scrollView.contentOffset = CGPointMake(self.estimationContainer.bounds.size.width, 0);
    } completion:^(BOOL finished) {
//        CGFloat indicatorY = 0;
//        
//        if ([self.distanceLabel.text isEqualToString:firstEstimationDistance]
//            && [self.timeLabel.text isEqualToString:firstEstimationTime]) {
//            indicatorY = 30.0;
//        } else {
//            indicatorY = 16.0;
//        }
//        
//        [UIView animateWithDuration:0.1 animations:^{
//            self.estimationContainer.alpha = 1;
//            self.currentIndicator.frame = CGRectMake(0, indicatorY, self.currentIndicator.bounds.size.width, self.currentIndicator.bounds.size.height);
//        }];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGFloat pageWidth = self.estimationContainer.scrollView.frame.size.width;
    int page = floor((self.estimationContainer.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    [UIView animateWithDuration:0.1 animations:^{
        if (page == 1) {
            self.secondDistanceLabel.alpha = 1;
            self.secondTimeLabel.alpha = 1;
            self.distanceLabel.alpha = SECOND_ESTIMATION_ALPHA;
            self.timeLabel.alpha = SECOND_ESTIMATION_ALPHA;
        } else {
            self.distanceLabel.alpha = 1;
            self.timeLabel.alpha = 1;
            self.secondDistanceLabel.alpha = SECOND_ESTIMATION_ALPHA;
            self.secondTimeLabel.alpha = SECOND_ESTIMATION_ALPHA;
        }
    }];
}

- (void)setBadgeColor:(UIColor *)badgeColor
{
    _badgeColor = badgeColor;
    
    self.colorBadge.badgeColor = badgeColor;
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
    [self.secondDistanceLabel removeFromSuperview];
    [self.secondTimeLabel removeFromSuperview];
    [self.noInfoLabel removeFromSuperview];
}

@end
