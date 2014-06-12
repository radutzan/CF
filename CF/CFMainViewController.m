//
//  CFMainViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Mixpanel/Mixpanel.h>
#import <OLGhostAlertView/OLGhostAlertView.h>

#import "CFMainViewController.h"
#import "OLCashier.h"
#import "CFSapoClient.h"

#import "CFMapController.h"
#import "CFSearchField.h"
#import "CFSmartSearchList.h"
#import "CFStopResultsViewController.h"
#import "CFServiceRouteViewController.h"
#import "CFFavoritesViewController.h"
#import "CFHistoryViewController.h"
#import "CFMoreViewController.h"
#import "CFWhatsNewViewController.h"

#import "OLShapeTintedButton.h"

#import "GADInterstitial.h"
#import "GADBannerView.h"

#define TAB_BAR_HEIGHT 44.0
#define TAB_BUTTON_WIDTH 75.0
#define CONTENT_ORIGIN 160.0

@interface CFMainViewController () <UIScrollViewDelegate, CFSearchFieldDelegate, CFStopTableViewDelegate, CFMapControllerDelegate, CFSmartSearchListDelegate, UIActionSheetDelegate, UIAlertViewDelegate, GADInterstitialDelegate>

@property (nonatomic, strong) CFMapController *mapController;
@property (nonatomic, strong) CFSmartSearchList *smartSearchList;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *gripper;
@property (nonatomic, strong) UIButton *openMapButton;
@property (nonatomic, strong) UIScrollView *mapFeaturesView;
@property (nonatomic, strong) UINavigationBar *localNavigationBar;
@property (nonatomic, strong) UIImageView *logoView;

@property (nonatomic, strong) NSArray *tabs;
@property (nonatomic, strong) UIView *tabBar;
@property (nonatomic, strong) CFFavoritesViewController *favoritesController;
@property (nonatomic, strong) CFHistoryViewController *historyController;
@property (nonatomic, strong) CFMoreViewController *moreController;

@property (nonatomic, assign) BOOL mapMode;
@property (nonatomic, assign) CGFloat initialContentCenterY;
@property (nonatomic, assign) CGPoint initialOpenMapButtonCenter;
@property (nonatomic, assign) CLLocationCoordinate2D mapLocationCoordinate;

@property (nonatomic, assign) BOOL shouldDisplayAds;
@property (nonatomic, strong) GADBannerView *mapBannerAd;
@property (nonatomic, strong) GADInterstitial *interstitialAd;
@property (nonatomic, assign) BOOL interstitialLoaded;

@end

@implementation CFMainViewController

#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"";
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:self.navigationController.view.bounds];
    
    self.mapController = [[CFMapController alloc] initWithFrame:self.view.bounds];
    self.mapController.delegate = self;
    self.mapController.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.mapController];
    
    self.smartSearchList = [[CFSmartSearchList alloc] initWithFrame:self.view.bounds];
    self.smartSearchList.delegate = self;
    self.smartSearchList.contentInset = UIEdgeInsetsMake(64.0, 0, TAB_BAR_HEIGHT, 0);
    [self.view addSubview:self.smartSearchList];
    
    self.localNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64.0)];
    self.localNavigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.localNavigationBar];
    
    CFSearchField *searchField = [[CFSearchField alloc] initWithFrame:CGRectMake(0, 0, 300, 44.0)];
    searchField.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    searchField.placeholder = NSLocalizedString(@"MAP_SEARCHFIELD_PLACEHOLDER", nil);
    searchField.delegate = self;
    
    UIBarButtonItem *bipButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-bip"] style:UIBarButtonItemStylePlain target:self.mapController action:@selector(goToNearestBipSpot)];
    MKUserTrackingBarButtonItem *tracky = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapController.mapView];
    
    UINavigationItem *navItem = [UINavigationItem new];
    navItem.titleView = searchField;
    navItem.rightBarButtonItems = @[tracky, bipButton];
    
    [self.localNavigationBar pushNavigationItem:navItem animated:NO];
    
    self.contentView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - CONTENT_ORIGIN)];
    self.contentView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.contentView.frame = CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - CONTENT_ORIGIN);
    [self.view addSubview:self.contentView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height - TAB_BAR_HEIGHT)];
    self.scrollView.delegate = self;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * 3, self.scrollView.bounds.size.height);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.alpha = 0;
    [self.contentView addSubview:self.scrollView];
    
    self.tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, TAB_BAR_HEIGHT)];
    self.tabBar.tintColor = [UIColor colorWithWhite:0.42 alpha:1];
    [self.view addSubview:self.tabBar];
    
    [self initTabs];
    
    self.gripper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, 30)];
    self.gripper.alpha = 0;
    [self.contentView addSubview:self.gripper];
    
    UIImageView *gripImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gripper"]];
    gripImage.frame = self.gripper.bounds;
    gripImage.contentMode = UIViewContentModeCenter;
    [self.gripper addSubview:gripImage];
    
    UIPanGestureRecognizer *gripDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGripDragGesture:)];
    [self.gripper addGestureRecognizer:gripDrag];
    
#if TARGET_IPHONE_SIMULATOR
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF01"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF02"];
    
#ifdef DEV_VERSION
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CF01"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF02"];
#endif
#endif
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *mappy = @"Yes";
    NSString *freeMap = ([[NSUserDefaults standardUserDefaults] boolForKey:@"CFEnableMapWithAds"])? @"Yes" : @"No";
    
    [mixpanel registerSuperProperties:@{@"Has Map": mappy}];
    [mixpanel registerSuperProperties:@{@"Has Free Map": freeMap}];
    
    self.openMapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.openMapButton.frame = CGRectMake(0, self.localNavigationBar.frame.size.height, self.view.bounds.size.width, CONTENT_ORIGIN - self.localNavigationBar.frame.size.height);
    self.openMapButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    [self.openMapButton addTarget:self action:@selector(switchToMap) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:self.openMapButton aboveSubview:self.mapController];
    
    UIPanGestureRecognizer *openMapButtonDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGripDragGesture:)];
    [self.openMapButton addGestureRecognizer:openMapButtonDrag];
    
    self.mapMode = YES;
    
    [self registerForKeyboardNotifications];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)viewDidLoad
{
    
    BOOL runBefore = [[NSUserDefaults standardUserDefaults] boolForKey:@"OLHasRunBefore"];
    
    if (!runBefore) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"OLHasRunBefore"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self importUserData];
    }
    
    BOOL hasLaunched192 = [[NSUserDefaults standardUserDefaults] boolForKey:@"OLHasLaunched192"];
    
    if (!hasLaunched192) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"OLHasLaunched192"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        CFWhatsNewViewController *whatsNew = [CFWhatsNewViewController new];
        [self presentViewController:whatsNew animated:YES completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [self reloadUserData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.shouldDisplayAds) {
        self.interstitialLoaded = NO;
        [self loadInterstitialAd];
        [self loadMapBannerAd];
    }
}

- (void)importUserData
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *favsPath = [documentsDirectory stringByAppendingPathComponent:@"favs.plist"];
    BOOL haveFavs = [fileManager fileExistsAtPath:favsPath];
    
    if (haveFavs) {
        NSMutableArray *tempFavs = [[NSMutableArray alloc] initWithContentsOfFile:favsPath];
        
        for (NSDictionary *oldStop in tempFavs) {
            NSString *code = [oldStop objectForKey:@"codigo"];
            NSString *favoriteName = [oldStop objectForKey:@"custName"];
            
            [[CFSapoClient sharedClient] fetchBusStop:code
                                              handler:^(NSError *error, id result) {
                                                  if (result) {
                                                      for (NSDictionary *stopData in result) {
                                                          CLLocationCoordinate2D coordinate;
                                                          coordinate.latitude = [[stopData objectForKey:@"latitude"] doubleValue];
                                                          coordinate.longitude = [[stopData objectForKey:@"longitude"] doubleValue];
                                                          
                                                          CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[stopData objectForKey:@"codigo"] name:[stopData objectForKey:@"nombre"] services:[stopData objectForKey:@"recorridos"]];
                                                          [stop setFavoriteWithName:favoriteName];
                                                      }
                                                      
                                                      [self reloadUserData];
                                                  } else {
                                                      NSLog(@"Couldn't fetch stop. %@", error);
                                                  }
                                              }];
        }
    }
    
    NSString *histPath = [documentsDirectory stringByAppendingPathComponent:@"history.plist"];
    BOOL haveHist = [fileManager fileExistsAtPath:histPath];
    
    if (haveHist) {
        NSMutableArray *tempHist = [[NSMutableArray alloc] initWithContentsOfFile:histPath];
        NSMutableArray *newHistory = [NSMutableArray new];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        for (NSDictionary *oldStop in tempHist) {
            NSString *code = [oldStop objectForKey:@"codigo"];
            [[CFSapoClient sharedClient] fetchBusStop:code
                                              handler:^(NSError *error, id result) {
                                                  if (result) {
                                                      for (NSDictionary *stopData in result) {
                                                          CLLocationCoordinate2D coordinate;
                                                          coordinate.latitude = [[stopData objectForKey:@"latitude"] doubleValue];
                                                          coordinate.longitude = [[stopData objectForKey:@"longitude"] doubleValue];
                                                          
                                                          CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[stopData objectForKey:@"codigo"] name:[stopData objectForKey:@"nombre"] services:[stopData objectForKey:@"recorridos"]];
                                                          
                                                          [newHistory addObject:[stop asDictionary]];
                                                      }
                                                      
                                                      [defaults setObject:newHistory forKey:@"history"];
                                                      [defaults synchronize];
                                                      
                                                      [self reloadUserData];
                                                  } else {
                                                      NSLog(@"Couldn't fetch stop. %@", error);
                                                  }
                                              }];
        }
    }
}

- (void)reloadUserData
{
    [self.favoritesController.tableView reloadData];
    [self.historyController.tableView reloadData];
}

#pragma mark - Tabs

- (void)initTabs
{
    self.favoritesController = [[CFFavoritesViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.favoritesController.delegate = self;
    
    self.historyController = [[CFHistoryViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.historyController.delegate = self;
    
    self.moreController = [[CFMoreViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    self.tabs = @[@{@"controller": self.favoritesController,
                    @"title": @"Favorites",
                    @"button": [UIImage imageNamed:@"button-favorites"],
                    @"button-selected": [UIImage imageNamed:@"button-favorites-selected"]},
                  @{@"controller": self.historyController,
                    @"title": @"History",
                    @"button": [UIImage imageNamed:@"button-history"],
                    @"button-selected": [UIImage imageNamed:@"button-history-selected"]},
                  @{@"controller": self.moreController,
                    @"title": @"More",
                    @"button": [UIImage imageNamed:@"button-more"],
                    @"button-selected": [UIImage imageNamed:@"button-more-selected"]}];
}

- (void)setTabs:(NSArray *)tabs
{
    _tabs = tabs;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * tabs.count, self.scrollView.bounds.size.height);
    
    CGFloat tabButtonWidth = floorf(300 / tabs.count);
    
    for (NSDictionary *tab in tabs) {
        UIViewController *thisTabController = tab[@"controller"];
        thisTabController.view.frame = CGRectMake(self.scrollView.bounds.size.width * [tabs indexOfObject:tab], 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
        [self addChildViewController:thisTabController];
        [self.scrollView addSubview:thisTabController.view];
        
        OLShapeTintedButton *thisTabButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
        thisTabButton.frame = CGRectMake(10.0 + tabButtonWidth * [tabs indexOfObject:tab], 0, tabButtonWidth, TAB_BAR_HEIGHT);
        [thisTabButton setImage:tab[@"button"] forState:UIControlStateNormal];
        [thisTabButton setImage:tab[@"button-selected"] forState:UIControlStateSelected];
        [thisTabButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabBar addSubview:thisTabButton];
    }
    
    UILongPressGestureRecognizer *clearHistory = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognized:)];
    [[self.tabBar.subviews objectAtIndex:1] addGestureRecognizer:clearHistory];
}

- (void)tabButtonTapped:(UIButton *)button
{
    [self selectTabButton:button];
    self.mapMode = NO;
    
    NSUInteger index = [[self.tabBar subviews] indexOfObject:button];
    
    [self switchToTab:index];
}

- (void)selectTabButton:(UIButton *)button
{
    for (UIButton *b in self.tabBar.subviews) {
        b.selected = NO;
        b.tintColor = nil;
    }
    
    button.selected = YES;
    button.tintColor = [[UIApplication sharedApplication] keyWindow].tintColor;
}

- (void)switchToTab:(NSUInteger)tabIndex
{
    CGFloat newOffset = self.scrollView.frame.size.width * tabIndex;
    self.scrollView.contentOffset = CGPointMake(newOffset, 0.0);
    
    switch (tabIndex) {
        case 0:
            [self.favoritesController.tableView flashScrollIndicators];
            break;
            
        case 1:
            [self.historyController.tableView flashScrollIndicators];
            break;
            
        case 2:
            [self.moreController.tableView flashScrollIndicators];
            break;
            
        default:
            break;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    [self.view endEditing:YES];
    
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSUInteger page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (page <= self.tabs.count - 1) {
        UIButton *thisButton = (UIButton *)[[self.tabBar subviews] objectAtIndex:page];
        [self selectTabButton:thisButton];
    }
}

#pragma mark - Map mode switching

- (void)setMapMode:(BOOL)mapMode
{
    _mapMode = mapMode;
    
    CGFloat scrollViewAlpha = 0.0;
    
    if (mapMode) {
        if (self.scrollView.alpha > 0) {
            [UIView animateWithDuration:0.33 delay:0.0 options:(7 >> 16) animations:^{
                [self openMap];
            } completion:nil];
        }
        
        self.openMapButton.hidden = YES;
        scrollViewAlpha = 0.0;
        
        if (self.shouldDisplayAds) {
            if (self.interstitialLoaded) [self.interstitialAd presentFromRootViewController:self];
            [self.view insertSubview:self.mapBannerAd aboveSubview:self.mapController];
        }
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Entered Map Mode" properties:nil];
        
    } else {
        if (self.scrollView.alpha < 1) {
            [UIView animateWithDuration:0.33 delay:0.0 options:(7 >> 16) animations:^{
                [self closeMap];
            } completion:nil];
        }
        
        scrollViewAlpha = 1.0;
        self.openMapButton.hidden = NO;
        
        [self centerMapLocationForClosedState];
    }
    
    [UIView animateWithDuration:0.33 delay:0.0 options:(7 >> 16) animations:^{
        self.openMapButton.frame = CGRectMake(0, self.localNavigationBar.frame.size.height, self.view.bounds.size.width, CONTENT_ORIGIN - self.localNavigationBar.frame.size.height);
        self.openMapButton.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)switchToMap
{
    self.mapMode = YES;
}

- (void)openMap
{
    self.contentView.transform = CGAffineTransformIdentity;
    self.contentView.frame = CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
    self.scrollView.alpha = 0;
    self.gripper.alpha = 0;
    self.openMapButton.alpha = 0;
    self.openMapButton.center = CGPointMake(self.openMapButton.center.x, self.initialOpenMapButtonCenter.y - self.openMapButton.bounds.size.height);
    
    [self.view endEditing:YES];
    
    [self.mapController.mapView setCenterCoordinate:self.mapController.defaultCenterCoordinate];
    
    for (UIButton *b in self.tabBar.subviews) {
        b.selected = NO;
        b.tintColor = nil;
    }
}

- (void)closeMap
{
    self.contentView.frame = CGRectMake(0, CONTENT_ORIGIN, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
    self.scrollView.alpha = 1;
    self.gripper.alpha = 1;
    self.openMapButton.alpha = 1.0;
    self.openMapButton.center = self.initialOpenMapButtonCenter;
}

- (void)centerMapLocationForClosedState
{
    CLLocationCoordinate2D center = self.mapController.defaultCenterCoordinate;
    center.latitude -= self.mapController.mapView.region.span.latitudeDelta * 0.36;
    [self.mapController.mapView setCenterCoordinate:center animated:YES];
}

- (void)mapControllerDidUpdateLocation
{
    if (!self.mapMode) [self centerMapLocationForClosedState];
}

- (void)handleGripDragGesture:(UIPanGestureRecognizer *)recognizer
{
    CGFloat gripTranslation = [recognizer translationInView:self.contentView].y;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.initialContentCenterY = self.contentView.center.y;
        self.initialOpenMapButtonCenter = self.openMapButton.center;
        self.mapLocationCoordinate = self.mapController.defaultCenterCoordinate;
        
        [self.view endEditing:YES];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Used Map Drag Gesture" properties:nil];
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint contentCenter;
        contentCenter.x = self.contentView.center.x;
        contentCenter.y = self.initialContentCenterY + gripTranslation;
        
        CLLocationCoordinate2D mapCenter = self.mapLocationCoordinate;
        
        CGFloat slideFactor = gripTranslation / (self.contentView.bounds.size.height - TAB_BAR_HEIGHT);
        CGFloat appliedFactor = 1.0 - slideFactor;
        
        if (slideFactor <= 1.0 && slideFactor >= 0.0) {
            self.contentView.center = contentCenter;
            self.scrollView.alpha = appliedFactor;
            self.gripper.alpha = appliedFactor;
            self.openMapButton.alpha = appliedFactor;
            self.openMapButton.center = CGPointMake(self.openMapButton.center.x, self.initialOpenMapButtonCenter.y - self.openMapButton.bounds.size.height * slideFactor);
            
            mapCenter.latitude -= self.mapController.mapView.region.span.latitudeDelta * (0.36 * appliedFactor);
            self.mapController.mapView.centerCoordinate = mapCenter;
            
        } else if (slideFactor < 0.0) {
            self.openMapButton.alpha = 1.0;
            self.openMapButton.center = self.initialOpenMapButtonCenter;
            self.contentView.center = CGPointMake(self.contentView.center.x, self.initialContentCenterY);
            CGFloat scaleFactor = 1.0 - slideFactor / 4;
            self.contentView.transform = CGAffineTransformMakeScale(1.0, scaleFactor);
            
            [self centerMapLocationForClosedState];
        }
        
    } else {
        CGFloat terminalVelocity = [recognizer velocityInView:self.view].y;
        CGFloat slideFactor = gripTranslation / (self.contentView.bounds.size.height - TAB_BAR_HEIGHT);
        BOOL opening = [recognizer.view isEqual:self.gripper] || [recognizer.view isEqual:self.openMapButton];
        
        if (terminalVelocity > 250 || (opening && slideFactor >= 0.25)) {
            [self openMapWithVelocity:terminalVelocity];
        } else if (terminalVelocity < -40 || (!opening && slideFactor < 0.25)) {
            [self closeMapWithVelocity:terminalVelocity];
        } else {
            if (opening) {
                [self closeMapWithVelocity:terminalVelocity];
            } else {
                [self closeMapWithVelocity:terminalVelocity];
            }
        }
    }
}

- (void)openMapWithVelocity:(CGFloat)velocity
{
    velocity = MIN(abs(velocity), 3500);
    CGFloat velocityFactor = velocity / 3500;
    CGFloat animationDuration = 0.3 * (1 - velocityFactor);
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self openMap];
    } completion:^(BOOL finished) {
        self.mapMode = YES;
    }];
}

- (void)closeMapWithVelocity:(CGFloat)velocity
{
    velocity = MIN(abs(velocity), 3500);
    CGFloat velocityFactor = velocity / 3500;
    CGFloat animationDuration = 0.3 * (1 - velocityFactor);
    CGFloat scaleFactor = 1 + velocityFactor * 0.2;
    
    [UIView animateWithDuration:animationDuration delay:0 options:0 animations:^{
        [self closeMap];
        
        if (CGAffineTransformIsIdentity(self.contentView.transform)) {
            self.contentView.transform = CGAffineTransformMakeScale(1.0, scaleFactor);
        }
        
    } completion:^(BOOL finished) {
        if (CGAffineTransformIsIdentity(self.contentView.transform)) {
            self.mapMode = NO;
        } else {
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.25 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.contentView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.mapMode = NO;
            }];
        }
    }];
}

#pragma mark - Push stop results and routes

- (void)pushStopResultsWithStopCode:(NSString *)stopCode
{
    [self.view endEditing:YES];
    
    if ([stopCode isEqualToString:@""]) return;
    
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"P[A-J][0-9]{1,4}$" options:(NSRegularExpressionCaseInsensitive) error:NULL];
    
    NSTextCheckingResult *result = [expression firstMatchInString:stopCode options:0 range:NSMakeRange(0, stopCode.length)];
    
    if (!result || [result rangeAtIndex:0].location == NSNotFound) {
        UIAlertView *GTFO = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INVALID_STOP_CODE_TITLE", nil) message:NSLocalizedString(@"INVALID_STOP_CODE_MESSAGE", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"DISMISS", nil) otherButtonTitles:nil];
        [GTFO show];
        
        return;
    }
    
    CFStopResultsViewController *stopResultsVC = [[CFStopResultsViewController alloc] initWithStyle:UITableViewStylePlain];
    stopResultsVC.stopCode = stopCode;
    
    [self.navigationController pushViewController:stopResultsVC animated:YES];
}

- (void)stopTableView:(UITableView *)tableView didSelectCellWithStop:(NSString *)stopCode
{
    [self pushStopResultsWithStopCode:stopCode];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Stop Requested" properties:@{@"Code": stopCode, @"From": @"History or Favorites"}];
}

- (void)mapControllerDidSelectStop:(NSString *)stopCode
{
    [self pushStopResultsWithStopCode:stopCode];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Stop Requested" properties:@{@"Code": stopCode, @"From": @"Map"}];
}

- (void)smartSearchListDidSelectStop:(NSString *)stopCode
{
    [self pushStopResultsWithStopCode:stopCode];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Stop Requested" properties:@{@"Code": stopCode, @"From": @"Smart Search Results"}];
}

- (void)smartSearchListDidSelectService:(NSString *)serviceName direction:(CFDirection)direction
{
    CFServiceRouteViewController *serviceRouteVC = [[CFServiceRouteViewController alloc] initWithService:serviceName direction:direction];
    [self.navigationController pushViewController:serviceRouteVC animated:YES];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Service Route Requested" properties:@{@"Service": serviceName, @"From": @"Smart Search Results"}];
}

- (void)smartSearchListDidSelectService:(NSString *)serviceName directionString:(NSString *)directionString
{
    CFServiceRouteViewController *serviceRouteVC = [[CFServiceRouteViewController alloc] initWithService:serviceName directionString:directionString];
    [self.navigationController pushViewController:serviceRouteVC animated:YES];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Service Route Requested" properties:@{@"Service": serviceName, @"From": @"Smart Search Results"}];
}

#pragma mark - Search

- (void)searchFieldDidBeginEditing:(CFSearchField *)searchField
{
    [self.smartSearchList show];
}

- (void)searchField:(CFSearchField *)searchField textDidChange:(NSString *)searchText
{
    [self.smartSearchList processSearchString:searchText];
}

- (void)searchFieldSearchButtonClicked:(CFSearchField *)searchField
{
    [searchField resignFirstResponder];
    
    if (self.smartSearchList.suggesting) return;
    
    [self.smartSearchList hide];
    [self.mapController performSearchWithString:searchField.text];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Searched in Map" properties:nil];
}

- (void)searchFieldDidEndEditing:(CFSearchField *)searchField
{
    if (!self.smartSearchList.suggesting) {
        [self.smartSearchList hide];
    }
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateKeyframesWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0.0 options:(7 << 16) animations:^{
        self.smartSearchList.contentInset = UIEdgeInsetsMake(self.smartSearchList.contentInset.top, self.smartSearchList.contentInset.left, keyboardRect.size.height, self.smartSearchList.contentInset.right);
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    
    [UIView animateKeyframesWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0.0 options:(7 << 16) animations:^{
        self.smartSearchList.contentInset = UIEdgeInsetsMake(self.smartSearchList.contentInset.top, self.smartSearchList.contentInset.left, TAB_BAR_HEIGHT, self.smartSearchList.contentInset.right);
    } completion:nil];
}

#pragma mark - Other shit

- (void)longPressRecognized:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        UIActionSheet *clearSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) destructiveButtonTitle:NSLocalizedString(@"CLEAR_ALL_HISTORY", nil) otherButtonTitles:nil];
        [clearSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        NSArray *emptyArray = [NSArray new];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:emptyArray forKey:@"history"];
        [defaults synchronize];
        
        [self.historyController.tableView reloadData];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Cleared History" properties:nil];
    }
}

# pragma mark - Commerce

- (void)purchaseMap
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Triggered Map Purchase"];
    
    NSString *mapIdentifier = @"CF01";
    
    OLGhostAlertView *wait = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_WAIT_TITLE", nil) message:NSLocalizedString(@"STORE_WAIT_MESSAGE", nil) timeout:100.0 dismissible:NO];
    wait.position = OLGhostAlertViewPositionCenter;
    [wait show];
    
    [[OLCashier defaultCashier] buyProduct:mapIdentifier handler:^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
        SKPaymentTransaction *transaction = transactions.firstObject;
        [wait hide];
        
        if (error) {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@. %@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
            [errorAlert show];
            
            [mixpanel track:@"Failed to Purchase Map"];
            return;
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:mapIdentifier];
        [transaction finish];
        
        self.mapMode = YES;
        
        [self.mapBannerAd removeFromSuperview];
        
        OLGhostAlertView *thanks = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_THANK_YOU_TITLE", nil) message:NSLocalizedString(@"STORE_THANK_YOU_MESSAGE_MAP", nil)];
        thanks.position = OLGhostAlertViewPositionCenter;
        [thanks show];
        
        [mixpanel track:@"Purchased Map"];
        [mixpanel registerSuperProperties:@{@"Has Map": @"Yes"}];
    }];
}

- (void)restorePurchases
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Triggered Restore Purchases"];
    
    OLGhostAlertView *wait = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_WAIT_TITLE", nil) message:NSLocalizedString(@"STORE_WAIT_MESSAGE", nil) timeout:100.0 dismissible:NO];
    wait.position = OLGhostAlertViewPositionCenter;
    [wait show];
    
    [[OLCashier defaultCashier] restoreCompletedTransactions:^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
        [wait hide];
        
        if (error) {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@. %@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
            [errorAlert show];
            
            [mixpanel track:@"Failed to Restore Purchases"];
            
            return;
        }
        
        for (SKPaymentTransaction *transaction in transactions) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:transaction.payment.productIdentifier];
            [transaction finish];
        }
        
        [mixpanel track:@"Successfully Restored Purchases"];
    }];
}

#pragma mark - Ads

- (BOOL)shouldDisplayAds
{
    return ([[NSUserDefaults standardUserDefaults] boolForKey:@"CFEnableMapWithAds"] && ![OLCashier hasProduct:@"CF01"]);
}

- (void)enableMapWithAdsButtonTapped
{
    UIAlertView *enableMapWithAdsAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ENABLE_MAP", nil) message:NSLocalizedString(@"ENABLE_MAP_ALERT_MESSAGE", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"ENABLE_MAP_ALERT_BUTTON_FREE", nil), NSLocalizedString(@"ENABLE_MAP_ALERT_BUTTON_PAID", nil), NSLocalizedString(@"STORE_RESTORE", nil), nil];
    enableMapWithAdsAlert.tag = 405;
    [enableMapWithAdsAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 405) {
        switch (buttonIndex) {
            case 1:
                [self enableMapWithAds];
                break;
                
            case 2:
                [self purchaseMap];
                break;
                
            case 3:
                [self restorePurchases];
                break;
                
            default:
                break;
        }
    }
}

- (void)enableMapWithAds
{
    [self loadInterstitialAd];
    [self loadMapBannerAd];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.mapMode = YES;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Enabled Map With Ads"];
    [mixpanel registerSuperProperties:@{@"Has Map": @"Yes"}];
    [mixpanel registerSuperProperties:@{@"Has Free Map": @"Yes"}];
}

- (void)loadInterstitialAd
{
    GADRequest *request = [GADRequest request];
    request.testDevices = @[@"61abccb6c029497b02bef4224933c76b", GAD_SIMULATOR_ID];
    
    self.interstitialAd = [GADInterstitial new];
    self.interstitialAd.delegate = self;
    self.interstitialAd.adUnitID = @"ca-app-pub-6226087428684107/9858178470";
    [self.interstitialAd loadRequest:request];
}

- (void)loadMapBannerAd
{
    GADRequest *request = [GADRequest request];
    request.testDevices = @[@"61abccb6c029497b02bef4224933c76b", GAD_SIMULATOR_ID];
    
    self.mapBannerAd = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    self.mapBannerAd.adUnitID = @"ca-app-pub-6226087428684107/9439376076";
    self.mapBannerAd.rootViewController = self;
    self.mapBannerAd.frame = CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT - self.mapBannerAd.bounds.size.height, self.mapBannerAd.bounds.size.width, self.mapBannerAd.bounds.size.height);
    [self.mapBannerAd loadRequest:request];
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)interstitial
{
    self.interstitialLoaded = YES;
}

- (void)interstitial:(GADInterstitial *)interstitial didFailToReceiveAdWithError:(GADRequestError *)error
{
    self.interstitialLoaded = NO;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial
{
    self.interstitialAd = nil;
    self.interstitialLoaded = NO;
    [self loadInterstitialAd];
}

@end
