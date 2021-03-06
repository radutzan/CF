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
#import <Social/Social.h>

#define SECOND_ESTIMATION_ALPHA 0.35

@interface CFResultCell () <UIScrollViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) CFClipView *estimationContainer;
@property (nonatomic, strong) CFColorBadgeView *colorBadge;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *distanceLabel;
@property (nonatomic, strong) UILabel *secondTimeLabel;
@property (nonatomic, strong) UILabel *secondDistanceLabel;
@property (nonatomic, strong) UIView *noInfoView;
@property (nonatomic, strong) UIButton *noInfoButton;
@property (nonatomic, strong) UILabel *noInfoLabel;
@property (nonatomic, strong) CALayer *selectionVeilLayer;
@property (nonatomic, strong) CALayer *separatorLayer;

@end

@implementation CFResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.contentView.bounds.size.width, 60.0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.separatorLayer = [CALayer new];
        self.separatorLayer.frame = CGRectMake(0, self.contentView.bounds.size.height - 0.5, self.contentView.bounds.size.width, 0.5);
        self.separatorLayer.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1].CGColor;
        [self.layer insertSublayer:self.separatorLayer above:self.contentView.layer];
        
        _colorBadge = [[CFColorBadgeView alloc] initWithFrame:CGRectMake(0, 0, 10.0, 10.0)];
        [self.contentView addSubview:_colorBadge];
        
        _serviceLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 10.0, 80.0, 25.0)];
        _serviceLabel.textColor = [UIColor whiteColor];
        _serviceLabel.font = [UIFont systemFontOfSize:22];//fontWithName:@"AvenirNext-Regular" size:24.0];
        _serviceLabel.backgroundColor = [UIColor blackColor];
        
        _directionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 33.0, 100.0, 17.0)];
        _directionLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];//fontWithName:@"AvenirNextCondensed-Medium" size:12.0];
        _directionLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        _directionLabel.numberOfLines = 1;
        _directionLabel.backgroundColor = [UIColor blackColor];
        
        _estimationContainer = [[CFClipView alloc] initWithFrame:CGRectMake(90.0, 0, self.bounds.size.width - 115.0, self.contentView.bounds.size.height)];
        _estimationContainer.backgroundColor = [UIColor blackColor];
        _estimationContainer.scrollView.frame = CGRectMake(50.0, 0, 95.0, self.contentView.bounds.size.height);
        _estimationContainer.scrollView.delegate = self;
        _estimationContainer.scrollView.contentSize = CGSizeMake(_estimationContainer.scrollView.bounds.size.width, _estimationContainer.bounds.size.height);
        _estimationContainer.scrollView.pagingEnabled = YES;
        _estimationContainer.scrollView.showsHorizontalScrollIndicator = NO;
        _estimationContainer.scrollView.clipsToBounds = NO;
        _estimationContainer.scrollView.alwaysBounceHorizontal = YES;
        _estimationContainer.scrollView.backgroundColor = [UIColor blackColor];
        _estimationContainer.clipsToBounds = YES;
        [self.contentView addSubview:_estimationContainer];
        [self.contentView addSubview:_serviceLabel];
        [self.contentView addSubview:_directionLabel];
        
        _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 11.0, _estimationContainer.scrollView.bounds.size.width, 20.0)];
        _distanceLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];//fontWithName:@"AvenirNext-Regular" size:20.0];
        _distanceLabel.textColor = [UIColor whiteColor];
        _distanceLabel.backgroundColor = [UIColor blackColor];
        _distanceLabel.userInteractionEnabled = NO;
        [_estimationContainer.scrollView addSubview:_distanceLabel];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 34.0, _estimationContainer.scrollView.bounds.size.width, 14.0)];
        _timeLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];//fontWithName:@"AvenirNextCondensed-DemiBold" size:14.0];
        _timeLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
        _timeLabel.alpha = 1;
        _timeLabel.backgroundColor = [UIColor blackColor];
        _timeLabel.userInteractionEnabled = NO;
        [_estimationContainer.scrollView addSubview:_timeLabel];
        
        _secondDistanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(_estimationContainer.scrollView.bounds.size.width, _distanceLabel.frame.origin.y, _distanceLabel.bounds.size.width, _distanceLabel.bounds.size.height)];
        _secondDistanceLabel.font = _distanceLabel.font;
        _secondDistanceLabel.textColor = _distanceLabel.textColor;
        _secondDistanceLabel.alpha = SECOND_ESTIMATION_ALPHA;
        _secondDistanceLabel.backgroundColor = _distanceLabel.backgroundColor;
        
        _secondTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_estimationContainer.scrollView.bounds.size.width, _timeLabel.frame.origin.y, _timeLabel.bounds.size.width, _timeLabel.bounds.size.height)];
        _secondTimeLabel.font = _timeLabel.font;
        _secondTimeLabel.textColor = _timeLabel.textColor;
        _secondTimeLabel.alpha = SECOND_ESTIMATION_ALPHA;
        _secondTimeLabel.backgroundColor = _timeLabel.backgroundColor;
        
        _noInfoView = [[UIView alloc] initWithFrame:CGRectMake(140.0, 0, 125.0, self.contentView.bounds.size.height)];
        
        _noInfoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        _noInfoButton.center = CGPointMake(_noInfoButton.center.x, _noInfoView.center.y);
        [_noInfoButton addTarget:self action:@selector(noInfoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_noInfoView addSubview:_noInfoButton];
        
        _noInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(30.0, 0, 90.0, self.contentView.bounds.size.height)];
        _noInfoLabel.font = [UIFont italicSystemFontOfSize:13];//fontWithName:@"AvenirNextCondensed-Italic" size:15.0];
        _noInfoLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
        _noInfoLabel.text = NSLocalizedString(@"NO_INFO", nil);
        _noInfoLabel.numberOfLines = 0;
        _noInfoLabel.backgroundColor = [UIColor blackColor];
        [_noInfoView addSubview:_noInfoLabel];
        
        _selectionVeilLayer = [CALayer layer];
        _selectionVeilLayer.frame = self.contentView.bounds;
        _selectionVeilLayer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
        _selectionVeilLayer.hidden = YES;
        [self.layer addSublayer:_selectionVeilLayer];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.separatorLayer.frame = CGRectMake(0, self.bounds.size.height - 0.5, self.bounds.size.width, 0.5);
    self.selectionVeilLayer.frame = self.bounds;
    self.estimationContainer.frame = CGRectMake(90.0, 0, self.bounds.size.width - 115.0, self.contentView.bounds.size.height);
    
    BOOL bigAssPhone = self.bounds.size.width > 305.0;
    
    if (bigAssPhone) {
        self.estimationContainer.gradientLayer.hidden = YES;
        self.estimationContainer.scrollView.scrollEnabled = NO;
        self.estimationContainer.scrollView.frame = CGRectMake(50.0, 0, self.estimationContainer.bounds.size.width - 50.0, self.contentView.bounds.size.height);
        self.secondDistanceLabel.alpha = SECOND_ESTIMATION_ALPHA * 1.8;
        self.secondTimeLabel.alpha = SECOND_ESTIMATION_ALPHA * 1.8;
    }
}

- (void)setEstimations:(NSArray *)estimations
{
    _estimations = estimations;
    
    self.estimationContainer.scrollView.contentSize = CGSizeMake(self.estimationContainer.scrollView.bounds.size.width, self.estimationContainer.bounds.size.height);
    [self.secondDistanceLabel removeFromSuperview];
    [self.secondTimeLabel removeFromSuperview];
    
    if (estimations.count == 0) {
        [self.estimationContainer removeFromSuperview];
        [self.contentView addSubview:self.noInfoView];
    } else {
        [self.noInfoView removeFromSuperview];
        if (!self.estimationContainer.superview) [self.contentView addSubview:self.estimationContainer];
        
        [self.contentView sendSubviewToBack:self.estimationContainer];
        self.distanceLabel.text = [[estimations firstObject] objectForKey:@"distance"];
        self.timeLabel.text = [[[estimations firstObject] objectForKey:@"eta"] stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
    
    if (estimations.count > 1) {
        self.estimationContainer.scrollView.contentSize = CGSizeMake(self.estimationContainer.scrollView.bounds.size.width * 2, self.estimationContainer.bounds.size.height);
        [self.estimationContainer.scrollView addSubview:self.secondDistanceLabel];
        [self.estimationContainer.scrollView addSubview:self.secondTimeLabel];
        
        self.secondDistanceLabel.text = [[estimations lastObject] objectForKey:@"distance"];
        self.secondTimeLabel.text = [[[estimations lastObject] objectForKey:@"eta"] stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
}

- (void)setNoEstimationReason:(NSString *)noEstimationReason
{
    _noEstimationReason = noEstimationReason;
    
    if (noEstimationReason) {
        self.noInfoLabel.text = noEstimationReason;
        self.noInfoLabel.frame = CGRectMake(0, 0, 120.0, self.contentView.bounds.size.height);
        self.noInfoButton.hidden = YES;
    } else {
        self.noInfoLabel.text = NSLocalizedString(@"NO_INFO", nil);
        self.noInfoLabel.frame = CGRectMake(30.0, 0, 90.0, self.contentView.bounds.size.height);
        self.noInfoButton.hidden = NO;
    }
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

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        self.selectionVeilLayer.hidden = NO;
    } else {
        self.selectionVeilLayer.hidden = YES;
    }
}

- (void)noInfoButtonTapped
{
    NSString *complainButtonTitle = nil;
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        complainButtonTitle = NSLocalizedString(@"NO_INFO_BUTTON_COMPLAIN", nil);
    }
    
    UIAlertView *noData = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO_INFO_TITLE", nil) message:NSLocalizedString(@"NO_INFO_MESSAGE", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"DISMISS", nil) otherButtonTitles:complainButtonTitle, nil];
    [noData show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self.delegate sendComplaintTweetForService:self.serviceLabel.text];
    }
}

- (void)prepareForReuse
{
    [self.secondDistanceLabel removeFromSuperview];
    [self.secondTimeLabel removeFromSuperview];
    [self.noInfoView removeFromSuperview];
}

@end
