//
//  CFMainViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Mixpanel/Mixpanel.h>
#import <OLGhostAlertView/OLGhostAlertView.h>
#import "OLCashier.h"
#import "CFMainViewController.h"
#import "CFMapController.h"
#import "CFSapoClient.h"
#import "CFStopResultsViewController.h"
#import "CFEnterStopCodeView.h"
#import "CFFavoritesViewController.h"
#import "CFHistoryViewController.h"
#import "CFMoreViewController.h"

#define TAB_BAR_HEIGHT 60.0
#define TAB_BUTTON_WIDTH 75.0

@interface CFMainViewController () <UIScrollViewDelegate, UISearchBarDelegate, CFEnterStopCodeViewDelegate, CFStopTableViewDelegate, CFMapControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) CFMapController *mapController;
@property (nonatomic, strong) CFEnterStopCodeView *enterStopCodeView;
@property (nonatomic, strong) CFFavoritesViewController *favoritesController;
@property (nonatomic, strong) CFHistoryViewController *historyController;
@property (nonatomic, strong) CFMoreViewController *moreController;
@property (nonatomic, strong) UIView *favoritesPlaceholder;
@property (nonatomic, strong) UIView *historyPlaceholder;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *gripper;
@property (nonatomic, strong) UINavigationBar *localNavigationBar;
@property (nonatomic, strong) UIButton *openMapButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *tabBar;
@property (nonatomic, strong) UIButton *codeButton;
@property (nonatomic, strong) UIButton *favoritesButton;
@property (nonatomic, strong) UIButton *historyButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, assign) CGFloat initialContentCenterY;
@property (nonatomic, assign) CLLocationCoordinate2D mapLocationCoordinate;
@property (nonatomic, assign) BOOL mapMode;
@property (nonatomic, assign) BOOL mapEnabled;

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
    
    self.localNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 45.0)];
    self.localNavigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.localNavigationBar];
    
    self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    self.logoView.frame = CGRectMake(0, 26.0, self.localNavigationBar.bounds.size.width, self.logoView.bounds.size.height);
    self.logoView.contentMode = UIViewContentModeCenter;
    self.logoView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.localNavigationBar addSubview:self.logoView];
    
    self.contentView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 140.0, self.view.bounds.size.width, self.view.bounds.size.height - 140.0)];
    [self.view addSubview:self.contentView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height - TAB_BAR_HEIGHT)];
    self.scrollView.delegate = self;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * 4, self.scrollView.bounds.size.height);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.contentView addSubview:self.scrollView];
    
    CAGradientLayer *gradientMask = [CAGradientLayer layer];
    gradientMask.colors = @[(id)[UIColor colorWithWhite:0 alpha:1].CGColor, (id)[UIColor colorWithWhite:0 alpha:0].CGColor];
    gradientMask.locations = @[@0.996, @1];
    gradientMask.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width * 4, self.scrollView.bounds.size.height);
    self.scrollView.layer.mask = gradientMask;
    
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
    
    self.codeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.codeButton.frame = CGRectMake(10.0, 0, TAB_BUTTON_WIDTH, TAB_BAR_HEIGHT);
    [self.codeButton setImage:[UIImage imageNamed:@"button-code"] forState:UIControlStateNormal];
    [self.codeButton setImage:[UIImage imageNamed:@"button-code-selected"] forState:UIControlStateSelected];
    [self.codeButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.codeButton];
    
    self.favoritesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.favoritesButton.frame = CGRectMake(10.0 + TAB_BUTTON_WIDTH, 0, TAB_BUTTON_WIDTH, TAB_BAR_HEIGHT);
    [self.favoritesButton setImage:[UIImage imageNamed:@"button-favorites"] forState:UIControlStateNormal];
    [self.favoritesButton setImage:[UIImage imageNamed:@"button-favorites-selected"] forState:UIControlStateSelected];
    [self.favoritesButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.favoritesButton];
    
    self.historyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.historyButton.frame = CGRectMake(10.0 + TAB_BUTTON_WIDTH * 2, 0, TAB_BUTTON_WIDTH, TAB_BAR_HEIGHT);
    [self.historyButton setImage:[UIImage imageNamed:@"button-history"] forState:UIControlStateNormal];
    [self.historyButton setImage:[UIImage imageNamed:@"button-history-selected"] forState:UIControlStateSelected];
    [self.historyButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.historyButton];
    
    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.moreButton.frame = CGRectMake(10.0 + TAB_BUTTON_WIDTH * 3, 0, TAB_BUTTON_WIDTH, TAB_BAR_HEIGHT);
    [self.moreButton setImage:[UIImage imageNamed:@"button-more"] forState:UIControlStateNormal];
    [self.moreButton setImage:[UIImage imageNamed:@"button-more-selected"] forState:UIControlStateSelected];
    [self.moreButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.moreButton];
    
    UILongPressGestureRecognizer *clearHistory = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognized:)];
    [self.historyButton addGestureRecognizer:clearHistory];
    
    // ese booleano po
    self.mapEnabled = [OLCashier hasProduct:@"CF01"];
    
#if TARGET_IPHONE_SIMULATOR
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF01"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF02"];
    self.mapEnabled = YES;
#endif
    
    NSString *mappy = @"No";
    if (self.mapEnabled) mappy = @"Yes";
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel registerSuperProperties:@{@"Has Map": mappy}];
    [mixpanel track:@"Launched App" properties:nil];
    
    self.openMapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.openMapButton.frame = CGRectMake(0, 45.0, self.view.bounds.size.width, 95.0);
    self.openMapButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    [self.view addSubview:self.openMapButton];
    
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
    
    UILabel *favoritesPlaceholderMessage = [[UILabel alloc] initWithFrame:CGRectMake(50, favoritesPlaceholderTitle.frame.origin.y + favoritesPlaceholderTitle.bounds.size.height + verticalMargin / 2, self.favoritesPlaceholder.bounds.size.width - 100, 60)];
    favoritesPlaceholderMessage.text = NSLocalizedString(@"FAVORITES_PLACEHOLDER_MESSAGE", nil);
    favoritesPlaceholderMessage.numberOfLines = 3;
    favoritesPlaceholderMessage.textAlignment = NSTextAlignmentCenter;
    favoritesPlaceholderMessage.font = [UIFont systemFontOfSize:15.0];
    favoritesPlaceholderMessage.textColor = [UIColor colorWithWhite:0 alpha:0.4];
    [self.favoritesPlaceholder addSubview:favoritesPlaceholderMessage];
    
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
    
    UILabel *historyPlaceholderMessage = [[UILabel alloc] initWithFrame:CGRectMake(50, historyPlaceholderTitle.frame.origin.y + historyPlaceholderTitle.bounds.size.height + verticalMargin / 2, self.historyPlaceholder.bounds.size.width - 100, 60)];
    historyPlaceholderMessage.text = NSLocalizedString(@"HISTORY_PLACEHOLDER_MESSAGE", nil);
    historyPlaceholderMessage.numberOfLines = 3;
    historyPlaceholderMessage.textAlignment = NSTextAlignmentCenter;
    historyPlaceholderMessage.font = [UIFont systemFontOfSize:15.0];
    historyPlaceholderMessage.textColor = [UIColor colorWithWhite:0 alpha:0.4];
    [self.historyPlaceholder addSubview:historyPlaceholderMessage];
    
    [self.scrollView addSubview:self.historyPlaceholder];
}

- (void)viewDidLoad
{
    self.mapMode = NO;
    
    if (self.mapMode)
        self.contentView.frame = CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - 140.0);
    else {
        self.contentView.frame = CGRectMake(0, 140.0, self.view.bounds.size.width, self.view.bounds.size.height - 140.0);
        
        [self tabButtonTapped:self.codeButton];
    }
    
    if (self.mapEnabled) {
        [self.openMapButton addTarget:self action:@selector(switchToMap) forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.openMapButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        [self.openMapButton addTarget:self action:@selector(purchaseMap) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *buyMapLabel = [[UILabel alloc] initWithFrame:CGRectMake(30.0, 25.0, 260.0, 45.0)];
        buyMapLabel.font = [UIFont systemFontOfSize:18.0];
        buyMapLabel.textColor = [UIColor colorWithHue:130.0/360.0 saturation:0.9 brightness:0.9 alpha:1];
        buyMapLabel.textAlignment = NSTextAlignmentCenter;
        buyMapLabel.text = NSLocalizedString(@"BUY_MAP_BUTTON", nil);
        
        UIToolbar *buyMapBackground = [[UIToolbar alloc] initWithFrame:buyMapLabel.frame];
        buyMapBackground.barStyle = UIBarStyleBlack;
        buyMapBackground.layer.cornerRadius = 4.0;
        buyMapBackground.layer.masksToBounds = YES;
        buyMapBackground.userInteractionEnabled = NO;
        [self.openMapButton addSubview:buyMapBackground];
        [self.openMapButton addSubview:buyMapLabel];
    }
    
    BOOL runBefore = [[NSUserDefaults standardUserDefaults] boolForKey:@"OLHasRunBefore"];
    
    if (!runBefore) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"OLHasRunBefore"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self importUserData];
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
    
    if (self.isMovingToParentViewController == YES)
        [self tabButtonTapped:self.codeButton];
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
    
    CGRect contentFrame = CGRectZero;
    CGFloat scrollViewAlpha = 0.0;
    CGFloat localNavBarHeight = 0.0;
    
    if (mapMode) {
        contentFrame = CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - 140.0);
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
        
        [self.view endEditing:YES];
        
        [self.mapController.mapView setCenterCoordinate:self.mapController.mapView.userLocation.coordinate animated:YES];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Entered Map Mode" properties:nil];
        
        for (UIButton *b in self.tabBar.subviews) {
            b.selected = NO;
            b.tintColor = nil;
        }
    } else {
        contentFrame = CGRectMake(0, 140.0, self.view.bounds.size.width, self.view.bounds.size.height - 140.0);
        scrollViewAlpha = 1.0;
        localNavBarHeight = 45.0;
        self.openMapButton.hidden = NO;
        
        [self.localNavigationBar popNavigationItemAnimated:YES];
        
        CLLocationCoordinate2D center = self.mapController.mapView.userLocation.coordinate;
        center.latitude -= self.mapController.mapView.region.span.latitudeDelta * 0.36;
        [self.mapController.mapView setCenterCoordinate:center animated:YES];
    }
    
    [UIView animateWithDuration:0.33 delay:0.0 options:(7 >> 16) animations:^{
        self.contentView.frame = contentFrame;
        self.scrollView.alpha = scrollViewAlpha;
        self.logoView.alpha = scrollViewAlpha;
        self.gripper.alpha = scrollViewAlpha;
        self.localNavigationBar.frame = CGRectMake(0, 0, self.localNavigationBar.bounds.size.width, localNavBarHeight);
        self.openMapButton.frame = CGRectMake(0, 45.0, self.view.bounds.size.width, 95.0);
        self.openMapButton.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)switchToMap
{
    self.mapMode = YES;
}

- (void)switchFromMap
{
    self.mapMode = NO;
}

- (void)handleGripDragGesture:(UIPanGestureRecognizer *)recognizer
{
    CGFloat gripTranslation = [recognizer translationInView:self.contentView].y;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.initialContentCenterY = self.contentView.center.y;
        self.mapLocationCoordinate = self.mapController.mapView.userLocation.coordinate;
        
        [self.view endEditing:YES];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Used Map Drag Gesture" properties:nil];
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint contentCenter;
        contentCenter.x = self.contentView.center.x;
        contentCenter.y = self.initialContentCenterY + gripTranslation;
        
        CLLocationCoordinate2D mapCenter = self.mapLocationCoordinate;
        
        CGFloat buttonHeight = 95.0 + gripTranslation;
        
        CGFloat slideFactor = gripTranslation / (self.contentView.bounds.size.height - TAB_BAR_HEIGHT);
        CGFloat appliedFactor = 1.0 - slideFactor;
        
        if (slideFactor <= 1.0 && slideFactor >= 0.0) {
            self.openMapButton.frame = CGRectMake(0, 45.0, self.view.bounds.size.width, buttonHeight);
            self.contentView.center = contentCenter;
            self.scrollView.alpha = appliedFactor;
            self.gripper.alpha = appliedFactor;
//            self.openMapButton.alpha = appliedFactor;
            mapCenter.latitude -= self.mapController.mapView.region.span.latitudeDelta * (0.36 * appliedFactor);
            self.mapController.mapView.centerCoordinate = mapCenter;
        }
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat slideFactor = gripTranslation / (self.contentView.bounds.size.height - TAB_BAR_HEIGHT);
        
        if (self.mapEnabled) {
            if (slideFactor >=0.25) {
                self.mapMode = YES;
            } else {
                self.mapMode = NO;
            }
        } else {
            self.mapMode = NO;
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
        [UIView animateWithDuration:0.2 animations:^{
            self.openMapButton.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [self.openMapButton removeTarget:self action:@selector(purchaseMap) forControlEvents:UIControlEventTouchUpInside];
            for (UIView *subview in self.openMapButton.subviews) {
                [subview removeFromSuperview];
            }
            self.openMapButton.backgroundColor = [UIColor clearColor];
            [self.openMapButton addTarget:self action:@selector(switchToMap) forControlEvents:UIControlEventTouchUpInside];
        }];
    }
    
    _mapEnabled = mapEnabled;
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
    button.tintColor = [UIColor colorWithHue:130.0/360.0 saturation:0.9 brightness:0.9 alpha:1];
    
    BOOL didKillImageView = NO;
    for (UIView *view in button.subviews) {
        if ([view isKindOfClass:[UIImageView class]] && !didKillImageView) {
            view.hidden = YES;
            didKillImageView = YES;
        }
    }
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

#pragma mark - Push stop results

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
    NSLog(@"index: %d", buttonIndex);
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
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self.mapController hideDarkOverlay];
    [self.mapController performSearchWithString:searchBar.text];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Searched in Map" properties:nil];
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
