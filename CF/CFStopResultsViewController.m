//
//  CFStopResultsViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/17/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Mixpanel/Mixpanel.h>
#import <Social/Social.h>
#import <OLGhostAlertView/OLGhostAlertView.h>
#import "CFStopResultsViewController.h"
#import "CFSapoClient.h"
#import "OLCashier.h"
#import "CFStopSignView.h"
#import "CFResultCell.h"
#import "OLShapeTintedButton.h"
#import "CFTransparentView.h"
#import "GADBannerView.h"

@interface CFStopResultsViewController () <CFStopSignViewDelegate, UIAlertViewDelegate, CFResultCellDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *stopResultsView;
@property (nonatomic, strong) CALayer *borderLayer;
@property (nonatomic, assign, readwrite) CFStopResultsDisplayMode displayMode;
@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, assign) CGPoint stopResultsViewPresentedCenter;
@property (nonatomic, assign) CGRect stopResultsViewPresentedFrame;
@property (nonatomic, assign) CGRect stopResultsViewMinimizedFrame;
@property (nonatomic, assign) CGPoint stopResultsViewStoredCenter;
@property (nonatomic, strong) UINavigationBar *titleView;
@property (nonatomic, strong) CFStopSignView *stopInfoView;
@property (nonatomic, strong) OLShapeTintedButton *favoriteButton;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSMutableArray *responseEstimation;
@property (nonatomic, strong) NSMutableArray *finalData;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UILabel *timerLabel;
@property (nonatomic, assign) NSUInteger timerCount;

@property (nonatomic, strong) GADBannerView *bannerView;
@property (nonatomic, assign) BOOL refreshing;
@property (nonatomic, assign) BOOL removedAds;

@end

@implementation CFStopResultsViewController

- (void)loadView
{
    self.responseEstimation = [NSMutableArray new];
    self.finalData = [NSMutableArray new];
    self.refreshing = YES;
    self.removedAds = ([OLCashier hasProduct:@"CF01"] || [OLCashier hasProduct:@"CF02"]);
    
    self.view = [[CFTransparentView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    self.overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:.3];
    [self.view addSubview:self.overlay];
    
    self.stopResultsView = [[UIView alloc] initWithFrame:CGRectOffset(CGRectInset(self.view.bounds, 10.0, 20.0), 0, 10.0)];
    self.stopResultsView.backgroundColor = [UIColor colorWithWhite:0 alpha:.5];
    [self.view addSubview:self.stopResultsView];
    
    self.titleView = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.stopResultsView.bounds.size.width, 54.0)];
    self.titleView.barStyle = UIBarStyleBlack;
    [self.stopResultsView addSubview:self.titleView];
    
    self.borderLayer = [CALayer layer];
    self.borderLayer.frame = CGRectInset(self.stopResultsView.bounds, -0.5, -0.5);
    self.borderLayer.borderWidth = 0.5;
    self.borderLayer.borderColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
    [self.stopResultsView.layer addSublayer:self.borderLayer];
    
    self.stopResultsViewPresentedCenter = self.stopResultsView.center;
    self.stopResultsViewPresentedFrame = self.stopResultsView.frame;
    self.stopResultsViewMinimizedFrame = CGRectMake(self.stopResultsView.frame.origin.x, self.view.bounds.size.height - self.titleView.bounds.size.height, self.stopResultsView.bounds.size.width, self.stopResultsView.bounds.size.height);
    
    self.tableView = [[UITableView alloc] initWithFrame:self.stopResultsView.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.contentInset = UIEdgeInsetsMake(self.titleView.bounds.size.height, 0, 0, 0);
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.stopResultsView insertSubview:self.tableView belowSubview:self.titleView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.displayMode = CFStopResultsDisplayModeNone;
    
    self.stopInfoView = [[CFStopSignView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.titleView.bounds.size.width - 33.0, 52.0)];
    self.stopInfoView.delegate = self;
    self.stopInfoView.stopCodeLabel.hidden = YES;
    self.stopInfoView.favoriteContentView.userInteractionEnabled = YES;
    [self.titleView addSubview:self.stopInfoView];
    
    self.favoriteButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    self.favoriteButton.frame = CGRectMake(self.titleView.bounds.size.width - 38.0, 5.0, 42.0, 42.0);
    self.favoriteButton.enabled = NO;
    [self.favoriteButton setImage:[UIImage imageNamed:@"button-favorites"] forState:UIControlStateNormal];
    [self.favoriteButton setImage:[UIImage imageNamed:@"button-favorites-selected"] forState:UIControlStateSelected];
    [self.favoriteButton addTarget:self action:@selector(favButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.titleView addSubview:self.favoriteButton];
    
    self.refreshControl = [UIRefreshControl new];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(performStopRequestQuietly:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.stopResultsView.bounds.size.width - 100.0 - 15.0, 0, 100.0, 20.0)];
    self.timerLabel.font = [UIFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
    self.timerLabel.alpha = 0.5;
    self.timerLabel.textAlignment = NSTextAlignmentRight;
    self.timerLabel.text = NSLocalizedString(@"REFRESHING", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.refreshing) {
        [self.refreshControl beginRefreshing];
//        [UIView animateWithDuration:0.2 animations:^{
//            self.tableView.contentOffset = CGPointMake(0, -134.0);
//        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.stop) [self performStopRequestQuietly:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.timer invalidate];
    [self.view endEditing:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma mark - Presentation

- (void)setDisplayMode:(CFStopResultsDisplayMode)displayMode
{
    if (_displayMode == displayMode) return;
    _displayMode = displayMode;
    
    // set up gesture recognizers
    UIPanGestureRecognizer *horizontalPanRecognizer;
    UITapGestureRecognizer *overlayTap;
    UIPanGestureRecognizer *overlayPan;
    UITapGestureRecognizer *titleBarTap;
    UITapGestureRecognizer *titleBarDoubleTap;
    UIPanGestureRecognizer *titleBarPan;
    
    if (!horizontalPanRecognizer) {
        horizontalPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalPanGesture:)];
        [horizontalPanRecognizer requireGestureRecognizerToFail:self.tableView.panGestureRecognizer];
        horizontalPanRecognizer.delegate = self;
        [self.stopResultsView addGestureRecognizer:horizontalPanRecognizer];
    }
    
    if (!overlayTap) {
        overlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [self.overlay addGestureRecognizer:overlayTap];
    }
    
    if (!overlayPan) {
        overlayPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalPanGesture:)];
        [self.overlay addGestureRecognizer:overlayPan];
    }
    
    if (!titleBarTap) {
        titleBarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expand)];
        [self.titleView addGestureRecognizer:titleBarTap];
    }
    
    if (!titleBarDoubleTap) {
        titleBarDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(minimize)];
        titleBarDoubleTap.numberOfTapsRequired = 2;
        [self.titleView addGestureRecognizer:titleBarDoubleTap];
    }
    
    if (!titleBarPan) {
        titleBarPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleVerticalPanGesture:)];
        [titleBarPan requireGestureRecognizerToFail:horizontalPanRecognizer];
        [self.titleView addGestureRecognizer:titleBarPan];
    }
    
    // handle mode switches
    if (displayMode == CFStopResultsDisplayModePresented) {
        self.favoriteButton.enabled = YES;
        titleBarDoubleTap.enabled = YES;
        titleBarTap.enabled = NO;
    } else {
        self.favoriteButton.enabled = NO;
        titleBarDoubleTap.enabled = NO;
        titleBarTap.enabled = YES;
    }
    
    if (displayMode == CFStopResultsDisplayModeContained) {
        horizontalPanRecognizer.enabled = NO;
    } else {
        horizontalPanRecognizer.enabled = YES;
    }
    
    // to-do: show gripper
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
            self.borderLayer.frame = self.stopResultsView.layer.bounds;
            initialVelocity = 0;
        }
    }
    
    [self expandWithVelocity:initialVelocity];
}

- (void)containOnRect:(CGRect)rect onViewController:(UIViewController *)onViewController
{
    if (![self addToParentViewController:onViewController]) {
        if (onViewController == self.parentViewController && self.displayMode == CFStopResultsDisplayModeContained) {
            // already contained, adjust frame
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{
                self.stopResultsView.frame = rect;
                self.borderLayer.frame = self.stopResultsView.layer.bounds;
            } completion:nil];
            
            return;
        } else return;
    }
    
    self.displayMode = CFStopResultsDisplayModeContained;
    self.stopResultsView.alpha = 0;
    self.stopResultsView.frame = CGRectOffset(rect, 0, -SEARCH_CARD_ANIMATION_OFFSET);
    
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.stopResultsView.alpha = 1;
        self.stopResultsView.frame = rect;
        self.borderLayer.frame = self.stopResultsView.layer.bounds;
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
        self.borderLayer.frame = self.stopResultsView.layer.bounds;
    } completion:^(BOOL finished) {
    }];
}

- (void)minimize
{
    if (!self.parentViewController) return;
    
    self.displayMode = CFStopResultsDisplayModeMinimized;
    
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:1 options:0 animations:^{
        self.overlay.alpha = 0;
        self.stopResultsView.frame = self.stopResultsViewMinimizedFrame;
    } completion:nil];
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
        self.stopResultsView.center = CGPointMake(self.stopResultsView.center.x + self.view.bounds.size.width, self.stopResultsView.center.y);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
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
            if (self.displayMode == CFStopResultsDisplayModePresented) self.overlay.alpha = 1.0 - fabs(dragFactor);
        } else {
            self.stopResultsView.center = CGPointMake(self.stopResultsViewPresentedCenter.x + moveDiff * 0.25, self.stopResultsView.center.y);
        }
        
    } else {
        CGFloat terminalVelocity = MIN([recognizer velocityInView:self.view].x, 3500);
        CGFloat velocityFactor = fabs(terminalVelocity / 3500);
        
        if (terminalVelocity > 250 || moveDiff > 80) {
            [self dismissFromCenter:self.stopResultsView.center withVelocityFactor:velocityFactor];
        } else {
            [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:velocityFactor options:0 animations:^{
                self.stopResultsView.center = self.stopResultsViewPresentedCenter;
                if (self.displayMode == CFStopResultsDisplayModePresented) self.overlay.alpha = 1;
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
            self.stopInfoView.favoriteContentView.hidden = NO;
            
            [UIView animateWithDuration:animationDuration animations:^{
                self.stopInfoView.favoriteContentView.alpha = 1;
            } completion:nil];
        }];
    }
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
    
    if (!history) {
        history = [NSArray new];
    }
    
    NSMutableArray *mutableHistory = [history mutableCopy];
    NSUInteger historyCount = 0;
    
    for (NSDictionary *stop in history) {
        if ([stop[@"codigo"] isEqualToString:self.stop.code]) {
            historyCount = [stop[@"count"] integerValue];
//            NSLog(@"stop %@ has count: %d", stop[@"codigo"], historyCount);
            [mutableHistory removeObject:stop];
        }
    }
    
    historyCount++;
    NSMutableDictionary *mutableStop = [[self.stop asDictionary] mutableCopy];
    [mutableStop setValue:@(historyCount) forKey:@"count"];
//    NSLog(@"recording count: %d", [mutableStop[@"count"] integerValue]);
    [mutableHistory addObject:mutableStop];
    
    [defaults setObject:mutableHistory forKey:@"history"];
    [defaults synchronize];
    
    [self.delegate stopResultsViewControllerDidUpdateUserData];
}

#pragma mark - Stop logic

- (void)setStopCode:(NSString *)stopCode
{
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
                                              
                                              if ([[self.navigationController topViewController] isEqual:self]) {
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
    _stop = stop;
    
    self.stopInfoView.stop = stop;
    
    [self resetTimer];
    [self.finalData removeAllObjects];
    [self.responseEstimation removeAllObjects];
    [self.tableView reloadData];
    
    if (stop) {
        self.favoriteButton.enabled = YES;
        self.favoriteButton.selected = stop.isFavorite;
        
        if (!self.removedAds) {
            self.bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
            self.bannerView.rootViewController = self;
            self.bannerView.adUnitID = @"ca-app-pub-6226087428684107/3340545274";
            
            GADRequest *adRequest = [GADRequest request];
            adRequest.testDevices = @[GAD_SIMULATOR_ID];
            [adRequest setLocationWithLatitude:stop.coordinate.latitude longitude:stop.coordinate.longitude accuracy:0];
            [self.bannerView loadRequest:adRequest];
        }
        
        [self updateHistory];
        [self performStopRequestQuietly:NO];
        [self.refreshControl beginRefreshing];
    } else {
        self.favoriteButton.enabled = NO;
        self.favoriteButton.selected = NO;
    }
}

- (void)performStopRequestQuietly:(BOOL)quietly
{
    NSLog(@"performStopRequestQuietly:");
    if (!self.stop) return;
    self.refreshing = YES;
    
    [self resetTimer];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.responseEstimation removeAllObjects];
    [self.tableView reloadData];
    
    [[CFSapoClient sharedClient] estimateAtBusStop:self.stop.code
                                          services:nil
                                           handler:^(NSError *error, id result) {
                                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                               
                                               if (result) {
                                                   NSArray *buses = result[@"estimation"][0];
                                                   
                                                   for (NSArray *busData in buses) {
                                                       NSDictionary *dict = [NSDictionary dictionaryWithObjects:busData forKeys:[NSArray arrayWithObjects:@"recorrido", @"tiempo", @"distancia", nil]];
                                                       [self.responseEstimation addObject:dict];
                                                   }
                                                   
                                                   [self processEstimationData];
                                                   
                                               } else if (error) {
                                                   NSLog(@"Consulta falló. Error: %@", error.description);
                                                   
                                                   if ([[self.navigationController topViewController] isEqual:self] && !quietly) {
                                                       UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STOP_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@\n%@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
                                                       [errorAlert show];
                                                   }
                                                   
                                                   Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                   [mixpanel track:@"Failed Estimation Request" properties:@{@"Code": self.stop.code, @"Error": error.debugDescription}];
                                               }
                                           }];
}

- (void)processEstimationData
{
    NSLog(@"processEstimationData");
    [self.finalData removeAllObjects];
    
    NSMutableArray *estimationlessServices = [NSMutableArray new];
    
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
        
        if (![estimations lastObject]) {
            [estimationlessServices addObject:moddedService];
        } else {
            [self.finalData addObject:moddedService];
        }
    }
    
    NSSortDescriptor *distanceSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"rawNearestDistance" ascending:YES];
    [self.finalData sortUsingDescriptors:@[distanceSortDescriptor]];
    
    [self.finalData addObjectsFromArray:estimationlessServices];
    
    self.refreshing = NO;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.refreshControl endRefreshing];
    [self refreshTimerLabel];
    
    [self performSelector:@selector(performStopRequestQuietly:) withObject:NO afterDelay:16.0];
    
    if (!self.timer.isValid) {
        NSTimer *newTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshTimerLabel) userInfo:nil repeats:YES];
        
        self.timer = newTimer;
    }

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
    [self refreshTimerLabel];
    [self.class cancelPreviousPerformRequestsWithTarget:self];
    [self.timer invalidate];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 6009) {
    }
}

#pragma mark - Table view data source

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
    
    if ([self.finalData lastObject])
        serviceDictionary = [self.finalData objectAtIndex:indexPath.row];
    else
        serviceDictionary = [self.stop.services objectAtIndex:indexPath.row];
    
    cell.backgroundColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.serviceLabel.text = [serviceDictionary objectForKey:@"name"];
    cell.directionLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [[serviceDictionary objectForKey:@"destino"] capitalizedString]];
    cell.estimations = [serviceDictionary objectForKey:@"estimations"];
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.removedAds)
        return 0;
    else
        return 50.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.stopResultsView.bounds.size.width, 20.0)];
    
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.removedAds) return nil;
    if (!self.stop) return nil;
    
    return self.bannerView;
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

#pragma mark - Store

- (BOOL)removedAds
{
    return ([OLCashier hasProduct:@"CF01"] || [OLCashier hasProduct:@"CF02"]);
}

@end
