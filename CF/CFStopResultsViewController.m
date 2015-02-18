//
//  CFStopResultsViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/17/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Social/Social.h>

#import <Mixpanel/Mixpanel.h>
#import <OLGhostAlertView/OLGhostAlertView.h>

#import "CFStopResultsViewController.h"
#import "CFSapoClient.h"
#import "OLCashier.h"

#import "CFStopSignView.h"
#import "CFResultCell.h"
#import "OLShapeTintedButton.h"
#import "CFTransparentView.h"
#import "UIImage+Star.h"

#import <GoogleMobileAds/GADBannerView.h>

@interface CFStopResultsViewController () <CFStopSignViewDelegate, UIAlertViewDelegate, CFResultCellDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, GADBannerViewDelegate>

@property (nonatomic, strong) UIView *stopResultsView;
@property (nonatomic, assign, readwrite) CFStopResultsDisplayMode displayMode;
@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) CFStopSignView *stopInfoView;
@property (nonatomic, strong) OLShapeTintedButton *favoriteButton;
@property (nonatomic, strong) UIActivityIndicatorView *titleActivityIndicatorView;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSMutableArray *responseEstimation;
@property (nonatomic, strong) NSMutableArray *responseWithoutEstimation;
@property (nonatomic, strong) NSMutableArray *finalData;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UILabel *timerLabel;
@property (nonatomic, assign) NSUInteger timerCount;
@property (nonatomic, assign) BOOL refreshing;

@property (nonatomic, assign) CGPoint stopResultsViewPresentedCenter;
@property (nonatomic, assign) CGRect stopResultsViewPresentedFrame;
@property (nonatomic, assign) CGRect stopResultsViewMinimizedFrame;
@property (nonatomic, assign) CGPoint stopResultsViewStoredCenter;

@property (nonatomic, strong) GADBannerView *bannerView;
@property (nonatomic, assign) BOOL removedAds;
@property (nonatomic, assign) BOOL showingAds;

@end

@implementation CFStopResultsViewController

UIPanGestureRecognizer *_horizontalPanRecognizer;
UIScreenEdgePanGestureRecognizer *_edgePanRecognizer;
UITapGestureRecognizer *_overlayTap;
UIPanGestureRecognizer *_overlayPan;
UITapGestureRecognizer *_titleBarTap;
UITapGestureRecognizer *_titleBarDoubleTap;
UIPanGestureRecognizer *_titleBarPan;
CALayer *_topGripper;
CALayer *_leftGripper;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _responseEstimation = [NSMutableArray new];
        _responseWithoutEstimation = [NSMutableArray new];
        _finalData = [NSMutableArray new];
        
        _removedAds = ([OLCashier hasProduct:@"CF01"] || [OLCashier hasProduct:@"CF02"]);
        _displayMode = CFStopResultsDisplayModeNone;
    }
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    screenBounds.size.height -= [UIApplication sharedApplication].statusBarFrame.size.height - 20.0;
    self.view = [[CFTransparentView alloc] initWithFrame:screenBounds];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    self.overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:.42];
    [self.view addSubview:self.overlay];
    
    if (NSClassFromString(@"UIVisualEffectView")) {
        self.stopResultsView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        self.stopResultsView.frame = self.stopResultsViewPresentedFrame;
    } else {
        self.stopResultsView = [[UIToolbar alloc] initWithFrame:self.stopResultsViewPresentedFrame];
        UIToolbar *castedStopResultsView = (UIToolbar *)self.stopResultsView;
        castedStopResultsView.barStyle = UIBarStyleBlack;
        self.stopResultsView.backgroundColor = [UIColor colorWithWhite:0 alpha:.5];
    }
    self.stopResultsView.layer.cornerRadius = 6.0;
    self.stopResultsView.layer.masksToBounds = YES;
    self.stopResultsView.layer.borderWidth = 0.5;
    self.stopResultsView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
    [self.view addSubview:self.stopResultsView];
    
    CGFloat motionEffectHorizontalOffset = MOTION_EFFECTS_HORIZONTAL_OFFSET / 2;
    CGFloat motionEffectVerticalOffset = MOTION_EFFECTS_VERTICAL_OFFSET / 2;
    
    UIInterpolatingMotionEffect *stopHorizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    stopHorizontalMotionEffect.minimumRelativeValue = [NSNumber numberWithFloat:-motionEffectHorizontalOffset];
    stopHorizontalMotionEffect.maximumRelativeValue = [NSNumber numberWithFloat:motionEffectHorizontalOffset];
    [self.stopResultsView addMotionEffect:stopHorizontalMotionEffect];
    
    UIInterpolatingMotionEffect *stopVerticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    stopVerticalMotionEffect.minimumRelativeValue = [NSNumber numberWithFloat:-motionEffectVerticalOffset];
    stopVerticalMotionEffect.maximumRelativeValue = [NSNumber numberWithFloat:motionEffectVerticalOffset];
    [self.stopResultsView addMotionEffect:stopVerticalMotionEffect];
    
    self.stopResultsViewPresentedCenter = self.stopResultsView.center;
    
    CGRect titleViewFrame = CGRectMake(0, 0, self.stopResultsView.bounds.size.width, 54.0);
    
    if (NSClassFromString(@"UIVisualEffectView")) {
        self.titleView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        self.titleView.frame = titleViewFrame;
    } else {
        self.titleView = [[UINavigationBar alloc] initWithFrame:titleViewFrame];
        UINavigationBar *titleViewAsNavBar = (UINavigationBar *)self.titleView;
        titleViewAsNavBar.barStyle = UIBarStyleBlack;
    }
    
    self.stopInfoView = [[CFStopSignView alloc] initWithFrame:CGRectMake(0.0, 0.0, titleViewFrame.size.width - 33.0, titleViewFrame.size.height)];
    self.stopInfoView.delegate = self;
    self.stopInfoView.stopCodeLabel.hidden = YES;
#ifdef DEV_VERSION
//    self.stopInfoView.stopCodeLabel.hidden = NO;
#endif
    self.stopInfoView.favoriteContentView.userInteractionEnabled = YES;
    
    CGSize starImageSize = CGSizeMake(27.0, 27.0);
    self.favoriteButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    self.favoriteButton.frame = CGRectMake(self.titleView.bounds.size.width - 38.0, (self.titleView.bounds.size.height - 42.0) / 2, 42.0, 42.0);
    self.favoriteButton.enabled = NO;
    [self.favoriteButton setImage:[UIImage starImageWithSize:starImageSize filled:NO] forState:UIControlStateNormal];
    [self.favoriteButton setImage:[UIImage starImageWithSize:starImageSize filled:YES] forState:UIControlStateSelected];
    [self.favoriteButton addTarget:self action:@selector(favButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.titleActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.titleActivityIndicatorView.center = self.favoriteButton.center;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.stopResultsView.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.contentInset = UIEdgeInsetsMake(self.titleView.bounds.size.height, 0, 0, 0);
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.stopResultsView insertSubview:self.tableView belowSubview:self.titleView];
    
    self.bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
    self.bannerView.rootViewController = self;
    self.bannerView.adUnitID = @"ca-app-pub-6226087428684107/3340545274";
    self.bannerView.delegate = self;
    self.bannerView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 50);
    [self.view insertSubview:self.bannerView aboveSubview:self.overlay];
    [self requestAds];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.stopResultsView addSubview:self.titleView];
    [self.titleView addSubview:self.stopInfoView];
    [self.titleView addSubview:self.favoriteButton];
    [self.titleView addSubview:self.titleActivityIndicatorView];
    [self.titleActivityIndicatorView startAnimating];
    
    self.refreshControl = [UIRefreshControl new];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(performStopRequestQuietly:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.stopResultsView.bounds.size.width - 100.0 - 15.0, 0, 100.0, 20.0)];
    self.timerLabel.font = [UIFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
    self.timerLabel.alpha = 0.5;
    self.timerLabel.textAlignment = NSTextAlignmentRight;
    self.timerLabel.text = NSLocalizedString(@"REFRESHING", nil);
    
    [self initGestures];
}

- (void)initGestures
{
    _horizontalPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalPanGesture:)];
    [_horizontalPanRecognizer requireGestureRecognizerToFail:self.tableView.panGestureRecognizer];
    _horizontalPanRecognizer.delegate = self;
    [self.stopResultsView addGestureRecognizer:_horizontalPanRecognizer];
    
    _edgePanRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalPanGesture:)];
    _edgePanRecognizer.edges = UIRectEdgeLeft|UIRectEdgeRight;
    [self.view addGestureRecognizer:_edgePanRecognizer];
    
    _overlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [self.overlay addGestureRecognizer:_overlayTap];
    
    _overlayPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalPanGesture:)];
    [self.overlay addGestureRecognizer:_overlayPan];
    
    _titleBarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expand)];
    [self.titleView addGestureRecognizer:_titleBarTap];
    
    _titleBarDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(minimize)];
    _titleBarDoubleTap.numberOfTapsRequired = 2;
    [self.titleView addGestureRecognizer:_titleBarDoubleTap];
    
    _titleBarPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleVerticalPanGesture:)];
    [_titleBarPan requireGestureRecognizerToFail:_horizontalPanRecognizer];
    [self.titleView addGestureRecognizer:_titleBarPan];
    
    // set up grippers
    CGFloat gripperThickness = 3.0;
    CGFloat gripperLength = 24.0;
    CGFloat gripperDistance = 3.5;
    UIColor *gripperColor = [UIColor colorWithWhite:1 alpha:.35];
    
    _topGripper = [CALayer layer];
    _topGripper.frame = CGRectMake(self.titleView.center.x - gripperLength / 2, gripperDistance, gripperLength, gripperThickness);
    _topGripper.backgroundColor = gripperColor.CGColor;
    _topGripper.cornerRadius = gripperThickness / 2;
    _topGripper.opacity = 0;
    [self.titleView.layer addSublayer:_topGripper];
    
    _leftGripper = [CALayer layer];
    _leftGripper.frame = CGRectMake(gripperDistance, self.titleView.center.y - gripperLength / 2, gripperThickness, gripperLength);
    _leftGripper.backgroundColor = gripperColor.CGColor;
    _leftGripper.cornerRadius = gripperThickness / 2;
    _leftGripper.opacity = 0;
    [self.titleView.layer addSublayer:_leftGripper];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setUpTitleView];
    if (self.stop && !self.refreshing) [self performStopRequestQuietly:NO];
    
    if (!self.removedAds) [self.view insertSubview:self.bannerView aboveSubview:self.overlay];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self resetTimer];
    [self.view endEditing:YES];
    self.refreshing = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.bannerView removeFromSuperview];
}

- (void)viewWillLayoutSubviews
{
    if (self.displayMode == CFStopResultsDisplayModePresented) self.stopResultsView.frame = self.stopResultsViewPresentedFrame;
    
    if (self.displayMode == CFStopResultsDisplayModeMinimized) self.stopResultsView.frame = self.stopResultsViewMinimizedFrame;
}

- (void)statusBarFrameChanged:(NSNotification*)notification
{
    CGRect statusBarFrame = [notification.userInfo[UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
    CGRect windowBounds = [UIScreen mainScreen].bounds;
    windowBounds.size.height -= statusBarFrame.size.height - 20.0;
    self.view.frame = windowBounds;
    
    [self.view setNeedsLayout];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma mark - Presentation

- (void)setDisplayMode:(CFStopResultsDisplayMode)displayMode
{
    if (_displayMode == displayMode) return;
    
    BOOL promotedFromContainment = NO;
    if (_displayMode == CFStopResultsDisplayModeContained && displayMode != CFStopResultsDisplayModeNone) promotedFromContainment = YES;
    
    _displayMode = displayMode;
    
    if (promotedFromContainment) {
        [self.delegate stopResultsViewWasPromotedFromContainment];
        [self updateHistory];
    }
    
    if (displayMode == CFStopResultsDisplayModePresented) {
        self.favoriteButton.enabled = YES;
        self.stopInfoView.userInteractionEnabled = YES;
        _titleBarDoubleTap.enabled = YES;
        _titleBarTap.enabled = NO;
        _leftGripper.opacity = 1;
        _topGripper.opacity = 0;
    } else {
        self.favoriteButton.enabled = NO;
        self.stopInfoView.userInteractionEnabled = NO;
        _titleBarDoubleTap.enabled = NO;
        _titleBarTap.enabled = YES;
        _leftGripper.opacity = 0;
        _topGripper.opacity = 1;
        [self.view endEditing:YES];
    }
    
    if (displayMode == CFStopResultsDisplayModeContained) {
        _horizontalPanRecognizer.enabled = NO;
    } else {
        _horizontalPanRecognizer.enabled = YES;
    }
}

- (BOOL)addToParentViewController:(UIViewController *)parentViewController
{
    if (self.parentViewController) return NO;
    
    [parentViewController addChildViewController:self];
    [parentViewController.view addSubview:self.view];
    
    self.overlay.alpha = 0;
    
    return YES;
}

- (void)presentOnViewController:(UIViewController *)onViewController
{
    [self presentFromRect:CGRectZero onViewController:onViewController];
}

- (void)presentFromRect:(CGRect)rect onViewController:(UIViewController *)onViewController
{
    CGFloat initialVelocity = 1;
    
    if ([self addToParentViewController:onViewController]) {
        if (CGRectIsEmpty(rect)) {
            self.stopResultsView.alpha = 0;
            self.stopResultsView.frame = CGRectOffset(self.stopResultsViewPresentedFrame, 0, 40.0);
        } else {
            self.stopResultsView.frame = rect;
            initialVelocity = 0;
        }
    }
    
    [self expandWithVelocity:initialVelocity];
}

- (void)containOnRect:(CGRect)rect onViewController:(UIViewController *)onViewController
{
    BOOL viewIsFresh = NO;
    if ([self addToParentViewController:onViewController]) viewIsFresh = YES;
    
    self.displayMode = CFStopResultsDisplayModeContained;
    
    CGRect targetRect = CGRectMake(self.stopResultsView.frame.origin.x, rect.origin.y, self.stopResultsView.frame.size.width, rect.size.height);
    
    if (viewIsFresh) {
        self.stopResultsView.alpha = 0;
        self.stopResultsView.frame = CGRectOffset(targetRect, 0, -SEARCH_CARD_ANIMATION_OFFSET);
    }
    
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.overlay.alpha = 0;
        self.stopResultsView.alpha = 1;
        self.stopResultsView.frame = targetRect;
    } completion:^(BOOL finished) {
    }];
}

- (void)expand
{
    [self expandWithVelocity:0];
}

- (void)expandWithVelocity:(CGFloat)velocity
{
    if (!self.parentViewController) return;
    
    self.displayMode = CFStopResultsDisplayModePresented;
    
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:velocity options:0 animations:^{
        self.overlay.alpha = 1;
        self.stopResultsView.alpha = 1;
        self.stopResultsView.frame = self.stopResultsViewPresentedFrame;
        if (!self.removedAds && self.showingAds) [self showAds];
    } completion:^(BOOL finished) {
//        Mixpanel *mixpanel = [Mixpanel sharedInstance];
//        [mixpanel track:@"Expanded Stop"];
    }];
}

- (void)minimize
{
    if (!self.parentViewController) return;
    
    self.displayMode = CFStopResultsDisplayModeMinimized;
    
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:1 options:0 animations:^{
        self.overlay.alpha = 0;
        self.stopResultsView.frame = self.stopResultsViewMinimizedFrame;
        [self hideAds];
    } completion:^(BOOL finished) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Minimized Stop"];
    }];
}

- (void)dismiss
{
    [self dismissFromCenter:CGPointZero withVelocityFactor:0.0];
}

- (void)dismissFromCenter:(CGPoint)center withVelocityFactor:(CGFloat)velocityFactor
{
    CGFloat animationDuration = 0.45 * (1 - velocityFactor);
    [self resetTimer];
    
    [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:velocityFactor options:0 animations:^{
        self.overlay.alpha = 0;
        [self hideAds];
        if (self.displayMode == CFStopResultsDisplayModeContained) {
            self.stopResultsView.center = CGPointMake(self.stopResultsView.center.x, self.stopResultsView.center.y - SEARCH_CARD_ANIMATION_OFFSET);
            self.stopResultsView.alpha = 0;
        } else {
            self.stopResultsView.center = CGPointMake(self.stopResultsView.center.x + self.view.bounds.size.width, self.stopResultsView.center.y);
        }
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        self.stopResultsView.alpha = 1;
        self.stopResultsView.frame = self.stopResultsViewPresentedFrame;
        self.displayMode = CFStopResultsDisplayModeNone;
    }];
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint velocity = [panGestureRecognizer velocityInView:self.view];
    return fabs(velocity.x) > fabs(velocity.y);
}

- (void)handleHorizontalPanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGFloat draggableDistance = self.view.bounds.size.width;
    CGFloat moveDiff = [recognizer translationInView:self.stopResultsView].x;
    
    CGFloat dragFactor = moveDiff / draggableDistance;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.view endEditing:YES];
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (moveDiff >= 0) {
            // moving to the right
            self.stopResultsView.center = CGPointMake(self.stopResultsViewPresentedCenter.x + moveDiff, self.stopResultsView.center.y);
            if (self.displayMode == CFStopResultsDisplayModePresented) {
                self.overlay.alpha = 1.0 - fabs(dragFactor);
                self.bannerView.alpha = self.overlay.alpha;
                [self positionAd:self.overlay.alpha];
            }
        } else {
            self.stopResultsView.center = CGPointMake(self.stopResultsViewPresentedCenter.x + moveDiff * 0.25, self.stopResultsView.center.y);
        }
        
    } else {
        CGFloat terminalVelocity = MIN([recognizer velocityInView:self.view].x, 3500);
        CGFloat velocityFactor = fabs(terminalVelocity / 3500);
        
        if (terminalVelocity > 250 || moveDiff > 80) {
            [self dismissFromCenter:self.stopResultsView.center withVelocityFactor:velocityFactor];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Used Stop Dismiss Gesture"];
        } else {
            [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:velocityFactor options:0 animations:^{
                self.stopResultsView.center = CGPointMake(self.stopResultsViewPresentedCenter.x, self.stopResultsView.center.y);
                if (self.displayMode == CFStopResultsDisplayModePresented) {
                    self.overlay.alpha = 1;
                    [self showAds];
                }
            } completion:nil];
        }
    }
}

- (void)handleVerticalPanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGFloat draggableDistance = self.stopResultsViewPresentedFrame.size.height;
    CGFloat moveDiff = [recognizer translationInView:self.view].y;
    
    CGFloat dragFactor = moveDiff / draggableDistance;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.stopResultsViewStoredCenter = self.stopResultsView.center;
        [self.view endEditing:YES];
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        self.stopResultsView.center = CGPointMake(self.stopResultsView.center.x, self.stopResultsViewStoredCenter.y + moveDiff);
        if (self.displayMode == CFStopResultsDisplayModePresented) {
            self.overlay.alpha = 1.0 - fabs(dragFactor);
        } else {
            self.overlay.alpha = fabs(dragFactor);
        }
        [self positionAd:self.overlay.alpha];
        
    } else {
        CGFloat terminalVelocity = MIN([recognizer velocityInView:self.view].y, 3500);
        CGFloat velocityFactor = fabs(terminalVelocity / 3500);
        CGFloat targetVelocity = 400;
        CGFloat targetDiff = 120;
        
        if (self.displayMode == CFStopResultsDisplayModePresented) {
            if (terminalVelocity > targetVelocity || moveDiff > targetDiff) {
                [self minimize];
            } else {
                [self expandWithVelocity:velocityFactor];
            }
        } else if (self.displayMode == CFStopResultsDisplayModeMinimized) {
            if (terminalVelocity < -targetVelocity || moveDiff < -targetDiff) {
                [self expandWithVelocity:velocityFactor];
            } else {
                [self minimize];
            }
        } else if (self.displayMode == CFStopResultsDisplayModeContained) {
            [self expandWithVelocity:velocityFactor];
        }
    }
}

- (CGRect)stopResultsViewPresentedFrame
{
    CGFloat adOffset = (self.showingAds) ? 50.0 : 0;
    
    CGFloat stopResultsViewWidth = self.view.bounds.size.width - 20.0;
    stopResultsViewWidth = MIN(MAX_OVERLAY_WIDTH, stopResultsViewWidth);
    CGFloat stopResultsViewHeight = self.view.bounds.size.height - 35.0 - adOffset;
    stopResultsViewHeight = MIN(610.0 - adOffset, stopResultsViewHeight);
    
    CGRect stopResultsViewFrame = CGRectMake(self.view.center.x - stopResultsViewWidth / 2, self.view.center.y + 7.5 - stopResultsViewHeight / 2 - adOffset / 2, stopResultsViewWidth, stopResultsViewHeight);
    return stopResultsViewFrame;
}

- (CGRect)stopResultsViewMinimizedFrame
{
    return CGRectMake(self.stopResultsViewPresentedFrame.origin.x, self.view.bounds.size.height - self.titleView.bounds.size.height, self.stopResultsViewPresentedFrame.size.width, self.stopResultsViewPresentedFrame.size.height);
}

#pragma mark - Favorites and history

- (void)favButtonTapped:(UIButton *)sender
{
    CGFloat animationDuration = 0.25;
    
    sender.selected = !sender.selected;
    
    if (self.stop.isFavorite) {
        self.stop.favorite = NO;
        
        [self.stopInfoView.favoriteContentView endEditing:YES];
        
        [UIView animateWithDuration:(animationDuration / 2) animations:^{
            self.stopInfoView.favoriteContentView.alpha = 0;
        } completion:^(BOOL finished) {
            self.stopInfoView.favoriteContentView.hidden = YES;
            self.stopInfoView.favoriteContentView.alpha = 1;
            self.stopInfoView.contentView.alpha = 0;
            self.stopInfoView.contentView.hidden = NO;
            
            [UIView animateWithDuration:animationDuration animations:^{
                self.stopInfoView.contentView.alpha = 1;
            } completion:nil];
        }];
    } else {
        self.stop.favorite = YES;
        
        [self.stopInfoView.favoriteNameField becomeFirstResponder];
        
        [UIView animateWithDuration:(animationDuration / 2) animations:^{
            self.stopInfoView.contentView.alpha = 0;
        } completion:^(BOOL finished) {
            self.stopInfoView.contentView.hidden = YES;
            self.stopInfoView.contentView.alpha = 1;
            self.stopInfoView.favoriteContentView.alpha = 0;
            self.stopInfoView.favoriteContentView.hidden = NO;
            
            [UIView animateWithDuration:animationDuration animations:^{
                self.stopInfoView.favoriteContentView.alpha = 1;
            } completion:nil];
        }];
    }
    
    [self.delegate stopResultsViewControllerDidUpdateUserData];
}

- (void)stopSignView:(UIView *)signView didEditFavoriteNameWithString:(NSString *)string
{
    [self.stop setFavoriteName:string];
    [self.delegate stopResultsViewControllerDidUpdateUserData];
}

- (void)updateHistory
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *history = [defaults arrayForKey:@"history"];
    
    if (!history) history = [NSArray new];
    
    NSMutableArray *mutableHistory = [history mutableCopy];
    NSUInteger historyCount = 0;
    
    for (NSDictionary *stop in history) {
        if ([stop[@"codigo"] isEqualToString:self.stop.code]) {
            historyCount = [stop[@"count"] integerValue];
            [mutableHistory removeObject:stop];
        }
    }
    
    historyCount++;
    NSMutableDictionary *mutableStop = [[self.stop asDictionary] mutableCopy];
    [mutableStop setValue:@(historyCount) forKey:@"count"];
    [mutableHistory addObject:mutableStop];
    
    [defaults setObject:mutableHistory forKey:@"history"];
    [defaults synchronize];
    
    [self.delegate stopResultsViewControllerDidUpdateUserData];
}

#pragma mark - Stop logic

- (void)setStopCode:(NSString *)stopCode
{
    NSLog(@"setStopCode:%@", stopCode);
    self.stop = nil;
    _stopCode = stopCode;
    
    [[CFSapoClient sharedClient] fetchBusStop:stopCode
                                      handler:^(NSError *error, id result) {
                                          if (result) {
                                              for (NSDictionary *stopData in result) {
                                                  CLLocationCoordinate2D coordinate;
                                                  coordinate.latitude = [[stopData objectForKey:@"latitude"] doubleValue];
                                                  coordinate.longitude = [[stopData objectForKey:@"longitude"] doubleValue];
                                                  
                                                  CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[stopData objectForKey:@"codigo"] name:[stopData objectForKey:@"nombre"] services:[stopData objectForKey:@"recorridos"]];
                                                  self.stop = stop;
                                              }
                                          } else {
                                              [self.refreshControl endRefreshing];
                                              NSLog(@"Couldn't fetch stop. %@", error);
                                              
                                              if (self.displayMode == CFStopResultsDisplayModePresented) {
                                                  UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STOP_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@\n%@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
                                                  errorAlert.tag = 6009;
                                                  [errorAlert show];
                                              }
                                              
                                              Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                              [mixpanel track:@"Failed Stop Data Request" properties:@{@"Code": stopCode, @"Error": error.debugDescription}];
                                          }
                                      }];
}

- (void)setStop:(CFStop *)stop
{
    NSLog(@"setStop:%@", stop.code);
    if ([stop isEqual:_stop]) return;
    _stop = stop;
    
    if (stop && stop.services.count == 0) {
        self.stopCode = stop.code;
        return;
    }
    
    self.refreshing = NO;
    
    [self resetEstimationData];
    [self resetTimer];
    [self setUpTitleView];
    
    if (stop) {
        [self.tableView reloadData];
        [self requestAds];
        
        if (self.displayMode == CFStopResultsDisplayModeContained) {
            [self performSelector:@selector(performStopRequestQuietly:) withObject:nil afterDelay:1.0];
        } else {
            [self updateHistory];
            [self performStopRequestQuietly:NO];
        }
    }
}

- (void)setUpTitleView
{
    self.stopInfoView.stop = self.stop;
    
    if (self.stop) {
        self.favoriteButton.selected = self.stop.isFavorite;
        self.stopInfoView.favoriteContentView.hidden = !self.stop.isFavorite;
        self.stopInfoView.contentView.hidden = self.stop.isFavorite;
        self.favoriteButton.alpha = 0;
    } else {
        self.favoriteButton.enabled = NO;
        self.favoriteButton.selected = NO;
        self.stopInfoView.favoriteContentView.hidden = YES;
        self.stopInfoView.contentView.hidden = NO;
        self.titleActivityIndicatorView.alpha = 0;
        self.favoriteButton.alpha = 1;
    }
    
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (self.stop) {
            [self.titleActivityIndicatorView stopAnimating];
            self.titleActivityIndicatorView.alpha = 0;
            self.favoriteButton.alpha = 1;
        } else {
            [self.titleActivityIndicatorView startAnimating];
            self.titleActivityIndicatorView.alpha = 1;
            self.favoriteButton.alpha = 0;
        }
    } completion:nil];
}

- (void)performStopRequestQuietly:(BOOL)quietly
{
    NSLog(@"performStopRequestQuietly:%d", quietly);
    if (!self.stop || self.refreshing) return;
    self.refreshing = YES;
    CFStop *requestedStop = self.stop;
    
    [self resetEstimationData];
    [self resetTimer];
    
    [[CFSapoClient sharedClient] estimateAtBusStop:requestedStop.code
                                          services:nil
                                           handler:^(NSError *error, id result) {
                                               if (!self.stop || ![self.stop isEqual:requestedStop]) return;
                                               if (result) {
                                                   NSArray *estimation = result[@"estimation"];
                                                   NSArray *buses = estimation[0];
                                                   
                                                   for (NSArray *busData in buses) {
                                                       NSDictionary *dict = [NSDictionary dictionaryWithObjects:busData forKeys:[NSArray arrayWithObjects:@"recorrido", @"tiempo", @"distancia", nil]];
                                                       [self.responseEstimation addObject:dict];
                                                   }
                                                   
                                                   if (estimation.count > 2) {
                                                       NSArray *outOfSchedule = estimation[2];
                                                       self.responseWithoutEstimation = [outOfSchedule mutableCopy];
                                                   }
                                                   
                                                   [self processEstimationData];
                                                   
                                               } else if (error) {
                                                   NSLog(@"Consulta falló. Error: %@", error.description);
                                                   
                                                   if (self.displayMode == CFStopResultsDisplayModePresented && !quietly) {
                                                       UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STOP_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@\n%@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
                                                       [errorAlert show];
                                                   }
                                                   
                                                   self.refreshing = NO;
                                                   [self.refreshControl endRefreshing];
                                                   [self refreshTimerLabel];
                                                   
                                                   Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                   [mixpanel track:@"Failed Estimation Request" properties:@{@"Code": self.stop.code, @"Error": error.debugDescription}];
                                               }
                                           }];
}

- (void)processEstimationData
{
    NSLog(@"processEstimationData");
    NSMutableArray *servicesWithoutAnyData = [NSMutableArray new];
    
    for (NSDictionary *service in self.stop.services) {
        NSMutableDictionary *moddedService = [service mutableCopy];
        NSMutableArray *estimations = [NSMutableArray new];
        NSString *serviceName = [service objectForKey:@"name"];
        CGFloat rawNearestDistance = CGFLOAT_MAX;
        
        for (NSDictionary *estimation in self.responseEstimation) {
            if ([[estimation objectForKey:@"recorrido"] isEqualToString:serviceName]) {
                NSMutableDictionary *thisEstimation = [NSMutableDictionary new];
                
                // take care of distance formatting
                CGFloat distance = [[estimation objectForKey:@"distancia"] integerValue];
                
                if (distance < rawNearestDistance) {
                    rawNearestDistance = distance;
                }
                
                NSString *distanceString;
                NSString *unit = @"m";
                
                if (distance >= 1000) {
                    unit = @"km";
                    distance = distance / 1000;
                    distanceString = [NSString stringWithFormat:@"%.2f", distance];
                } else {
                    unit = @"m";
                    distanceString = [NSString stringWithFormat:@"%.0f", distance];
                }
                
                NSString *finalDistanceString = [NSString stringWithFormat:@"%@ %@", distanceString, unit];
                
                [thisEstimation setObject:finalDistanceString forKey:@"distance"];
                
                // and time formatting
                NSString *time = [estimation objectForKey:@"tiempo"];
                NSString *finalTimeString;
                
                if ([time hasPrefix:@"Entre"]) {
                    NSRange fromRange = NSMakeRange(6, 2);
                    NSRange toRange = NSMakeRange(11, 2);
                    NSInteger fromMin = [[time substringWithRange:fromRange] integerValue];
                    NSInteger toMin = [[time substringWithRange:toRange] integerValue];
                    finalTimeString =  [NSString stringWithFormat:@"%ld %@ %ld min", (long)fromMin, NSLocalizedString(@"TO_MINS", nil), (long)toMin];
                } else {
                    finalTimeString = time;
                }
                
                [thisEstimation setObject:finalTimeString forKey:@"eta"];
                
                [estimations addObject:thisEstimation];
            }
        }
        
        [moddedService setObject:[NSNumber numberWithFloat:rawNearestDistance] forKey:@"rawNearestDistance"];
        [moddedService setObject:estimations forKey:@"estimations"];
        
        for (NSString *outOfScheduleService in self.responseWithoutEstimation) {
            if ([outOfScheduleService isEqualToString:serviceName]) {
                [moddedService setObject:NSLocalizedString(@"OUT_OF_SCHEDULE", nil) forKey:@"noEstimationReason"];
            }
        }
        
        if (![estimations lastObject] && !moddedService[@"noEstimationReason"]) {
            [servicesWithoutAnyData addObject:moddedService];
        } else {
            [self.finalData addObject:moddedService];
        }
    }
    
    NSSortDescriptor *distanceSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"rawNearestDistance" ascending:YES];
    [self.finalData sortUsingDescriptors:@[distanceSortDescriptor]];
    
    [self.finalData addObjectsFromArray:servicesWithoutAnyData];
    
    self.refreshing = NO;
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.refreshControl endRefreshing];
    [self refreshTimerLabel];
    
    [self performSelector:@selector(performStopRequestQuietly:) withObject:nil afterDelay:16.0];
    
    if (!self.timer.isValid) {
        NSTimer *newTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshTimerLabel) userInfo:nil repeats:YES];
        
        self.timer = newTimer;
    }
}

- (void)resetEstimationData
{
    [self.responseEstimation removeAllObjects];
    [self.responseWithoutEstimation removeAllObjects];
    [self.finalData removeAllObjects];
    if (!self.refreshing) [self.tableView reloadData];
}

- (void)refreshTimerLabel
{
    if (self.refreshing) {
        self.timerLabel.text = NSLocalizedString(@"REFRESHING", nil);
        self.timerCount = 15;
    } else if (self.timer.isValid) {
        self.timerLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.timerCount--];
    } else {
        self.timerLabel.text = @"";
    }
}

- (void)resetTimer
{
    [self.timer invalidate];
    [self refreshTimerLabel];
    [self.class cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Table view data source

- (void)setRefreshing:(BOOL)refreshing
{
    _refreshing = refreshing;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = refreshing;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.stop.services count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Result Cell";
    CFResultCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.delegate = self;
    
    if (cell == nil)
        cell = [[CFResultCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    NSDictionary *serviceDictionary;
    
    if ([self.finalData lastObject]) {
        serviceDictionary = [self.finalData objectAtIndex:indexPath.row];
    } else {
        serviceDictionary = [self.stop.services objectAtIndex:indexPath.row];
    }
    
    cell.backgroundColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.serviceLabel.text = [serviceDictionary objectForKey:@"name"];
    cell.directionLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [[serviceDictionary objectForKey:@"destino"] capitalizedString]];
    cell.estimations = [serviceDictionary objectForKey:@"estimations"];
    cell.noEstimationReason = [serviceDictionary objectForKey:@"noEstimationReason"];
    
    NSString *operatorID = [cell.serviceLabel.text substringToIndex:1];
    
    UIColor *badgeColor = [UIColor whiteColor];
    
    if ([operatorID isEqualToString:@"1"]) // alsacia
        badgeColor = [UIColor colorWithRed:0.00 green:0.62 blue:0.91 alpha:1.0];
    else if ([operatorID isEqualToString:@"2"] || [operatorID isEqualToString:@"G"]) // subus
        badgeColor = [UIColor colorWithRed:39.0/255.0 green:58.0/255.0 blue:145.0/255.0 alpha:1];
    else if ([operatorID isEqualToString:@"3"] || [operatorID isEqualToString:@"E"] || [operatorID isEqualToString:@"H"] || [operatorID isEqualToString:@"I"]) // vule
        badgeColor = [UIColor colorWithRed:0 green:167.0/255.0 blue:126.0/255.0 alpha:1];
    else if ([operatorID isEqualToString:@"4"] || [operatorID isEqualToString:@"D"]) // express
        badgeColor = [UIColor colorWithRed:247.0/255.0 green:148.0/255.0 blue:29.0/255.0 alpha:1];
    else if ([operatorID isEqualToString:@"5"] || [operatorID isEqualToString:@"J"]) // metbus
        badgeColor = [UIColor colorWithRed:0.00 green:0.68 blue:0.72 alpha:1.0];
    else if ([operatorID isEqualToString:@"6"] || [operatorID isEqualToString:@"B"] || [operatorID isEqualToString:@"C"]) // veolia
        badgeColor = [UIColor colorWithRed:237.0/255.0 green:28.0/255.0 blue:36.0/255.0 alpha:1];
    else if ([operatorID isEqualToString:@"F"]) // stp
        badgeColor = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0 alpha:1];
    
    cell.badgeColor = badgeColor;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.stopResultsView.bounds.size.width, 20.0)];
//    headerView.backgroundColor = [UIColor whiteColor];
    
    UILabel *service = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 0, 90.0, 20.0)];
    service.text = NSLocalizedString(@"SERVICE", nil);
    service.font = [UIFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
    [headerView addSubview:service];
    
    UILabel *estimate = [[UILabel alloc] initWithFrame:CGRectMake(140.0, 0, 100.0, 20.0)];
    estimate.text = NSLocalizedString(@"ESTIMATION", nil);
    estimate.font = [UIFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
    [headerView addSubview:estimate];
    
    [headerView addSubview:self.timerLabel];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CFResultCell *cell = (CFResultCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    [self.delegate stopResultsViewControllerDidRequestServiceRoute:cell.serviceLabel.text directionString:cell.directionLabel.text];
    [self minimize];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Service Route Requested" properties:@{@"Service": cell.serviceLabel.text, @"From": @"Stop Results"}];
}

- (void)sendComplaintTweetForService:(NSString *)service
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *complaintTweet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [complaintTweet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"NO_INFO_COMPLAINT_TWEET", nil), service, self.stop.code]];
        [self presentViewController:complaintTweet animated:YES completion:nil];
    }
}

#pragma mark - Ads

- (void)requestAds
{
    if (self.removedAds) return;
    if (!self.bannerView) return;
    NSLog(@"requestAds: passed all checks, requesting ad");
    
    GADRequest *adRequest = [GADRequest request];
    if (self.stop) [adRequest setLocationWithLatitude:self.stop.coordinate.latitude longitude:self.stop.coordinate.longitude accuracy:0];
    [self.bannerView loadRequest:adRequest];
}

- (BOOL)removedAds
{
    return ([OLCashier hasProduct:@"CF01"] || [OLCashier hasProduct:@"CF02"]);
}

- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    NSLog(@"adViewDidReceiveAd");
    if (self.removedAds) return;
    if (self.showingAds) return;
    if (self.displayMode != CFStopResultsDisplayModePresented) return;
    
    self.showingAds = YES;
    
    [UIView animateWithDuration:2.2 delay:1 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{
        self.stopResultsView.frame = self.stopResultsViewPresentedFrame;
        [self showAds];
    } completion:nil];
}

- (void)hideAds
{
    self.bannerView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 50);
}

- (void)showAds
{
    self.bannerView.frame = CGRectMake(0, self.view.bounds.size.height - 50, self.view.bounds.size.width, 50);
}

- (void)positionAd:(CGFloat)positionFactor
{
    if (!self.showingAds) return;
    positionFactor = MAX(0, positionFactor);
    positionFactor = MIN(1.0, positionFactor);
    CGFloat adOffset = 50 * positionFactor;
    self.bannerView.frame = CGRectMake(0, self.view.bounds.size.height - adOffset, self.view.bounds.size.width, 50);
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    NSLog(@"adView:didFailToReceiveAdWithError:%@", error);
}

@end
