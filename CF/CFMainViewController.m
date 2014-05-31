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
#import "CFSmartSearchList.h"
#import "CFStopResultsViewController.h"
#import "CFServiceRouteViewController.h"
#import "CFEnterStopCodeView.h"
#import "CFFavoritesViewController.h"
#import "CFHistoryViewController.h"
#import "CFMoreViewController.h"
#import "CFWhatsNewViewController.h"

#import "OLShapeTintedButton.h"

#import "GADInterstitial.h"
#import "GADBannerView.h"

#define TAB_BAR_HEIGHT 60.0
#define TAB_BUTTON_WIDTH 75.0
#define CONTENT_ORIGIN 160.0

@interface CFMainViewController () <UIScrollViewDelegate, UISearchBarDelegate, CFEnterStopCodeViewDelegate, CFStopTableViewDelegate, CFMapControllerDelegate, CFSmartSearchListDelegate, UIActionSheetDelegate, UIAlertViewDelegate, GADInterstitialDelegate>

@property (nonatomic, strong) CFMapController *mapController;
@property (nonatomic, strong) CFSmartSearchList *smartSearchList;
@property (nonatomic, strong) CFEnterStopCodeView *enterStopCodeView;
@property (nonatomic, strong) CFFavoritesViewController *favoritesController;
@property (nonatomic, strong) CFHistoryViewController *historyController;
@property (nonatomic, strong) CFMoreViewController *moreController;
@property (nonatomic, strong) UIView *favoritesPlaceholder;
@property (nonatomic, strong) UIView *historyPlaceholder;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *gripper;
@property (nonatomic, strong) UIButton *openMapButton;
@property (nonatomic, strong) UIScrollView *mapFeaturesView;
@property (nonatomic, strong) UINavigationBar *localNavigationBar;
@property (nonatomic, strong) UIImageView *logoView;

@property (nonatomic, strong) UIView *tabBar;
@property (nonatomic, strong) OLShapeTintedButton *codeButton;
@property (nonatomic, strong) OLShapeTintedButton *favoritesButton;
@property (nonatomic, strong) OLShapeTintedButton *historyButton;
@property (nonatomic, strong) OLShapeTintedButton *moreButton;

@property (nonatomic, assign) CGFloat initialContentCenterY;
@property (nonatomic, assign) CGPoint initialOpenMapButtonCenter;
@property (nonatomic, assign) CLLocationCoordinate2D mapLocationCoordinate;

@property (nonatomic, assign) BOOL mapMode;
@property (nonatomic, assign) BOOL mapEnabled;
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
    
    self.smartSearchList = [[CFSmartSearchList alloc] initWithFrame:CGRectMake(0, 64.0, self.view.bounds.size.width, 200.0)];
    self.smartSearchList.delegate = self;
    self.smartSearchList.hidden = YES;
    [self.view addSubview:self.smartSearchList];
    
    self.localNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 45.0)];
    self.localNavigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.localNavigationBar];
    
    self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    self.logoView.frame = CGRectMake(0, 26.0, self.localNavigationBar.bounds.size.width, self.logoView.bounds.size.height);
    self.logoView.contentMode = UIViewContentModeCenter;
    self.logoView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.localNavigationBar addSubview:self.logoView];
    
    self.contentView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, CONTENT_ORIGIN, self.view.bounds.size.width, self.view.bounds.size.height - CONTENT_ORIGIN)];
    self.contentView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.contentView.frame = CGRectMake(0, CONTENT_ORIGIN, self.view.bounds.size.width, self.view.bounds.size.height - CONTENT_ORIGIN);
    self.initialContentCenterY = self.contentView.center.y;
    [self.view addSubview:self.contentView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height - TAB_BAR_HEIGHT)];
    self.scrollView.delegate = self;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * 4, self.scrollView.bounds.size.height);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.contentView addSubview:self.scrollView];
    
    [self initTabs];
    
    self.gripper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, 30)];
    [self.contentView addSubview:self.gripper];
    
    UIImageView *gripImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gripper"]];
    gripImage.frame = self.gripper.bounds;
    gripImage.contentMode = UIViewContentModeCenter;
    [self.gripper addSubview:gripImage];
    
    UIPanGestureRecognizer *gripDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGripDragGesture:)];
    [self.gripper addGestureRecognizer:gripDrag];
    
    self.tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, TAB_BAR_HEIGHT)];
    self.tabBar.tintColor = [UIColor colorWithWhite:0.42 alpha:1];
    [self.view addSubview:self.tabBar];
    
    self.codeButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    self.codeButton.frame = CGRectMake(10.0, 0, TAB_BUTTON_WIDTH, TAB_BAR_HEIGHT);
    [self.codeButton setImage:[UIImage imageNamed:@"button-code"] forState:UIControlStateNormal];
    [self.codeButton setImage:[UIImage imageNamed:@"button-code-selected"] forState:UIControlStateSelected];
    [self.codeButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.codeButton];
    
    self.favoritesButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    self.favoritesButton.frame = CGRectMake(10.0 + TAB_BUTTON_WIDTH, 0, TAB_BUTTON_WIDTH, TAB_BAR_HEIGHT);
    [self.favoritesButton setImage:[UIImage imageNamed:@"button-favorites"] forState:UIControlStateNormal];
    [self.favoritesButton setImage:[UIImage imageNamed:@"button-favorites-selected"] forState:UIControlStateSelected];
    [self.favoritesButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.favoritesButton];
    
    self.historyButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    self.historyButton.frame = CGRectMake(10.0 + TAB_BUTTON_WIDTH * 2, 0, TAB_BUTTON_WIDTH, TAB_BAR_HEIGHT);
    [self.historyButton setImage:[UIImage imageNamed:@"button-history"] forState:UIControlStateNormal];
    [self.historyButton setImage:[UIImage imageNamed:@"button-history-selected"] forState:UIControlStateSelected];
    [self.historyButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.historyButton];
    
    self.moreButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    self.moreButton.frame = CGRectMake(10.0 + TAB_BUTTON_WIDTH * 3, 0, TAB_BUTTON_WIDTH, TAB_BAR_HEIGHT);
    [self.moreButton setImage:[UIImage imageNamed:@"button-more"] forState:UIControlStateNormal];
    [self.moreButton setImage:[UIImage imageNamed:@"button-more-selected"] forState:UIControlStateSelected];
    [self.moreButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.moreButton];
    
    UILongPressGestureRecognizer *clearHistory = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognized:)];
    [self.historyButton addGestureRecognizer:clearHistory];
    
    // ese booleano po
    if ([OLCashier hasProduct:@"CF01"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"CFEnableMapWithAds"]) self.mapEnabled = YES;
    
#if TARGET_IPHONE_SIMULATOR
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF01"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF02"];
    self.mapEnabled = YES;
    
#ifdef DEV_VERSION
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CF01"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF02"];
    self.mapEnabled = NO;
#endif
#endif
    
#ifdef DEV_VERSION
    NSLog(@"dev!");
#endif
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *mappy = (self.mapEnabled)? @"Yes" : @"No";
    NSString *freeMap = ([[NSUserDefaults standardUserDefaults] boolForKey:@"CFEnableMapWithAds"])? @"Yes" : @"No";
    
    [mixpanel registerSuperProperties:@{@"Has Map": mappy}];
    [mixpanel registerSuperProperties:@{@"Has Free Map": freeMap}];
    
    self.openMapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.openMapButton.frame = CGRectMake(0, self.localNavigationBar.frame.size.height, self.view.bounds.size.width, CONTENT_ORIGIN - self.localNavigationBar.frame.size.height);
    self.openMapButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    [self.view insertSubview:self.openMapButton aboveSubview:self.mapController];
    
    UIPanGestureRecognizer *openMapButtonDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGripDragGesture:)];
    [self.openMapButton addGestureRecognizer:openMapButtonDrag];
    
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

- (void)initTabs
{
    self.enterStopCodeView = [[CFEnterStopCodeView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height)];
    self.enterStopCodeView.delegate = self;
    [self.scrollView addSubview:self.enterStopCodeView];
    
    self.favoritesController = [[CFFavoritesViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.favoritesController.view.frame = CGRectMake(self.scrollView.bounds.size.width, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    self.favoritesController.delegate = self;
    [self addChildViewController:self.favoritesController];
    [self.scrollView addSubview:self.favoritesController.view];
    
    self.historyController = [[CFHistoryViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.historyController.view.frame = CGRectMake(self.scrollView.bounds.size.width * 2, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    self.historyController.delegate = self;
    [self addChildViewController:self.historyController];
    [self.scrollView addSubview:self.historyController.view];
    
    [self initPlaceholders];
    
    self.moreController = [[CFMoreViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.moreController.view.frame = CGRectMake(self.scrollView.bounds.size.width * 3, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    [self addChildViewController:self.moreController];
    [self.scrollView addSubview:self.moreController.view];
}

- (void)initPlaceholders
{
    CGFloat verticalMargin = 12.0;
    CGFloat imageOriginY = floorf((self.scrollView.bounds.size.height - 240.0) / 2);
    
    self.favoritesPlaceholder = [[UIView alloc] initWithFrame:self.favoritesController.view.frame];
    UIImageView *favoritesPlaceholderImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-favorites"]];
    favoritesPlaceholderImage.frame = CGRectMake(
                                                 floorf((self.favoritesPlaceholder.bounds.size.width - favoritesPlaceholderImage.bounds.size.width) / 2), imageOriginY,
                                                 favoritesPlaceholderImage.bounds.size.width, favoritesPlaceholderImage.bounds.size.height);
    [self.favoritesPlaceholder addSubview:favoritesPlaceholderImage];
    
    UILabel *favoritesPlaceholderTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, favoritesPlaceholderImage.frame.origin.y + favoritesPlaceholderImage.bounds.size.height + verticalMargin, self.favoritesPlaceholder.bounds.size.width, 25)];
    favoritesPlaceholderTitle.text = NSLocalizedString(@"FAVORITES_PLACEHOLDER_TITLE", nil);
    favoritesPlaceholderTitle.textAlignment = NSTextAlignmentCenter;
    favoritesPlaceholderTitle.font = [UIFont boldSystemFontOfSize:17.0];
    favoritesPlaceholderTitle.textColor = [UIColor colorWithWhite:0 alpha:0.4];
    [self.favoritesPlaceholder addSubview:favoritesPlaceholderTitle];
    
    UILabel *favoritesPlaceholderMessage = [[UILabel alloc] initWithFrame:CGRectMake(50, favoritesPlaceholderTitle.frame.origin.y + favoritesPlaceholderTitle.bounds.size.height + verticalMargin / 2, self.favoritesPlaceholder.bounds.size.width - 100, 62)];
    favoritesPlaceholderMessage.text = NSLocalizedString(@"FAVORITES_PLACEHOLDER_MESSAGE", nil);
    favoritesPlaceholderMessage.numberOfLines = 3;
    favoritesPlaceholderMessage.textAlignment = NSTextAlignmentCenter;
    favoritesPlaceholderMessage.font = [UIFont systemFontOfSize:15.0];
    favoritesPlaceholderMessage.textColor = [UIColor colorWithWhite:0 alpha:0.4];
    [self.favoritesPlaceholder addSubview:favoritesPlaceholderMessage];
    
    if (imageOriginY < 20) {
        favoritesPlaceholderImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
        favoritesPlaceholderImage.center = CGPointMake(favoritesPlaceholderImage.center.x, favoritesPlaceholderImage.center.y + 15.0);
    }
    
    [self.scrollView addSubview:self.favoritesPlaceholder];
    
    self.historyPlaceholder = [[UIView alloc] initWithFrame:self.historyController.view.frame];
    UIImageView *historyPlaceholderImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-history"]];
    historyPlaceholderImage.frame = CGRectMake(
                                                 floorf((self.historyPlaceholder.bounds.size.width - historyPlaceholderImage.bounds.size.width) / 2), imageOriginY,
                                                 historyPlaceholderImage.bounds.size.width, historyPlaceholderImage.bounds.size.height);
    [self.historyPlaceholder addSubview:historyPlaceholderImage];
    
    UILabel *historyPlaceholderTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, historyPlaceholderImage.frame.origin.y + historyPlaceholderImage.bounds.size.height + verticalMargin, self.historyPlaceholder.bounds.size.width, 25)];
    historyPlaceholderTitle.text = NSLocalizedString(@"HISTORY_PLACEHOLDER_TITLE", nil);
    historyPlaceholderTitle.textAlignment = NSTextAlignmentCenter;
    historyPlaceholderTitle.font = [UIFont boldSystemFontOfSize:17.0];
    historyPlaceholderTitle.textColor = [UIColor colorWithWhite:0 alpha:0.4];
    [self.historyPlaceholder addSubview:historyPlaceholderTitle];
    
    UILabel *historyPlaceholderMessage = [[UILabel alloc] initWithFrame:CGRectMake(favoritesPlaceholderMessage.frame.origin.x, historyPlaceholderTitle.frame.origin.y + historyPlaceholderTitle.bounds.size.height + verticalMargin / 2, favoritesPlaceholderMessage.bounds.size.width, favoritesPlaceholderMessage.bounds.size.height)];
    historyPlaceholderMessage.text = NSLocalizedString(@"HISTORY_PLACEHOLDER_MESSAGE", nil);
    historyPlaceholderMessage.numberOfLines = 3;
    historyPlaceholderMessage.textAlignment = NSTextAlignmentCenter;
    historyPlaceholderMessage.font = [UIFont systemFontOfSize:15.0];
    historyPlaceholderMessage.textColor = [UIColor colorWithWhite:0 alpha:0.4];
    [self.historyPlaceholder addSubview:historyPlaceholderMessage];
    
    if (imageOriginY < 20) {
        historyPlaceholderImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
        historyPlaceholderImage.center = CGPointMake(historyPlaceholderImage.center.x, historyPlaceholderImage.center.y + 15.0);
    }
    
    [self.scrollView addSubview:self.historyPlaceholder];
}

- (void)viewDidLoad
{
    self.mapMode = NO;
    
    if (!self.mapMode) {
        [self tabButtonTapped:self.codeButton];
    }
    
    if (self.mapEnabled) {
        self.openMapButton.hidden = NO;
        [self.openMapButton addTarget:self action:@selector(switchToMap) forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.openMapButton.hidden = YES;
        [self showMapFeatures];
    }
    
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
    
    if (self.isMovingToParentViewController == YES) {
        [self tabButtonTapped:self.codeButton];
        self.mapMode = NO;
    }
    
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
    
    if ([self.favoritesController.tableView numberOfRowsInSection:0] == 0)
        self.favoritesPlaceholder.hidden = NO;
    else
        self.favoritesPlaceholder.hidden = YES;
    
    if ([self.historyController.tableView numberOfRowsInSection:0] == 0)
        self.historyPlaceholder.hidden = NO;
    else
        self.historyPlaceholder.hidden = YES;
    
    if ([OLCashier hasProduct:@"CF01"])
        self.mapEnabled = YES;
}

#pragma mark - Map mode switching

- (void)setMapMode:(BOOL)mapMode
{
    _mapMode = mapMode;
    
    CGFloat scrollViewAlpha = 0.0;
    CGFloat localNavBarHeight = 0.0;
    
    if (mapMode) {
        if (self.scrollView.alpha > 0) {
            [UIView animateWithDuration:0.33 delay:0.0 options:(7 >> 16) animations:^{
                [self openMap];
            } completion:nil];
        }
        
        self.openMapButton.hidden = YES;
        scrollViewAlpha = 0.0;
        localNavBarHeight = 64.0;
        
        UISearchBar *searchBar = [UISearchBar new];
        searchBar.searchBarStyle = UISearchBarStyleMinimal;
        searchBar.placeholder = NSLocalizedString(@"MAP_SEARCHFIELD_PLACEHOLDER", nil);
        searchBar.delegate = self;
        
        UIBarButtonItem *bipButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-bip"] style:UIBarButtonItemStylePlain target:self.mapController action:@selector(goToNearestBipSpot)];
        MKUserTrackingBarButtonItem *tracky = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapController.mapView];
        
        UINavigationItem *navItem = [UINavigationItem new];
        navItem.titleView = searchBar;
        navItem.rightBarButtonItems = @[tracky, bipButton];
        
        [self.localNavigationBar pushNavigationItem:navItem animated:YES];
        
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
        localNavBarHeight = 45.0;
        self.openMapButton.hidden = NO;
        
        [self.localNavigationBar popNavigationItemAnimated:YES];
        
        [self centerMapLocationForClosedState];
    }
    
    [UIView animateWithDuration:0.33 delay:0.0 options:(7 >> 16) animations:^{
        self.logoView.alpha = scrollViewAlpha;
        self.localNavigationBar.frame = CGRectMake(0, 0, self.localNavigationBar.bounds.size.width, localNavBarHeight);
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
    self.contentView.center = CGPointMake(self.contentView.center.x, self.initialContentCenterY + self.contentView.bounds.size.height - TAB_BAR_HEIGHT);
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
    self.contentView.center = CGPointMake(self.contentView.center.x, self.initialContentCenterY);
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

- (void)centerMapLocationInTransition
{
    CGPoint targetCenter = CGPointMake(self.view.center.x, 102.0);
    
    CLLocationCoordinate2D userLocation = self.mapController.defaultCenterCoordinate;
    CGPoint currentCenter = [self.mapController.mapView convertCoordinate:userLocation toPointToView:self.view];
    CGPoint finalCenter = currentCenter;
    
    //    userLocation.latitude -= self.mapController.mapView.region.span.latitudeDelta * 0.36;
    
    CGSize offset = CGSizeMake(targetCenter.x - currentCenter.x, targetCenter.y - currentCenter.y);
    
    finalCenter.x -= offset.width;
    finalCenter.y -= offset.height;
    
    CLLocationCoordinate2D coordinate = [self.mapController.mapView convertPoint:finalCenter toCoordinateFromView:self.view];
    
    [self.mapController.mapView setCenterCoordinate:coordinate animated:YES];
}

- (void)mapControllerDidUpdateLocation
{
    [self centerMapLocationForClosedState];
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
        
        if (self.mapEnabled) {
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
        } else {
            [self closeMapWithVelocity:terminalVelocity];
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

- (void)showMapFeatures
{
    self.mapFeaturesView = [[UIScrollView alloc] initWithFrame:self.openMapButton.bounds];
    self.mapFeaturesView.pagingEnabled = YES;
    self.mapFeaturesView.contentSize = CGSizeMake(self.mapFeaturesView.bounds.size.width * 4, self.mapFeaturesView.bounds.size.height);
    self.mapFeaturesView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    self.mapFeaturesView.tag = 5674;
    [self.openMapButton addSubview:self.mapFeaturesView];
    
    // page 1
    UIButton *activateMapButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [activateMapButton setTitle:NSLocalizedString(@"ENABLE_MAP_WITH_ADS", nil) forState:UIControlStateNormal];
    activateMapButton.frame = CGRectMake(0.0, self.mapFeaturesView.bounds.size.height - 45.0, self.mapFeaturesView.bounds.size.width, 45.0);
    activateMapButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:19.0];
    activateMapButton.layer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25].CGColor;
    [activateMapButton addTarget:self action:@selector(enableMapWithAdsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.mapFeaturesView addSubview:activateMapButton];
    
    UILabel *pageOneTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 0, self.mapFeaturesView.bounds.size.width - 40.0, self.mapFeaturesView.bounds.size.height - 45.0)];
    pageOneTitleLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:19.0];
    pageOneTitleLabel.textColor = [UIColor whiteColor];
    pageOneTitleLabel.text = NSLocalizedString(@"THE_MAP", nil);
    [self.mapFeaturesView addSubview:pageOneTitleLabel];
    
    UILabel *pageOneSlideLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.mapFeaturesView.bounds.size.width - 20.0, self.mapFeaturesView.bounds.size.height - 45.0)];
    pageOneSlideLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:19.0];
    pageOneSlideLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    pageOneSlideLabel.text = NSLocalizedString(@"SLIDE_TO_LEARN_MORE_MAP", nil);
    pageOneSlideLabel.textAlignment = NSTextAlignmentRight;
    [self.mapFeaturesView addSubview:pageOneSlideLabel];
    
    UILabel *pageOneSlideLabelGradient = [[UILabel alloc] initWithFrame:pageOneSlideLabel.frame];
    pageOneSlideLabelGradient.font = pageOneSlideLabel.font;
    pageOneSlideLabelGradient.textColor = [UIColor whiteColor];
    pageOneSlideLabelGradient.text = pageOneSlideLabel.text;
    pageOneSlideLabelGradient.textAlignment = pageOneSlideLabel.textAlignment;
    [self.mapFeaturesView addSubview:pageOneSlideLabelGradient];
    
    CGFloat gradientSize = 0.2;
    
    NSArray *startLocations = @[@1.0, [NSNumber numberWithFloat:1.0 + (gradientSize / 2)], [NSNumber numberWithFloat:1.0 + gradientSize]];
    NSArray *endLocations = @[@0.0, [NSNumber numberWithFloat:gradientSize / 2], [NSNumber numberWithFloat:gradientSize]];
    
    CAGradientLayer *gradientMask = [CAGradientLayer layer];
    gradientMask.frame = pageOneSlideLabel.bounds;
    gradientMask.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor];
    gradientMask.locations = startLocations;
    gradientMask.startPoint = CGPointMake(0 - (gradientSize * 2), .5);
    gradientMask.endPoint = CGPointMake(1 + gradientSize, .5);
    
    pageOneSlideLabelGradient.layer.mask = gradientMask;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"locations"];
    animation.fromValue = startLocations;
    animation.toValue = endLocations;
    animation.repeatCount = 3.4e38f;
    animation.duration  = 3.0f;
    
    [gradientMask addAnimation:animation forKey:@"animateGradient"];
    
    // page 2
    CGFloat pageTwoOrigin = self.mapFeaturesView.bounds.size.width;
    
    UILabel *pageTwoLabel = [[UILabel alloc] initWithFrame:CGRectMake(pageTwoOrigin + 85.0, 0, self.mapFeaturesView.bounds.size.width - 105.0, self.mapFeaturesView.bounds.size.height)];
    pageTwoLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    pageTwoLabel.textColor = [UIColor whiteColor];
    pageTwoLabel.text = NSLocalizedString(@"MAP_FEATURE_STOPS", nil);
    pageTwoLabel.numberOfLines = 0;
    [self.mapFeaturesView addSubview:pageTwoLabel];
    
    UIImageView *pageTwoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feature-stops"]];
    pageTwoImage.frame = CGRectOffset(pageTwoImage.frame, pageTwoOrigin + 20.0, floorf((self.mapFeaturesView.bounds.size.height - pageTwoImage.bounds.size.height) / 2));
    [self.mapFeaturesView addSubview:pageTwoImage];
    
    // page 3
    CGFloat pageThreeOrigin = self.mapFeaturesView.bounds.size.width * 2;
    
    UILabel *pageThreeLabel = [[UILabel alloc] initWithFrame:CGRectMake(pageThreeOrigin + 85.0, 0, self.mapFeaturesView.bounds.size.width - 105.0, self.mapFeaturesView.bounds.size.height)];
    pageThreeLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    pageThreeLabel.textColor = [UIColor whiteColor];
    pageThreeLabel.text = NSLocalizedString(@"MAP_FEATURE_BIP", nil);
    pageThreeLabel.numberOfLines = 0;
    [self.mapFeaturesView addSubview:pageThreeLabel];
    
    UIImageView *pageThreeImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feature-bip"]];
    pageThreeImage.frame = CGRectOffset(pageThreeImage.frame, pageThreeOrigin + 20.0, floorf((self.mapFeaturesView.bounds.size.height - pageThreeImage.bounds.size.height) / 2));
    [self.mapFeaturesView addSubview:pageThreeImage];
    
    // page 4
    CGFloat pageFourOrigin = self.mapFeaturesView.bounds.size.width * 3;
    
    UILabel *pageFourTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(pageFourOrigin, 0, self.mapFeaturesView.bounds.size.width, self.mapFeaturesView.bounds.size.height - 45.0)];
    pageFourTitleLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:19.0];
    pageFourTitleLabel.textColor = [UIColor whiteColor];
    pageFourTitleLabel.text = NSLocalizedString(@"MAP_FEATURES_END", nil);
    pageFourTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.mapFeaturesView addSubview:pageFourTitleLabel];
    
    UIButton *finalActivateMapButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [finalActivateMapButton setTitle:[activateMapButton titleForState:UIControlStateNormal] forState:UIControlStateNormal];
    finalActivateMapButton.frame = CGRectOffset(activateMapButton.frame, pageFourOrigin, 0.0);
    finalActivateMapButton.titleLabel.font = activateMapButton.titleLabel.font;
    finalActivateMapButton.layer.backgroundColor = activateMapButton.layer.backgroundColor;
    [finalActivateMapButton addTarget:self action:@selector(enableMapWithAdsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.mapFeaturesView addSubview:finalActivateMapButton];
}

- (void)hideMapFeatures
{
    UIScrollView *mapFeatures = (UIScrollView *)[self.view viewWithTag:5674];
    
    [UIView animateWithDuration:0.25 delay:0 options:0 animations:^{
        mapFeatures.alpha = 0;
    } completion:^(BOOL finished) {
        [mapFeatures removeFromSuperview];
    }];
}

- (void)enableMapWithAdsButtonTapped
{
    UIAlertView *enableMapWithAdsAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ENABLE_MAP", nil) message:NSLocalizedString(@"ENABLE_MAP_ALERT_MESSAGE", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"ENABLE_MAP_ALERT_BUTTON_FREE", nil), NSLocalizedString(@"ENABLE_MAP_ALERT_BUTTON_PAID", nil), nil];
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
                
            default:
                break;
        }
    }
}

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
        
        self.mapEnabled = [OLCashier hasProduct:@"CF01"];
        self.mapMode = YES;
        
        OLGhostAlertView *thanks = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_THANK_YOU_TITLE", nil) message:NSLocalizedString(@"STORE_THANK_YOU_MESSAGE_MAP", nil)];
        thanks.position = OLGhostAlertViewPositionCenter;
        [thanks show];
        
        [mixpanel track:@"Purchased Map"];
        [mixpanel registerSuperProperties:@{@"Has Map": @"Yes"}];
    }];
}

- (void)setMapEnabled:(BOOL)mapEnabled
{
    if (!_mapEnabled && mapEnabled) {
        [self hideMapFeatures];
        
        [self.openMapButton removeTarget:self action:@selector(purchaseMap) forControlEvents:UIControlEventTouchUpInside];
        [self.openMapButton addTarget:self action:@selector(switchToMap) forControlEvents:UIControlEventTouchUpInside];
    }
    
    _mapEnabled = mapEnabled;
}

#pragma mark - Ads

- (BOOL)shouldDisplayAds
{
    return ([[NSUserDefaults standardUserDefaults] boolForKey:@"CFEnableMapWithAds"] && ![OLCashier hasProduct:@"CF01"]);
}

- (void)enableMapWithAds
{
    [self loadInterstitialAd];
    [self loadMapBannerAd];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.mapEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"CFEnableMapWithAds"];
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

#pragma mark - Tab switching

- (void)tabButtonTapped:(UIButton *)button
{
    [self selectTabButton:button];
    self.mapMode = NO;
    
    if ([button isEqual:self.codeButton]) {
        [self switchToTab:1];
    } else if ([button isEqual:self.favoritesButton]) {
        [self switchToTab:2];
    } else if ([button isEqual:self.historyButton]) {
        [self switchToTab:3];
    } else if ([button isEqual:self.moreButton]) {
        [self switchToTab:4];
    }
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

- (void)switchToTab:(int)tabNumber
{
    CGFloat newOffset = self.scrollView.frame.size.width * (1 - tabNumber);
    self.scrollView.contentOffset = CGPointMake(-newOffset, 0.0);
    
    switch (tabNumber) {
        case 2:
            [self.favoritesController.tableView flashScrollIndicators];
            break;
            
        case 3:
            [self.historyController.tableView flashScrollIndicators];
            break;
            
        case 4:
            [self.moreController.tableView flashScrollIndicators];
            break;
            
        case 1:
        default:
            break;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    [self.view endEditing:YES];
    
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    switch (page) {
        case 0:
            [self selectTabButton:self.codeButton];
            break;
            
        case 1:
            [self selectTabButton:self.favoritesButton];
            break;
            
        case 2:
            [self selectTabButton:self.historyButton];
            break;
            
        case 3:
            [self selectTabButton:self.moreButton];
            break;
            
        default:
            break;
    }
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

- (void)enterStopCodeViewDidEnterStopCode:(NSString *)stopCode
{
    [self pushStopResultsWithStopCode:stopCode];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Stop Requested" properties:@{@"Code": stopCode, @"From": @"Enter Stop Code"}];
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
        self.historyPlaceholder.hidden = NO;
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Cleared History" properties:nil];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self.mapController showDarkOverlay];
    self.smartSearchList.hidden = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.smartSearchList processSearchString:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self.mapController hideDarkOverlay];
    [self.mapController performSearchWithString:searchBar.text];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Searched in Map" properties:nil];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [UIView animateWithDuration:0.25 animations:^{
        self.smartSearchList.alpha = 0;
    } completion:^(BOOL finished) {
        self.smartSearchList.hidden = YES;
        self.smartSearchList.alpha = 1;
    }];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateKeyframesWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0.0 options:(7 << 16) animations:^{
        CGPoint center = self.enterStopCodeView.center;
        center.y -= kbSize.height - 70;
        self.enterStopCodeView.center = center;
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    
    [UIView animateKeyframesWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0.0 options:(7 << 16) animations:^{
        self.enterStopCodeView.center = self.scrollView.center;
    } completion:nil];
}

@end
