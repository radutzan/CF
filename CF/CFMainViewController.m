//
//  CFMainViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <OLGhostAlertView/OLGhostAlertView.h>

#import "CFMainViewController.h"
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

@interface CFMainViewController () <CFMapControllerDelegate, CFDrawerControllerDelegate, CFSearchControllerDelegate, CFStopResultsViewControllerDelegate, CFServiceRouteBarDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) CFMapController *mapController;
@property (nonatomic, strong) CFDrawerController *drawerController;
@property (nonatomic, strong) CFSearchController *searchController;
@property (nonatomic, strong) CFStopResultsViewController *stopResultsController;
@property (nonatomic, strong) NSMutableArray *serviceRouteBars;

@property (nonatomic, strong) UINavigationBar *localNavigationBar;
@property (nonatomic, strong) OLShapeTintedButton *locationButton;
@property (nonatomic, strong) NSArray *rightBarButtonItems;

@property (nonatomic, assign) CGFloat topContentMargin;
@property (nonatomic, assign) CGFloat bottomContentMargin;
@property (nonatomic, assign) CGPoint storedDismissingViewCenter;

@property (nonatomic, assign) BOOL shouldDisplayAds;

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
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
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
//    self.localNavigationBar.barStyle = UIBarStyleBlack;
    [self.view addSubview:self.localNavigationBar];
    
    CFSearchField *searchField = [[CFSearchField alloc] initWithFrame:CGRectMake(8.0, 20.0, self.localNavigationBar.bounds.size.width - 70.0, 44.0)];
    searchField.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    searchField.placeholder = NSLocalizedString(@"MAP_SEARCHFIELD_PLACEHOLDER", nil);
    self.searchController.searchField = searchField;
    [self.localNavigationBar addSubview:searchField];
    
    self.topContentMargin = self.localNavigationBar.bounds.size.height;
    self.bottomContentMargin = TAB_BAR_HEIGHT;
    
    self.locationButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    [self.locationButton setImage:[[UIImage imageNamed:@"location"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.locationButton setImage:[[UIImage imageNamed:@"location-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    [self.locationButton addTarget:self action:@selector(goToUserLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.locationButton sizeToFit];
    UIBarButtonItem *locationButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.locationButton];
    
    UINavigationItem *navItem = [UINavigationItem new];
    navItem.rightBarButtonItems = @[locationButtonItem];
    
    self.rightBarButtonItems = navItem.rightBarButtonItems;
    
    [self.localNavigationBar pushNavigationItem:navItem animated:NO];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF01"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CF02"];
//#if TARGET_IPHONE_SIMULATOR
//    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CF01"];
//    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CF02"];
//#endif
//    
//#ifdef DEV_VERSION
//    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CF01"];
//    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CF02"];
//#endif
    
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
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL runBefore = [defaults boolForKey:@"OLHasRunBefore"];
    
    if (!runBefore) {
        [defaults setBool:YES forKey:@"OLHasRunBefore"];
        [defaults synchronize];
        
        [self importUserData];
    }
    
    BOOL performedInitialCloudSync = [defaults boolForKey:@"OLHasPerformedInitialCloudSync"];
    
    if (!performedInitialCloudSync) {
        [defaults setBool:YES forKey:@"OLHasPerformedInitialCloudSync"];
        
        NSArray *favoritesArray = [defaults arrayForKey:@"favorites"];
        if (!favoritesArray) return;
        
        [[NSUbiquitousKeyValueStore defaultStore] setArray:favoritesArray forKey:@"favorites"];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self reloadUserData];
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

#pragma mark - Layout and more

- (void)setTopContentMargin:(CGFloat)topContentMargin
{
    _topContentMargin = topContentMargin;
    
    self.searchController.contentInset = UIEdgeInsetsMake(topContentMargin, self.searchController.contentInset.left, self.searchController.contentInset.bottom, self.searchController.contentInset.right);
    self.mapController.contentInset = UIEdgeInsetsMake(topContentMargin, self.mapController.contentInset.left, self.mapController.contentInset.bottom, self.mapController.contentInset.right);
}

- (void)setBottomContentMargin:(CGFloat)bottomContentMargin
{
    _bottomContentMargin = bottomContentMargin;
    
    self.searchController.contentInset = UIEdgeInsetsMake(self.searchController.contentInset.top, self.searchController.contentInset.left, bottomContentMargin, self.searchController.contentInset.right);
    self.mapController.contentInset = UIEdgeInsetsMake(self.mapController.contentInset.top, self.mapController.contentInset.left, bottomContentMargin, self.mapController.contentInset.right);
}

- (void)goToUserLocation
{
    [self.mapController setInitialRegionAnimated:YES];
    self.locationButton.selected = YES;
}

- (void)mapControllerMapViewRegionDidChange
{
    CGFloat epsilon = 0.0005;
    
    if (fabs(self.mapController.mapView.centerCoordinate.latitude - self.mapController.mapView.userLocation.coordinate.latitude) <= epsilon && fabs(self.mapController.mapView.centerCoordinate.longitude - self.mapController.mapView.userLocation.coordinate.longitude) <= epsilon) {
        self.locationButton.selected = YES;
    } else {
        self.locationButton.selected = NO;
    }
}

#pragma mark - Search

- (void)searchControllerWillHide
{
    if (self.stopResultsController.displayMode == CFStopResultsDisplayModeContained) {
        [self.stopResultsController dismiss];
    }
}

- (void)searchControllerDidBeginSearching
{
    [self.localNavigationBar.topItem setRightBarButtonItems:@[] animated:YES];
    self.drawerController.drawerOpen = NO;
}

- (void)searchControllerDidEndSearching
{
    [self.localNavigationBar.topItem setRightBarButtonItems:self.rightBarButtonItems animated:YES];
}

- (void)searchControllerNeedsStopCardForStop:(CFStop *)stop
{
    [self.stopResultsController containOnRect:CGRectMake(10.0, self.topContentMargin + 10.0, self.searchController.bounds.size.width - 20.0, self.searchController.containerView.bounds.size.height - 20.0) onViewController:self];
    self.stopResultsController.stop = stop;
}

- (void)searchControllerDidClearStopSuggestions
{
    if (self.stopResultsController.displayMode == CFStopResultsDisplayModeContained) {
        [self.stopResultsController dismiss];
    }
}

- (void)searchControllerRequestedStop:(CFStop *)stop
{
    self.stopResultsController.stop = stop;
    [self.stopResultsController presentOnViewController:self];
}

- (void)searchControllerRequestedLocalSearch:(NSString *)searchString
{
    [self.mapController performSearchWithString:searchString];
}

- (void)searchControllerDidSelectService:(CFService *)service direction:(CFDirection)direction
{
    [self showServiceRouteForService:service direction:direction];
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

- (void)stopResultsViewWasPromotedFromContainment
{
    [self.searchController hide];
    [self.searchController.searchField clear];
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
    [self.stopResultsController presentOnViewController:self];
    self.drawerController.drawerOpen = NO;
}

- (void)processExternalURL:(NSURL *)url
{
    NSLog(@"%@", [url absoluteString]);
    
    if ([url.host isEqualToString:@"stop"]) {
        NSString *stopCode = url.lastPathComponent;
        [self pushStopResultsWithStopCode:stopCode];
    }
}

- (void)drawerDidSelectCellWithStop:(NSString *)stopCode
{
    [self pushStopResultsWithStopCode:stopCode];
}

- (void)mapControllerDidSelectStop:(CFStop *)stop
{
    CGRect originRect = [self.view convertRect:self.mapController.stopCalloutView.contentView.frame fromView:self.mapController.stopCalloutView];
    self.stopResultsController.stop = stop;
    [self.stopResultsController presentFromRect:originRect onViewController:self];
    self.drawerController.drawerOpen = NO;
}

- (void)stopResultsViewControllerDidUpdateUserData
{
    [self reloadUserData];
    if (self.mapController.mapMode == CFMapModeStops) [self.mapController reloadStops];
}

#pragma mark - Push service routes

- (void)stopResultsViewControllerDidRequestServiceRoute:(NSString *)serviceName directionString:(NSString *)directionString
{
    [self showServiceRoute:serviceName directionString:directionString];
}

- (void)showServiceRoute:(NSString *)serviceName directionString:(NSString *)directionString
{
    self.mapController.showActivityIndicator = YES;
    
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
    if (self.mapController.mapMode == CFMapModeServiceRoute && self.mapController.currentServiceName == service.name && self.mapController.currentDirection == direction) return;
    
    [self.mapController displayServiceRoute:service.name direction:direction];
    [self showServiceRouteBarWithService:service selectedDirection:direction];
}

- (void)showServiceRouteBarWithService:(CFService *)service selectedDirection:(CFDirection)direction
{
    CFServiceRouteBar *serviceBar;
    BOOL didFindABar = NO;
    
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[CFServiceRouteBar class]]) {
            CFServiceRouteBar *possibleBar = (CFServiceRouteBar *)subview;
            if ([possibleBar.service isEqualToService:service]) {
                didFindABar = YES;
                serviceBar = possibleBar;
            } else {
                // this should change when more bars are supported at once
                [self clearServiceRouteBarAnimated:YES];
            }
        }
    }
    
    if (!didFindABar) {
        serviceBar = [[CFServiceRouteBar alloc] initWithFrame:CGRectMake(0, self.topContentMargin, self.view.bounds.size.width, 44.0)];
        serviceBar.service = service;
        serviceBar.dismissible = YES;
        serviceBar.delegate = self;
        serviceBar.alpha = 0;
        [self.view insertSubview:serviceBar aboveSubview:self.searchController];
        
        UIView *serviceBarBackground;
        if (NSClassFromString(@"UIVisualEffectView")) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
            
            serviceBarBackground = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            serviceBarBackground.frame = serviceBar.bounds;
        } else {
            serviceBarBackground = [[UINavigationBar alloc] initWithFrame:serviceBar.bounds];
            serviceBarBackground.clipsToBounds = YES;
        }
        [serviceBar insertSubview:serviceBarBackground atIndex:0];
        
//        serviceBar.center = CGPointMake(serviceBar.center.x, serviceBar.center.y - serviceBar.bounds.size.height);
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
            serviceBar.alpha = 1;
//            serviceBar.center = CGPointMake(serviceBar.center.x, serviceBar.center.y + serviceBar.bounds.size.height);
        } completion:^(BOOL finished) {
            self.topContentMargin += serviceBar.bounds.size.height;
        }];
        
        UIPanGestureRecognizer *dismissRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalDismissPanGesture:)];
        [serviceBar addGestureRecognizer:dismissRecognizer];
    }
    
    serviceBar.selectedDirection = direction;
}

- (void)serviceRouteBar:(CFServiceRouteBar *)serviceRouteBar selectedButtonAtIndex:(NSUInteger)index service:(CFService *)service
{
    [self showServiceRouteForService:service direction:(index ? CFDirectionInward : CFDirectionOutward)];
}

- (void)clearServiceRouteBarAnimated:(BOOL)animated
{
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[CFServiceRouteBar class]]) {
            self.topContentMargin -= subview.bounds.size.height;
            
            if (animated) {
                [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
                    subview.alpha = 0;
                    subview.center = CGPointMake(subview.center.x, subview.center.y - subview.bounds.size.height);
                } completion:^(BOOL finished) {
                    [subview removeFromSuperview];
                }];
            } else {
                [subview removeFromSuperview];
            }
        }
    }
}

- (void)clearServiceRouteAnimated:(BOOL)animated
{
    [self clearServiceRouteBarAnimated:animated];
    [self.mapController displayStops];
}

- (void)serviceRouteBarDidDismiss:(CFServiceRouteBar *)serviceRouteBar
{
    [self clearServiceRouteAnimated:YES];
}

- (void)handleHorizontalDismissPanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGFloat moveDiff = [recognizer translationInView:self.view].x;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.view endEditing:YES];
        self.storedDismissingViewCenter = recognizer.view.center;
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (moveDiff >= 0) {
            // moving to the right
            recognizer.view.center = CGPointMake(self.storedDismissingViewCenter.x + moveDiff, recognizer.view.center.y);
        } else {
            recognizer.view.center = CGPointMake(self.storedDismissingViewCenter.x + moveDiff * 0.25, recognizer.view.center.y);
        }
        
    } else {
        CGFloat terminalVelocity = MIN([recognizer velocityInView:self.view].x, 3500);
        CGFloat velocityFactor = fabs(terminalVelocity / 3500);
        
        if (terminalVelocity > 250 || moveDiff > 80) {
            CGFloat animationDuration = 0.45 * (1 - velocityFactor);
            
            [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:velocityFactor options:0 animations:^{
                recognizer.view.center = CGPointMake(recognizer.view.center.x + self.view.bounds.size.width, recognizer.view.center.y);
            } completion:^(BOOL finished) {
                if ([recognizer.view isKindOfClass:[CFServiceRouteBar class]]) {
                    [self clearServiceRouteAnimated:NO];
                } else {
                    self.topContentMargin -= recognizer.view.bounds.size.height;
                    [recognizer.view removeFromSuperview];
                }
            }];
        } else {
            [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:velocityFactor options:0 animations:^{
                recognizer.view.center = CGPointMake(self.storedDismissingViewCenter.x, recognizer.view.center.y);
            } completion:nil];
        }
    }
}

@end
