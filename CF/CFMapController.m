//
//  CFMapController.m
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "sys/utsname.h"
#import "CFMapController.h"
#import "NSDictionary+NSNullUtility.h"
#import "CFSapoClient.h"
#import "CFStop.h"
#import "CFRoute.h"
#import "CFBipSpot.h"

#import <OLGhostAlertView/OLGhostAlertView.h>
#import "CFStopSignView.h"
#import "CFStopServicesButtonArrayView.h"

@interface CFMapController () <CLLocationManagerDelegate, SMCalloutViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableSet *stops;
@property (nonatomic, strong) NSMutableSet *bipSpots;
@property (assign) CFStop *selectedStop;
@property (assign) id<MKAnnotation> selectedSearchAnnotation;

@property (nonatomic, strong) UILabel *zoomWarning;
@property (nonatomic) BOOL showZoomWarning;
@property (nonatomic, strong) OLGhostAlertView *outOfSantiagoWarning;
@property (nonatomic) BOOL showOutOfSantiagoWarning;
@property (nonatomic, strong) OLGhostAlertView *connectivityWarning;
@property (nonatomic) BOOL showConnectivityWarning;
@property (nonatomic) BOOL shouldRetryConnection;

@property (nonatomic, assign, readwrite) CFMapMode mapMode;

@property (nonatomic) BOOL phoneIsCrap;
@property (nonatomic) BOOL hasPresentedNearestStop;

@property (nonatomic, assign) BOOL routeRegionSet;
@property (nonatomic, strong, readwrite) NSString *currentServiceName;
@property (nonatomic, assign, readwrite) CFDirection currentDirection;

@end

@implementation CFMapController

static MKMapRect santiagoBounds;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.stops = [NSMutableSet new];
        self.bipSpots = [NSMutableSet new];
        self.selectedSearchAnnotation = nil;
        
        CGFloat motionEffectHorizontalOffset = MOTION_EFFECTS_HORIZONTAL_OFFSET;
        CGFloat motionEffectVerticalOffset = MOTION_EFFECTS_VERTICAL_OFFSET;
        
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectInset(self.bounds, -motionEffectHorizontalOffset, -motionEffectVerticalOffset)];
        self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.mapView.delegate = self;
        self.mapView.showsUserLocation = YES;
        self.mapView.showsPointsOfInterest = NO;
        self.mapView.showsBuildings = YES;
        self.mapView.rotateEnabled = NO;
        self.mapView.pitchEnabled = NO;
        [self addSubview:self.mapView];
        
        UIInterpolatingMotionEffect *mapHorizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        mapHorizontalMotionEffect.minimumRelativeValue = [NSNumber numberWithFloat:motionEffectHorizontalOffset];
        mapHorizontalMotionEffect.maximumRelativeValue = [NSNumber numberWithFloat:-motionEffectHorizontalOffset];
        [self.mapView addMotionEffect:mapHorizontalMotionEffect];
        
        UIInterpolatingMotionEffect *mapVerticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        mapVerticalMotionEffect.minimumRelativeValue = [NSNumber numberWithFloat:motionEffectVerticalOffset];
        mapVerticalMotionEffect.maximumRelativeValue = [NSNumber numberWithFloat:-motionEffectVerticalOffset];
        [self.mapView addMotionEffect:mapVerticalMotionEffect];
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        [self.locationManager startUpdatingLocation];
        
        self.mapMode = CFMapModeStops;
        self.hasPresentedNearestStop = NO;
        self.routeRegionSet = NO;
        [self setInitialRegionAnimated:NO];
        
        self.stopCalloutView = [SMCalloutView new];
        self.stopCalloutView.delegate = self;
        self.stopCalloutView.constrainedInsets = UIEdgeInsetsMake(64.0, 0, 60.0, 0);
        self.stopCalloutView.permittedArrowDirection = SMCalloutArrowDirectionDown;
        
        self.zoomWarning = [[UILabel alloc] initWithFrame:CGRectMake(0.0, frame.size.height - self.contentInset.bottom - 10.0 - 36.0, 280.0, 36.0)];
        self.zoomWarning.userInteractionEnabled = YES;
        self.zoomWarning.backgroundColor = [UIColor colorWithWhite:0 alpha:.75];
        self.zoomWarning.alpha = 0;
        self.zoomWarning.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:17.0];
        self.zoomWarning.text = NSLocalizedString(@"ZOOM_LEVEL_WARNING_MESSAGE", nil);
        self.zoomWarning.textColor = [UIColor whiteColor];
        self.zoomWarning.textAlignment = NSTextAlignmentCenter;
        self.zoomWarning.layer.cornerRadius = 2.5;
        self.zoomWarning.layer.masksToBounds = YES;
        [self addSubview:self.zoomWarning];
        
        UITapGestureRecognizer *zoomWarningTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomWarningTapped)];
        [self.zoomWarning addGestureRecognizer:zoomWarningTap];
        
        self.outOfSantiagoWarning = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"OUT_OF_SANTIAGO_WARNING_TITLE", nil) message:NSLocalizedString(@"OUT_OF_SANTIAGO_WARNING_MESSAGE", nil) timeout:200.0 dismissible:NO];
        self.outOfSantiagoWarning.titleLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
        self.outOfSantiagoWarning.messageLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:14.0];
        self.outOfSantiagoWarning.position = OLGhostAlertViewPositionTop;
        self.outOfSantiagoWarning.topContentMargin = self.contentInset.top;
        self.outOfSantiagoWarning.userInteractionEnabled = NO;
        
        self.connectivityWarning = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"NO_INTERNET_WARNING_TITLE", nil) message:NSLocalizedString(@"NO_INTERNET_WARNING_MESSAGE", nil) timeout:200.0 dismissible:NO];
        self.connectivityWarning.titleLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
        self.connectivityWarning.messageLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:14.0];
        self.connectivityWarning.style = OLGhostAlertViewStyleDark;
        self.connectivityWarning.position = OLGhostAlertViewPositionCenter;
        self.connectivityWarning.userInteractionEnabled = NO;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            MKMapPoint upperLeft = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-33.259, -70.939));
            MKMapPoint lowerRight = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-33.674, -70.391));
            
            santiagoBounds = MKMapRectMake(upperLeft.x, upperLeft.y, lowerRight.x-upperLeft.x, lowerRight.y-upperLeft.y);
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appBecameActive:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)layoutSubviews
{
    self.outOfSantiagoWarning.topContentMargin = self.contentInset.top;
    self.zoomWarning.frame = CGRectMake(0.0, self.bounds.size.height - self.contentInset.bottom - 10.0 - 36.0, self.zoomWarning.bounds.size.width, self.zoomWarning.bounds.size.height);
    self.zoomWarning.center = CGPointMake(self.center.x, self.zoomWarning.center.y);
}

#pragma mark - Helpers

- (void)clearStopAnnotations
{
    NSMutableArray *pins = [NSMutableArray new];
    
    for (id annotation in [self.mapView annotations]) {
        if ([annotation isKindOfClass:[CFStop class]] || [annotation isKindOfClass:[CFBipSpot class]])
            [pins addObject:annotation];
    }
    
    [self.mapView removeAnnotations:pins];
    [self.stops removeAllObjects];
    [self.bipSpots removeAllObjects];
    pins = nil;
}

- (void)clearSearchAnnotations
{
    self.selectedSearchAnnotation = nil;
    
    id userLocation = [self.mapView userLocation];
    
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[self.mapView annotations]];
    
    if (userLocation)
        [pins removeObject:userLocation];
    
    for (id annotation in [self.mapView annotations]) {
        if ([annotation isKindOfClass:[CFStop class]])
            [pins removeObject:annotation];
    }
    
    [self.mapView removeAnnotations:pins];
    pins = nil;
}

- (void)clearRouteOverlays
{
    NSMutableArray *pins = [NSMutableArray new];
    
    for (id annotation in [self.mapView annotations]) {
        if ([annotation isKindOfClass:[CFStop class]] || [annotation isKindOfClass:[CFBipSpot class]])
            [pins addObject:annotation];
    }
    
    [self.mapView removeAnnotations:pins];
    pins = nil;
}

- (void)setInitialRegionAnimated:(BOOL)animated
{
    if (!self.locationManager.location) {
        [self setDefaultRegionAnimated:animated];
    } else {
        CGFloat distance = 600;
        if (self.phoneIsCrap) distance = 250;
        [self.mapView setRegion:[self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(self.locationManager.location.coordinate, distance, distance)] animated:animated];
    }
}

- (void)setDefaultRegionAnimated:(BOOL)animated
{
    CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake(-33.444117, -70.651055);
    CGFloat distance = 350;
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(startCoordinate, distance, distance)];
    [self.mapView setRegion:adjustedRegion animated:animated];
    
    self.defaultCenterCoordinate = startCoordinate;
}

- (void)setShowZoomWarning:(BOOL)showZoomWarning
{
    if (_showZoomWarning == showZoomWarning) return;
    _showZoomWarning = showZoomWarning;
    
    CGFloat offset = TAB_BAR_HEIGHT + 10.0;
    if (showZoomWarning) offset = -offset;
    if (showZoomWarning) [self setNeedsLayout];
    
    self.zoomWarning.alpha = 1 - showZoomWarning;
    self.zoomWarning.center = CGPointMake(self.zoomWarning.center.x, self.zoomWarning.center.y - offset * showZoomWarning);
    
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:showZoomWarning options:0 animations:^{
        self.zoomWarning.alpha = showZoomWarning;
        self.zoomWarning.center = CGPointMake(self.zoomWarning.center.x, self.zoomWarning.center.y + offset);
    } completion:^(BOOL finished) {
        self.zoomWarning.center = CGPointMake(self.zoomWarning.center.x, self.zoomWarning.center.y - offset * !showZoomWarning);
    }];
}

- (void)setShowOutOfSantiagoWarning:(BOOL)showOutOfSantiagoWarning
{
    if (_showOutOfSantiagoWarning == showOutOfSantiagoWarning) return;
    _showOutOfSantiagoWarning = showOutOfSantiagoWarning;
    
    if (showOutOfSantiagoWarning && !self.outOfSantiagoWarning.visible) {
        [self.outOfSantiagoWarning showInView:self];
    } else if (!showOutOfSantiagoWarning) {
        [self.outOfSantiagoWarning hide];
    }
}

- (void)setShowConnectivityWarning:(BOOL)showConnectivityWarning
{
    _showConnectivityWarning = showConnectivityWarning;
    
    if (showConnectivityWarning && !self.connectivityWarning.visible) {
        [self.connectivityWarning showInView:self];
    } else if (!showConnectivityWarning) {
        [self.connectivityWarning hide];
    }
}

- (void)setShouldRetryConnection:(BOOL)shouldRetryConnection
{
    if (_shouldRetryConnection == shouldRetryConnection) return;
    _shouldRetryConnection = shouldRetryConnection;
    
    if (shouldRetryConnection) {
        [self performSelector:@selector(loadStopAnnotations) withObject:nil afterDelay:3.0];
    } else {
        [self.class cancelPreviousPerformRequestsWithTarget:self];
    }
}

- (void)zoomWarningTapped
{
    CGFloat distance = 600;
    if (self.phoneIsCrap) distance = 250;
    [self.mapView setRegion:[self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(self.mapView.centerCoordinate, distance, distance)] animated:YES];
}

- (BOOL)phoneIsCrap
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if ([machineName isEqualToString:@"iPhone3,1"]) return YES;
    
    return NO;
}

- (void)appBecameActive:(NSNotification *)notification
{
    self.hasPresentedNearestStop = NO;
    if (self.mapMode == CFMapModeStops) [self selectNearestStop];
}

#pragma mark - Map Mode Switching

- (void)setMapMode:(CFMapMode)mapMode
{
    if (_mapMode == mapMode) return;
    
    if (mapMode == CFMapModeStops) {
        [self performSelector:@selector(loadStopAnnotations) withObject:nil afterDelay:0.1];
        if (_mapMode != CFMapModeServiceRoute) [self setInitialRegionAnimated:YES];
    } else {
        [self clearStopAnnotations];
    }
    
    if (mapMode == CFMapModeServiceRoute) {
        
    } else if (_mapMode == CFMapModeServiceRoute && mapMode != CFMapModeServiceRoute) {
        [self.mapView removeOverlays:self.mapView.overlays];
        [self clearStopAnnotations];
        self.routeRegionSet = NO;
        self.currentServiceName = nil;
    }
    
    _mapMode = mapMode;
}

#pragma mark - CFMapModeStops

- (void)displayStops
{
    self.mapMode = CFMapModeStops;
}

- (void)reloadStops
{
    [self clearStopAnnotations];
    [self loadStopAnnotations];
}

- (void)loadStopAnnotations
{
    self.shouldRetryConnection = NO;
    
    MKCoordinateRegion region = self.mapView.region;
    
    float radio = floorf(MIN(region.span.longitudeDelta, region.span.latitudeDelta) * 111000) - 50;
    radio = MIN(1750, radio);
    radio = radio + 50;
    
    if ((self.phoneIsCrap && radio > 420) || (!self.phoneIsCrap && radio > 1450)) {
        [self clearStopAnnotations];
        self.showZoomWarning = YES;
        return;
    } else {
        self.showZoomWarning = NO;
    }
    
    [self placeBipAnnotationsInRegion:region withRadius:radio];
    [self placeStopAnnotationsInRegion:region withRadius:radio];
}

- (void)placeStopAnnotationsInRegion:(MKCoordinateRegion)region withRadius:(float)radius
{
    if (!self.mapMode == CFMapModeStops) return;
    
    [[CFSapoClient sharedClient] busStopsAroundCoordinate:region.center radius:radius handler:^(NSError *error, id result) {
        if (error) {
            NSLog(@"bus stops error: %@", error);
            
            if (error.code == -1009) {
                self.connectivityWarning.title = NSLocalizedString(@"NO_INTERNET_WARNING_TITLE", nil);
                self.connectivityWarning.message = NSLocalizedString(@"NO_INTERNET_WARNING_MESSAGE", nil);
            } else {
                self.connectivityWarning.title = NSLocalizedString(@"API_ISSUE_WARNING_TITLE", nil);
                self.connectivityWarning.message = NSLocalizedString(@"API_ISSUE_WARNING_MESSAGE", nil);
            }
            self.showConnectivityWarning = YES;
            self.shouldRetryConnection = YES;
            
            return;
        }
        
        if ([result count] == 0) return;
        
        for (NSDictionary *stopData in result) {
            if (!self.mapMode == CFMapModeStops) return;
            
            CLLocationCoordinate2D coordinate;
            coordinate.latitude = [[stopData objectForKey:@"latitude"] doubleValue];
            coordinate.longitude = [[stopData objectForKey:@"longitude"] doubleValue];
            
            CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[stopData objectForKey:@"codigo"] name:[stopData objectForKey:@"nombre"] services:[stopData objectForKey:@"recorridos"]];
            [self.stops addObject:stop];
        }
        
        NSArray *stopsArray = [self.stops allObjects];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView addAnnotations:stopsArray];
            [self selectNearestStop];
        });
        
        self.showConnectivityWarning = NO;
        self.shouldRetryConnection = NO;
    }];
}

- (void)placeBipAnnotationsInRegion:(MKCoordinateRegion)region withRadius:(float)radius
{
    if (!self.mapMode == CFMapModeStops) return;
    
    [[CFSapoClient sharedClient] bipSpotsAroundCoordinate:region.center radius:radius handler:^(NSError *error, id result) {
        if (error) {
            NSLog(@"bip spots error: %@", error);
            return;
        }
        
        for (NSDictionary *spotDictionary in result) {
            CFBipSpot *spot = [self bipSpotFromDictionary:spotDictionary];
            [self.bipSpots addObject:spot];
        }
        
        NSArray *spotsArray = [self.bipSpots allObjects];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.mapMode == CFMapModeStops) return;
            [self.mapView addAnnotations:spotsArray];
        });
    }];
}

- (void)selectNearestStop
{
    //    NSLog(@"selectNearestStop");
    if (self.hasPresentedNearestStop) return;
    if (!self.locationManager.location) return;
    
    NSMutableDictionary *distances = [NSMutableDictionary dictionary];
    
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[CFStop class]]) {
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
            CLLocationDistance distance = [loc distanceFromLocation:self.locationManager.location];
            
            [distances setObject:annotation forKey:@(distance)];
        }
    }
    
    if (distances.count == 0) return;
    
    NSArray *sortedKeys = [[distances allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *nearestKeys = [sortedKeys subarrayWithRange:NSMakeRange(0, MIN(5, sortedKeys.count))];
    
    NSArray *nearestAnnotations = [distances objectsForKeys:nearestKeys notFoundMarker:[NSNull null]];
    
    id<MKAnnotation> annotationToSelect = nearestAnnotations[0];
    
    for (id<MKAnnotation> annotation in nearestAnnotations) {
        CFStop *stopAnnotation = (CFStop *)annotation;
        if (stopAnnotation.isFavorite) {
            annotationToSelect = stopAnnotation;
            break;
        }
    }
    
    [self.mapView selectAnnotation:annotationToSelect animated:YES];
    
    self.hasPresentedNearestStop = YES;
}

- (void)goToNearestBipSpot
{
    self.mapView.userTrackingMode = MKUserTrackingModeNone;
    
    CLLocationDistance distance = DBL_MAX;
    CFBipSpot *nearestSpot = nil;
    
    for (CFBipSpot *spot in self.bipSpots) {
        CLLocation *spotLocation = [[CLLocation alloc] initWithLatitude:spot.coordinate.latitude longitude:spot.coordinate.longitude];
        CLLocationDistance DistancetoPoint = [self.mapView.userLocation.location distanceFromLocation:spotLocation];
        
        if (distance > DistancetoPoint) {
            distance = DistancetoPoint;
            nearestSpot = spot;
        }
    }
    
    if (distance <= 1000) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(nearestSpot.coordinate, 250, 250);
        [self.mapView setRegion:region animated:YES];
        [self.mapView selectAnnotation:nearestSpot animated:YES];
    } else {
        [[CFSapoClient sharedClient] bipSpotsAroundCoordinate:self.mapView.centerCoordinate radius:0 handler:^(NSError *error, id result) {
            NSDictionary *spotDictionary = [result objectAtIndex:0];
            
            CFBipSpot *spot = [self bipSpotFromDictionary:spotDictionary];
            
            [self.bipSpots addObject:spot];
            [self.mapView addAnnotation:spot];
            
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(spot.coordinate, 250, 250);
            [self.mapView setRegion:region animated:YES];
            [self.mapView selectAnnotation:spot animated:YES];
        }];
    }
}

- (CFBipSpot *)bipSpotFromDictionary:(NSDictionary *)dictionary
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [[dictionary objectForKeyNotNull:@"lat"] doubleValue];
    coordinate.longitude = [[dictionary objectForKeyNotNull:@"long"] doubleValue];
    
    NSString *name;
    
    if ([dictionary objectForKeyNotNull:@"nombre"])
        name = [[dictionary objectForKeyNotNull:@"nombre"] capitalizedString];
    
    if ([[dictionary objectForKeyNotNull:@"tipo"] isEqualToString:@"Centro Bip"])
        name = @"Centro Bip";
    
    CFBipSpot *spot = [CFBipSpot bipSpotWithCoordinate:coordinate title:name subtitle:[[dictionary objectForKeyNotNull:@"direccion"] capitalizedString]];
    
    return spot;
}

#pragma mark - CFMapModeServiceRoute

- (void)displayServiceRoute:(NSString *)serviceName direction:(CFDirection)direction
{
    self.mapMode = CFMapModeServiceRoute;
    if (!direction) direction = CFDirectionOutward;
    [self drawPolylineForService:serviceName direction:direction];
    
    self.currentServiceName = serviceName;
    self.currentDirection = direction;
}

- (void)displayServiceRoute:(NSString *)serviceName directionString:(NSString *)directionString
{
    [[CFSapoClient sharedClient] serviceInfoForService:serviceName handler:^(NSError *error, NSArray *result) {
        if (result) {
            CFDirection finalDirection;
            NSDictionary *resultDictionary = [result objectAtIndex:0];
            NSString *responseIda = [resultDictionary objectForKey:@"ida"];
//            NSString *responseRegreso = [resultDictionary objectForKey:@"regreso"];
            NSString *localizedTo = NSLocalizedString(@"TO_DIRECTION", nil);
            NSString *comparableDirectionString = [[directionString stringByReplacingCharactersInRange:NSMakeRange(0, localizedTo.length + 1) withString:@""] uppercaseString];
            
            if ([comparableDirectionString isEqualToString:responseIda]) {
                finalDirection = CFDirectionOutward;//NSLog(@"CFDirectionOutward");
            } else {
                finalDirection = CFDirectionInward;//NSLog(@"CFDirectionInward");
            }
            
            [self displayServiceRoute:serviceName direction:finalDirection];
        }
    }];
}

- (void)drawPolylineForService:(NSString *)service direction:(CFDirection)direction
{
    if (!self.mapMode == CFMapModeServiceRoute) return;
    
    [self.mapView removeOverlays:self.mapView.overlays];
    [self clearStopAnnotations];
    
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
                // it's a bus stop
                CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[dataPoint objectForKey:@"codigo"] name:name services:[dataPoint objectForKey:@"recorridos"]];
                [stops addObject:stop];
            }
            
            coordinates[i] = coordinate;
            i++;
        }
        
        CFRoute *route = [CFRoute routeWithServiceName:service stops:stops routeCoordinates:coordinates count:result.count];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.mapMode == CFMapModeServiceRoute) return;
            
            [self.mapView removeOverlays:self.mapView.overlays];
            [self clearStopAnnotations];
            
            [self.mapView addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
            [self.mapView addAnnotations:stops];
            
            if (i == result.count && !self.routeRegionSet) {
                CFStop *middleAnnotation = [stops objectAtIndex:floorf(stops.count / 2)];
                if (self.mapView.userLocation && MKMapRectContainsPoint(santiagoBounds, MKMapPointForCoordinate(self.mapView.userLocation.coordinate))) {
                    [self.mapView showAnnotations:@[middleAnnotation, self.mapView.userLocation] animated:YES];
                } else {
                    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(middleAnnotation.coordinate, 1400, 1400)];
                    [self.mapView setRegion:adjustedRegion animated:YES];
                }
                
                self.routeRegionSet = YES;
            }
        });
    }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations lastObject];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 250, 250);
    self.mapView.region = region;
    
    self.defaultCenterCoordinate = currentLocation.coordinate;
    if ([self.delegate respondsToSelector:@selector(mapControllerDidUpdateLocation)]) [self.delegate mapControllerDidUpdateLocation];
    
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"location manager failure: %@", error);
    [self setDefaultRegionAnimated:NO];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        UIAlertView *locationDenied = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOCATION_DENIED_ALERT_TITLE", nil) message:NSLocalizedString(@"LOCATION_DENIED_ALERT_MESSAGE", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"DISMISS", nil) otherButtonTitles:nil];
        [locationDenied show];
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    if (self.mapMode == CFMapModeStops) [self selectNearestStop];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    self.defaultCenterCoordinate = self.mapView.userLocation.coordinate;
    if ([self.delegate respondsToSelector:@selector(mapControllerDidUpdateLocation)]) [self.delegate mapControllerDidUpdateLocation];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(mapControllerMapViewRegionDidChange)])
        [self.delegate mapControllerMapViewRegionDidChange];
    
    if (!MKMapRectIntersectsRect(santiagoBounds, mapView.visibleMapRect)) {
        self.showOutOfSantiagoWarning = YES;
        return;
    } else {
        self.showOutOfSantiagoWarning = NO;
    }
    
    if (self.mapMode == CFMapModeStops) [self loadStopAnnotations];
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
    
    if ([annotation isKindOfClass:[CFBipSpot class]]) {
        static NSString *identifier = @"BipSpot";
        MKAnnotationView *spotPin = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if (!spotPin) {
            spotPin = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            [spotPin setCanShowCallout:YES];
            [spotPin setImage:[UIImage imageNamed:@"pin-bip"]];
            
        } else {
            [spotPin setAnnotation:annotation];
        }
        
        return spotPin;
    }
    
    if (![annotation isKindOfClass:[MKUserLocation class]]) {
        MKPinAnnotationView *searchPin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"SearchPin"];
        searchPin.animatesDrop = YES;
        searchPin.canShowCallout = YES;
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps-x-callback://"]]) {
            UIButton *calloutInfoButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [calloutInfoButton addTarget:self action:@selector(displayOptionsForSelectedAnnotation) forControlEvents:UIControlEventTouchUpInside];
            searchPin.rightCalloutAccessoryView = calloutInfoButton;
        }
        
        return searchPin;
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
    } else {
        self.selectedSearchAnnotation = view.annotation;
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[CFStop class]])
        [self.stopCalloutView dismissCalloutAnimated:NO];
}

- (void)popupStopCalloutViewFromPin:(MKAnnotationView *)pin
{
    CFStopSignView *stopSign = [[CFStopSignView alloc] initWithFrame:CGRectMake(0, 0, 280, 49)];
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
    
    CGPoint center = [self.mapView convertCoordinate:coordinate toPointToView:self];
    
    center.x -= offset.width;
    center.y -= offset.height;
    
    coordinate = [self.mapView convertPoint:center toCoordinateFromView:self];
    
    [self.mapView setCenterCoordinate:coordinate animated:YES];
    
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)calloutViewClicked:(SMCalloutView *)calloutView
{
    [self.delegate mapControllerDidSelectStop:self.selectedStop];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor colorWithHue:135.0/360.0 saturation:0.70 brightness:0.80 alpha:0.8];
    renderer.lineWidth = 5.0;
    return renderer;
}

#pragma mark - Search

- (void)performSearchWithString:(NSString *)searchString
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    MKLocalSearchRequest *searchRequest = [MKLocalSearchRequest new];
    searchRequest.naturalLanguageQuery = searchString;
    searchRequest.region = self.mapView.region;
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:searchRequest];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (response) {
            [self clearSearchAnnotations];
            [self.mapView setRegion:response.boundingRegion animated:YES];
            
            for (MKMapItem *item in response.mapItems) {
                MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
                annotation.coordinate = item.placemark.coordinate;
                annotation.title      = item.name;
                annotation.subtitle   = item.placemark.title;
                [self.mapView addAnnotation:annotation];
            }
        } else {
            if (error.code == 4) {
                UIAlertView *notFound = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SEARCH_ERROR_NOTFOUND_TITLE", nil) message:NSLocalizedString(@"SEARCH_ERROR_NOTFOUND_MESSAGE", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"DISMISS", nil) otherButtonTitles:nil];
                [notFound show];
            } else {
                UIAlertView *shitHappens = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SEARCH_ERROR_GENERIC_TITLE", nil) message:NSLocalizedString(@"SEARCH_ERROR_GENERIC_MESSAGE", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
                [shitHappens show];
            }
        }
    }];
}

- (void)displayOptionsForSelectedAnnotation
{
    UIActionSheet *optionsSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"DIRECTIONS_WITH_GOOGLE_MAPS", nil), nil];
    [optionsSheet showInView:self];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self launchGoogleMapsForDirections];
    }
}

- (void)launchGoogleMapsForDirections
{
    NSString *locationCoordinateString = [NSString stringWithFormat:@"%f,%f", self.mapView.userLocation.coordinate.latitude, self.mapView.userLocation.coordinate.longitude];
    MKPointAnnotation *searchAnnotation = (MKPointAnnotation *)self.selectedSearchAnnotation;
    NSString *calloutAddressString = [searchAnnotation.subtitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"comgooglemaps-x-callback://?saddr=%@&daddr=%@&directionsmode=transit&x-success=cuantofalta://gmaps/&x-source=%@", locationCoordinateString, calloutAddressString, [@"Cuánto Falta" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

@end