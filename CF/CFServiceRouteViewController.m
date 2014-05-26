//
//  CFServiceRouteViewController.m
//  CF
//
//  Created by Radu Dutzan on 5/18/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFServiceRouteViewController.h"
#import "CFStop.h"
#import "CFRoute.h"

#import "CFStopSignView.h"
#import "CustomPinAnnotationView.h"
#import "CFStopResultsViewController.h"

#import "GADBannerView.h"
#import "OLCashier.h"

@import MapKit;

@interface CFServiceRouteViewController () <MKMapViewDelegate, SMCalloutViewDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UINavigationBar *notANavigationBar;
@property (assign) CFStop *selectedStop;
@property (nonatomic, strong) SMCalloutView *stopCalloutView;
@property (nonatomic, strong) UISegmentedControl *directionSwitcher;
@property (nonatomic, assign) BOOL regionSet;

@property (nonatomic, strong) NSString *currentService;
@property (nonatomic, assign) CFDirection currentDirection;
@property (nonatomic, strong) NSString *directionString;
@property (nonatomic, strong) CFRoute *route;

@property (nonatomic, strong) GADBannerView *mapBannerAd;

@end

@implementation CFServiceRouteViewController

static MKMapRect santiagoBounds;

- (id)initWithService:(NSString *)service direction:(CFDirection)direction
{
    self = [super init];
    if (self) {
        self.currentService = service;
        self.currentDirection = direction;
        
        self.title = service;
        self.navigationItem.backBarButtonItem.title = @"";
    }
    return self;
}

- (id)initWithService:(NSString *)service
{
    self = [self initWithService:service direction:CFDirectionOutward];
    return self;
}

- (id)initWithService:(NSString *)service directionString:(NSString *)directionString
{
    self = [super init];
    if (self) {
        self.currentService = service;
        self.directionString = directionString;
        
        self.title = service;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.showsPointsOfInterest = NO;
    self.mapView.showsBuildings = YES;
    [self.view addSubview:self.mapView];
    
    self.regionSet = NO;
    
    self.stopCalloutView = [SMCalloutView new];
    self.stopCalloutView.delegate = self;
    self.stopCalloutView.constrainedInsets = UIEdgeInsetsMake(64.0, 0, 45.0, 0);
    self.stopCalloutView.permittedArrowDirection = SMCalloutArrowDirectionAny;
    
    CGFloat segmentWidth = 135.0;
    self.directionSwitcher = [[UISegmentedControl alloc] initWithItems:@[@"Ida", @"Vuelta"]];
    self.directionSwitcher.selectedSegmentIndex = self.currentDirection;
    [self.directionSwitcher setWidth:segmentWidth forSegmentAtIndex:0];
    [self.directionSwitcher setWidth:segmentWidth forSegmentAtIndex:1];
    [self.directionSwitcher addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.directionSwitcher];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[spaceItem, segmentedControlItem, spaceItem];
    
    MKUserTrackingBarButtonItem *tracky = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    self.navigationItem.rightBarButtonItem = tracky;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MKMapPoint upperLeft = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-33.259, -70.939));
        MKMapPoint lowerRight = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-33.674, -70.391));
        
        santiagoBounds = MKMapRectMake(upperLeft.x, upperLeft.y, lowerRight.x-upperLeft.x, lowerRight.y-upperLeft.y);
    });
    
    [self drawPolylineForService:self.currentService direction:self.currentDirection];
    
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backButtonItem];
    
    if (![OLCashier hasProduct:@"CF01"] && ![OLCashier hasProduct:@"CF02"]) {
        [self loadMapBannerAd];
        [self.view addSubview:self.mapBannerAd];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[CFSapoClient sharedClient] serviceInfoForService:self.currentService handler:^(NSError *error, NSArray *result) {
        if (result) {
            NSDictionary *resultDictionary = [result objectAtIndex:0];
            NSString *outwardName = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [[resultDictionary objectForKey:@"ida"] capitalizedString]];
            NSString *inwardName = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [[resultDictionary objectForKey:@"regreso"] capitalizedString]];
//            NSLog(@"%@, %@", outwardName, inwardName);
            [self.directionSwitcher setTitle:outwardName forSegmentAtIndex:0];
            [self.directionSwitcher setTitle:inwardName forSegmentAtIndex:1];
        }
    }];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setToolbarHidden:YES];
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl
{
    if (segmentedControl.selectedSegmentIndex == 0) {
        self.currentDirection = CFDirectionOutward;
    } else {
        self.currentDirection = CFDirectionInward;
    }
}

- (void)setDefaultRegion
{
    CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake(-33.444117, -70.651055);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(startCoordinate, 400, 400)];
    [self.mapView setRegion:adjustedRegion animated:NO];
}

- (void)loadMapBannerAd
{
    GADRequest *request = [GADRequest request];
    request.testDevices = @[@"61abccb6c029497b02bef4224933c76b", GAD_SIMULATOR_ID];
    
    self.mapBannerAd = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    self.mapBannerAd.adUnitID = @"ca-app-pub-6226087428684107/7036992874";
    self.mapBannerAd.rootViewController = self;
    self.mapBannerAd.frame = CGRectMake(0, self.view.bounds.size.height - self.navigationController.toolbar.bounds.size.height - self.mapBannerAd.bounds.size.height, self.mapBannerAd.bounds.size.width, self.mapBannerAd.bounds.size.height);
    [self.mapBannerAd loadRequest:request];
}

#pragma mark - Cuantofaltism

- (void)drawPolylineForService:(NSString *)service direction:(CFDirection)direction
{
    [self.mapView removeOverlays:self.mapView.overlays];
    [self clearAnnotations];
    
    [[CFSapoClient sharedClient] routeForBusService:service direction:direction handler:^(NSError *error, NSArray *result) {
        if (error || [result count] == 0) {
            UIAlertView *nope = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SERVICE_ROUTE_ERROR_ALERT_TITLE", nil) message:NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
            [nope show];
            return;
        }
        
        NSMutableArray *stops = [NSMutableArray arrayWithCapacity:result.count];
        CLLocationCoordinate2D *coordinates = malloc(sizeof(CLLocationCoordinate2D) * result.count);
        NSUInteger i = 0;
        
        for (NSDictionary *dataPoint in result) {
            CLLocationCoordinate2D coordinate;
            coordinate.latitude = [[dataPoint objectForKey:@"latitude"] doubleValue];
            coordinate.longitude = [[dataPoint objectForKey:@"longitude"] doubleValue];
            NSString *name = [dataPoint objectForKey:@"nombre"];
            
            if (name != nil) {
                //Its a bus stop
                CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[dataPoint objectForKey:@"codigo"] name:name services:[dataPoint objectForKey:@"recorridos"]];
                [stops addObject:stop];
            }
            
            coordinates[i] = coordinate;
            i++;
        }
        
        CFRoute *route = [CFRoute routeWithServiceName:service stops:stops routeCoordinates:coordinates count:result.count];
        self.route = route;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
            [self.mapView addAnnotations:stops];
            
            if (i == result.count && !self.regionSet) {
                MKCoordinateRegion adjustedRegion;
                
                if (self.mapView.userLocation && MKMapRectContainsPoint(santiagoBounds, MKMapPointForCoordinate(self.mapView.userLocation.coordinate))) {
                    adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1400, 1400)];
                } else {
                    CFStop *middleAnnotation = [stops objectAtIndex:floorf(stops.count / 2)];
                    adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(middleAnnotation.coordinate, 1400, 1400)];
                }
                
                [self.mapView setRegion:adjustedRegion];
                self.regionSet = YES;
            }
        });
    }];
}

- (void)setCurrentDirection:(CFDirection)currentDirection
{
    if (currentDirection != _currentDirection) {
        [self clearAnnotations];
        [self drawPolylineForService:self.currentService direction:currentDirection];
    }
    
    _currentDirection = currentDirection;
}

- (void)setDirectionString:(NSString *)directionString
{
    [[CFSapoClient sharedClient] serviceInfoForService:self.currentService handler:^(NSError *error, NSArray *result) {
        if (result) {
            CFDirection finalDirection;
            NSDictionary *resultDictionary = [result objectAtIndex:0];
            NSString *responseIda = [resultDictionary objectForKey:@"ida"];
//            NSString *responseRegreso = [resultDictionary objectForKey:@"regreso"];
            NSString *localizedTo = NSLocalizedString(@"TO_DIRECTION", nil);
            NSString *comparableDirectionString = [[directionString stringByReplacingCharactersInRange:NSMakeRange(0, localizedTo.length + 1) withString:@""] uppercaseString];
//            NSLog(@"%@", responseIda);
//            NSLog(@"%@", responseRegreso);
//            NSLog(@"%@", comparableDirectionString);
            
            if ([comparableDirectionString isEqualToString:responseIda]) {
                finalDirection = CFDirectionOutward;//NSLog(@"CFDirectionOutward");
            } else {
                finalDirection = CFDirectionInward;//NSLog(@"CFDirectionInward");
            }
            
            self.directionSwitcher.selectedSegmentIndex = finalDirection;
            self.currentDirection = finalDirection;
            
            [self drawPolylineForService:self.currentService direction:self.currentDirection];
        }
    }];
}

- (void)clearAnnotations
{
    id userLocation = [self.mapView userLocation];
    
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[self.mapView annotations]];
    
    if (userLocation) {
        [pins removeObject:userLocation];
    }
    
    [self.mapView removeAnnotations:pins];
    pins = nil;
}

- (void)stopCalloutTapped
{
    CFStopResultsViewController *stopResultsVC = [[CFStopResultsViewController alloc] initWithStyle:UITableViewStylePlain];
    stopResultsVC.stopCode = self.selectedStop.code;
    
    [self.navigationController pushViewController:stopResultsVC animated:YES];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
//    [self setDefaultRegion];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[CFStop class]]) {
        CFStop *stopAnnotation = (CFStop *)annotation;
        if (stopAnnotation.isFavorite) {
            static NSString *identifier = @"FavoriteBusStop";
            MKAnnotationView *favPin = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
            
            if (!favPin) {
                favPin = [[CustomPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
                [favPin setCanShowCallout:NO];
                [favPin setImage:[UIImage imageNamed:@"pin-favorite"]];
                
            } else {
                [favPin setAnnotation:annotation];
            }
            
            return favPin;
            
        } else {
            static NSString *identifier = @"BusStop";
            MKAnnotationView *stopPin = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
            
            if (!stopPin) {
                stopPin = [[CustomPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
                [stopPin setCanShowCallout:NO];
                [stopPin setImage:[UIImage imageNamed:@"pin-stop"]];
                
            } else {
                [stopPin setAnnotation:annotation];
            }
            
            return stopPin;
        }
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[CFStop class]]) {
        self.selectedStop = (CFStop *)view.annotation;
        
        if (self.stopCalloutView.window)
            [self.stopCalloutView dismissCalloutAnimated:NO];
        
        [self popupStopCalloutViewFromPin:view];
	}
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[CFStop class]])
        [self.stopCalloutView dismissCalloutAnimated:NO];
}

- (void)popupStopCalloutViewFromPin:(MKAnnotationView *)pin
{
    CFStopSignView *stopSign = [[CFStopSignView alloc] initWithFrame:CGRectMake(0, 0, 280, 52)];
    stopSign.stop = self.selectedStop;
    stopSign.userInteractionEnabled = NO;
    
    self.stopCalloutView.contentView = stopSign;
    
    ((CustomPinAnnotationView *)pin).calloutView = self.stopCalloutView;
    [self.stopCalloutView presentCalloutFromRect:pin.bounds
                                          inView:pin
                               constrainedToView:self.mapView
                                        animated:YES];
}

- (NSTimeInterval)calloutView:(SMCalloutView *)theCalloutView delayForRepositionWithSize:(CGSize)offset
{
    CLLocationCoordinate2D coordinate = self.mapView.centerCoordinate;
    
    CGPoint center = [self.mapView convertCoordinate:coordinate toPointToView:self.view];
    
    center.x -= offset.width;
    center.y -= offset.height;
    
    coordinate = [self.mapView convertPoint:center toCoordinateFromView:self.view];
    
    [self.mapView setCenterCoordinate:coordinate animated:YES];
    
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)calloutViewClicked:(SMCalloutView *)calloutView
{
    [self stopCalloutTapped];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor colorWithHue:133.0/360.0 saturation:0.74 brightness:0.87 alpha:0.8];
    renderer.lineWidth = 5.0;
    return renderer;
}

@end