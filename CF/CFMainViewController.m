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
#import "CFDrawerController.h"
#import "CFSearchField.h"
#import "CFSearchController.h"
#import "CFStopResultsViewController.h"
#import "CFServiceRouteViewController.h"
#import "CFWhatsNewViewController.h"

#import "CFService.h"
#import "CFServiceRouteBar.h"

#import "OLShapeTintedButton.h"
#import "GADBannerView.h"

@interface CFMainViewController () <CFMapControllerDelegate, CFDrawerControllerDelegate, CFSearchControllerDelegate, CFStopResultsViewControllerDelegate, CFServiceRouteBarDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) CFMapController *mapController;
@property (nonatomic, strong) CFDrawerController *drawerController;
@property (nonatomic, strong) CFSearchController *searchController;
@property (nonatomic, strong) CFStopResultsViewController *stopResultsController;

@property (nonatomic, strong) UINavigationBar *localNavigationBar;
@property (nonatomic, strong) NSArray *rightBarButtonItems;

@property (nonatomic, assign) CGFloat topContentMargin;
@property (nonatomic, assign) CGFloat bottomContentMargin;

@property (nonatomic, assign) BOOL shouldDisplayAds;
@property (nonatomic, strong) GADBannerView *mapBannerAd;

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
    
    self.drawerController = [CFDrawerController new];
    self.drawerController.delegate = self;
    [self addChildViewController:self.drawerController];
    [self.view addSubview:self.drawerController.view];
    
    self.searchController = [[CFSearchController alloc] initWithFrame:self.view.bounds];
    self.searchController.delegate = self;
    self.searchController.contentInset = UIEdgeInsetsMake(64.0, 0, TAB_BAR_HEIGHT, 0);
    [self.view addSubview:self.searchController];
    
    self.localNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64.0)];
    self.localNavigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.localNavigationBar];
    
    CFSearchField *searchField = [[CFSearchField alloc] initWithFrame:CGRectMake(0, 0, 300, 44.0)];
    searchField.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    searchField.placeholder = NSLocalizedString(@"MAP_SEARCHFIELD_PLACEHOLDER", nil);
    self.searchController.searchField = searchField;
    
    self.topContentMargin = 64.0;
    self.bottomContentMargin = TAB_BAR_HEIGHT;
    
    UIBarButtonItem *bipButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-bip"] style:UIBarButtonItemStylePlain target:self.mapController action:@selector(goToNearestBipSpot)];
    MKUserTrackingBarButtonItem *tracky = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapController.mapView];
    
    UINavigationItem *navItem = [UINavigationItem new];
    navItem.titleView = searchField;
    navItem.rightBarButtonItems = @[tracky];
    
    self.rightBarButtonItems = navItem.rightBarButtonItems;
    
    [self.localNavigationBar pushNavigationItem:navItem animated:NO];
    
#if TARGET_IPHONE_SIMULATOR
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF01"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF02"];
#endif
    
#ifdef DEV_VERSION
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CF01"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF02"];
#endif
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *mappy = @"Yes";
    NSString *freeMap = ([[NSUserDefaults standardUserDefaults] boolForKey:@"CFEnableMapWithAds"])? @"Yes" : @"No";
    
    [mixpanel registerSuperProperties:@{@"Has Map": mappy}];
    [mixpanel registerSuperProperties:@{@"Has Free Map": freeMap}];
    
    self.stopResultsController = [CFStopResultsViewController new];
    self.stopResultsController.delegate = self;
    
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
    [self.drawerController reloadUserData];
}

#pragma mark - Search

- (void)searchControllerDidBeginSearching
{
    [self.localNavigationBar.topItem setRightBarButtonItems:@[] animated:YES];
    self.drawerController.drawerOpen = NO;
}

- (void)searchControllerDidEndSearching
{
    [self.localNavigationBar.topItem setRightBarButtonItems:self.rightBarButtonItems animated:YES];
}

- (void)searchControllerRequestedLocalSearch:(NSString *)searchString
{
    [self.mapController performSearchWithString:searchString];
}

- (void)searchControllerDidSelectStop:(NSString *)stopCode
{
    [self pushStopResultsWithStopCode:stopCode];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Stop Requested" properties:@{@"Code": stopCode, @"From": @"Smart Search Results"}];
}

- (void)searchControllerDidSelectService:(CFService *)service direction:(CFDirection)direction
{
    [self showServiceRouteForService:service direction:direction];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Service Route Requested" properties:@{@"Service": service.name, @"From": @"Smart Search Results"}];
}

- (void)searchControllerDidSelectService:(CFService *)service directionString:(NSString *)directionString
{
    [self showServiceRoute:service.name directionString:directionString];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Service Route Requested" properties:@{@"Service": service.name, @"From": @"Smart Search Results"}];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateKeyframesWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0.0 options:(7 << 16) animations:^{
        self.bottomContentMargin = keyboardRect.size.height;
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    
    [UIView animateKeyframesWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0.0 options:(7 << 16) animations:^{
        self.bottomContentMargin = TAB_BAR_HEIGHT;
    } completion:nil];
}

- (void)setTopContentMargin:(CGFloat)topContentMargin
{
    _topContentMargin = topContentMargin;
    
    self.searchController.contentInset = UIEdgeInsetsMake(topContentMargin, self.searchController.contentInset.left, self.searchController.contentInset.bottom, self.searchController.contentInset.right);
}

- (void)setBottomContentMargin:(CGFloat)bottomContentMargin
{
    _bottomContentMargin = bottomContentMargin;
    
    self.searchController.contentInset = UIEdgeInsetsMake(self.searchController.contentInset.top, self.searchController.contentInset.left, bottomContentMargin, self.searchController.contentInset.right);
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
    
    self.stopResultsController.stopCode = stopCode;
    [self.stopResultsController presentFromViewController:self];
    self.drawerController.drawerOpen = NO;
}

- (void)drawerDidSelectCellWithStop:(NSString *)stopCode
{
    [self pushStopResultsWithStopCode:stopCode];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Stop Requested" properties:@{@"Code": stopCode, @"From": @"History or Favorites"}];
}

- (void)mapControllerDidSelectStop:(NSString *)stopCode
{
    CGRect originRect = [self.view convertRect:self.mapController.stopCalloutView.contentView.frame fromView:self.mapController.stopCalloutView];
    NSLog(@"origin.x: %f, origin.y: %f, width: %f, height: %f", originRect.origin.x, originRect.origin.y, originRect.size.width, originRect.size.height);
    
    self.stopResultsController.stopCode = stopCode;
    [self.stopResultsController presentFromRect:originRect fromViewController:self];
    self.drawerController.drawerOpen = NO;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Stop Requested" properties:@{@"Code": stopCode, @"From": @"Map"}];
}

- (void)stopResultsViewControllerDidUpdateUserData
{
    [self reloadUserData];
}

#pragma mark - Push service routes

- (void)stopResultsViewControllerDidRequestServiceRoute:(NSString *)serviceName directionString:(NSString *)directionString
{
    [self showServiceRoute:serviceName directionString:directionString];
}

- (void)showServiceRoute:(NSString *)serviceName directionString:(NSString *)directionString
{
    [[CFSapoClient sharedClient] serviceInfoForService:serviceName handler:^(NSError *error, NSArray *result) {
        if (result) {
            CFDirection finalDirection;
            NSDictionary *serviceInfo = [result objectAtIndex:0];
            NSString *responseIda = [serviceInfo objectForKey:@"ida"];
            NSString *localizedTo = NSLocalizedString(@"TO_DIRECTION", nil);
            NSString *comparableDirectionString = [[directionString stringByReplacingCharactersInRange:NSMakeRange(0, localizedTo.length + 1) withString:@""] uppercaseString];
            
            if ([comparableDirectionString isEqualToString:responseIda]) {
                finalDirection = CFDirectionOutward;//NSLog(@"CFDirectionOutward");
            } else {
                finalDirection = CFDirectionInward;//NSLog(@"CFDirectionInward");
            }
            
            [self showServiceRouteForService:[CFService serviceWithName:serviceName outwardDirectionName:[serviceInfo objectForKey:@"ida"] inwardDirectionName:[serviceInfo objectForKey:@"regreso"]] direction:finalDirection];
        }
    }];
}

- (void)showServiceRouteForService:(CFService *)service direction:(CFDirection)direction
{
    [self.mapController displayServiceRoute:service.name direction:direction];
    
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[CFServiceRouteBar class]]) {
            [subview removeFromSuperview];
        }
    }
    
    [self showServiceRouteBarWithService:service];
}

- (void)showServiceRouteBarWithService:(CFService *)service
{
    CFServiceRouteBar *serviceBar = [[CFServiceRouteBar alloc] initWithFrame:CGRectMake(0, self.localNavigationBar.bounds.size.height, self.view.bounds.size.width, 44.0)];
    serviceBar.service = service;
    serviceBar.delegate = self;
    [self.view insertSubview:serviceBar aboveSubview:self.searchController];
    
    UINavigationBar *serviceBarBackground = [[UINavigationBar alloc] initWithFrame:serviceBar.bounds];
    [serviceBar insertSubview:serviceBarBackground atIndex:0];
    
    UIButton *clearServiceRouteButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [clearServiceRouteButton addTarget:self action:@selector(clearServiceRoute) forControlEvents:UIControlEventTouchUpInside];
    [serviceBar addSubview:clearServiceRouteButton];
    
    self.topContentMargin += serviceBar.bounds.size.height;
}

- (void)serviceRouteBarSelectedButtonAtIndex:(NSUInteger)index service:(CFService *)service
{
    [self showServiceRouteForService:service direction:(index ? CFDirectionInward : CFDirectionOutward)];
}

- (void)clearServiceRoute
{
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[CFServiceRouteBar class]]) {
            self.topContentMargin -= subview.bounds.size.height;
            [subview removeFromSuperview];
        }
    }
    
    [self.mapController displayStops];
}

#pragma mark - Commerce and Ads

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
    [self loadMapBannerAd];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CFEnableMapWithAds"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Enabled Map With Ads"];
    [mixpanel registerSuperProperties:@{@"Has Map": @"Yes"}];
    [mixpanel registerSuperProperties:@{@"Has Free Map": @"Yes"}];
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

@end