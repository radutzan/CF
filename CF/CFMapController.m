//
//  CFMapController.m
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFMapController.h"
#import "NSDictionary+NSNullUtility.h"
#import "CFSapoClient.h"
#import "CFStop.h"
#import "CFBipSpot.h"

#import <OLGhostAlertView/OLGhostAlertView.h>
#import "CFStopSignView.h"

@interface CFMapController () <CLLocationManagerDelegate, SMCalloutViewDelegate>

@property (nonatomic, strong) SMCalloutView *stopCalloutView;
@property (nonatomic, strong) OLGhostAlertView *zoomWarning;
@property (nonatomic, strong) OLGhostAlertView *outOfSantiagoWarning;

@property (nonatomic, strong) NSMutableSet *stops;
@property (nonatomic, strong) NSMutableSet *bipSpots;
@property (assign) CFStop *selectedStop;
@property (nonatomic) BOOL showZoomWarning;
@property (nonatomic) BOOL showOutOfSantiagoWarning;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation CFMapController

static MKMapRect santiagoBounds;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.stops = [NSMutableSet new];
        self.bipSpots = [NSMutableSet new];
        
        self.mapView = [[MKMapView alloc] initWithFrame:self.bounds];
        self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.mapView.delegate = self;
        self.mapView.showsUserLocation = YES;
        self.mapView.showsPointsOfInterest = NO;
        self.mapView.showsBuildings = YES;
        self.mapView.rotateEnabled = NO;
        self.mapView.pitchEnabled = NO;
        [self addSubview:self.mapView];
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
        
        self.stopCalloutView = [SMCalloutView new];
        self.stopCalloutView.delegate = self;
        self.stopCalloutView.constrainedInsets = UIEdgeInsetsMake(64.0, 0, 60.0, 0);
        self.stopCalloutView.permittedArrowDirection = SMCalloutArrowDirectionAny;
        
        self.darkOverlay = [[UIView alloc] initWithFrame:self.bounds];
        self.darkOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        self.darkOverlay.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
        self.darkOverlay.alpha = 0;
        
        UITapGestureRecognizer *darkOverlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(darkOverlayTapped)];
        [self.darkOverlay addGestureRecognizer:darkOverlayTap];
        
        self.zoomWarning = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"ZOOM_LEVEL_WARNING_TITLE", nil) message:NSLocalizedString(@"ZOOM_LEVEL_WARNING_MESSAGE", nil) timeout:200.0 dismissible:NO];
        self.zoomWarning.style = OLGhostAlertViewStyleLight;
        self.zoomWarning.position = OLGhostAlertViewPositionCenter;
        self.zoomWarning.userInteractionEnabled = NO;
        
        self.outOfSantiagoWarning = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"OUT_OF_SANTIAGO_WARNING_TITLE", nil) message:NSLocalizedString(@"OUT_OF_SANTIAGO_WARNING_MESSAGE", nil) timeout:200.0 dismissible:NO];
        self.outOfSantiagoWarning.style = OLGhostAlertViewStyleLight;
        self.outOfSantiagoWarning.position = OLGhostAlertViewPositionCenter;
        self.outOfSantiagoWarning.userInteractionEnabled = NO;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            MKMapPoint upperLeft = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-33.259, -70.939));
            MKMapPoint lowerRight = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-33.674, -70.391));
            
            santiagoBounds = MKMapRectMake(upperLeft.x, upperLeft.y, lowerRight.x-upperLeft.x, lowerRight.y-upperLeft.y);
        });
    }
    return self;
}

- (void)clearStopAnnotations
{
    NSMutableArray *pins = [NSMutableArray new];
    
    for (id annotation in [self.mapView annotations]) {
        if ([annotation isKindOfClass:[CFStop class]] || [annotation isKindOfClass:[CFBipSpot class]])
            [pins addObject:annotation];
    }
    
    [self.mapView removeAnnotations:pins];
    pins = nil;
}

- (void)clearSearchAnnotations
{
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

- (void)setShowZoomWarning:(BOOL)showZoomWarning
{
    if (_showZoomWarning == showZoomWarning) return;
    
    _showZoomWarning = showZoomWarning;
    
    if (showZoomWarning && !self.showOutOfSantiagoWarning) {
        [self.zoomWarning showInView:self];
    } else {
        [self.zoomWarning hide];
    }
}

- (void)setShowOutOfSantiagoWarning:(BOOL)showOutOfSantiagoWarning
{
    if (_showOutOfSantiagoWarning == showOutOfSantiagoWarning) return;
    
    _showOutOfSantiagoWarning = showOutOfSantiagoWarning;
    
    if (showOutOfSantiagoWarning) {
        [self.outOfSantiagoWarning showInView:self];
    } else {
        [self.outOfSantiagoWarning hide];
    }
}

- (void)stopCalloutTapped
{
    [self.delegate mapControllerDidSelectStop:self.selectedStop.code];
//    [self.mapView deselectAnnotation:self.selectedStop animated:NO];
}

- (void)showDarkOverlay
{
    [self addSubview:self.darkOverlay];
    
    [UIView animateWithDuration:0.33 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.darkOverlay.alpha = 1;
    } completion:nil];
}

- (void)hideDarkOverlay
{
    [self.superview endEditing:YES];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.darkOverlay.alpha = 0;
    } completion:^(BOOL finished) {
        [self.darkOverlay removeFromSuperview];
    }];
}

- (void)darkOverlayTapped
{
    [self hideDarkOverlay];
}

#pragma mark - Cuantofaltism

- (void)placeStopAnnotationsInRegion:(MKCoordinateRegion)region withRadius:(float)radius
{
    [[CFSapoClient sharedClient] busStopsAroundCoordinate:region.center radius:radius handler:^(NSError *error, id result) {
        if (error || [result count] == 0) {
            NSLog(@"bus stops error: %@", error);
            return;
        }
        
        for (NSDictionary *stopData in result) {
            CLLocationCoordinate2D coordinate;
            coordinate.latitude = [[stopData objectForKey:@"latitude"] doubleValue];
            coordinate.longitude = [[stopData objectForKey:@"longitude"] doubleValue];
            
            CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[stopData objectForKey:@"codigo"] name:[stopData objectForKey:@"nombre"] services:[stopData objectForKey:@"recorridos"]];
            [self.stops addObject:stop];
        }
        
        NSArray *stopsArray = [self.stops allObjects];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView addAnnotations:stopsArray];
        });
    }];
}

- (void)placeBipAnnotationsInRegion:(MKCoordinateRegion)region withRadius:(float)radius
{
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
            [self.mapView addAnnotations:spotsArray];
        });
    }];
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

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations lastObject];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 250, 250);
    self.mapView.region = region;
    
    self.defaultCenterCoordinate = currentLocation.coordinate;
    [self.delegate mapControllerDidUpdateLocation];
    
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"location manager failure: %@", error);
    [self setDefaultRegion];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        UIAlertView *locationDenied = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOCATION_DENIED_ALERT_TITLE", nil) message:NSLocalizedString(@"LOCATION_DENIED_ALERT_MESSAGE", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"DISMISS", nil) otherButtonTitles:nil];
        [locationDenied show];
    }
}

- (void)setDefaultRegion
{
    CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake(-33.444117, -70.651055);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(startCoordinate, 400, 400)];
    [self.mapView setRegion:adjustedRegion animated:NO];
    
    self.defaultCenterCoordinate = startCoordinate;
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (!MKMapRectIntersectsRect(santiagoBounds, mapView.visibleMapRect)) {
        self.showOutOfSantiagoWarning = YES;
        return;
    } else {
        self.showOutOfSantiagoWarning = NO;
    }
    
    [self loadStopAnnotations];
}

- (void)loadStopAnnotations
{
    MKCoordinateRegion region = self.mapView.region;
    
    float radio = floorf(MIN(region.span.longitudeDelta, region.span.latitudeDelta) * 111000) - 50;
    radio = MIN(950, radio);
    radio = radio + 50;
    
    if (radio > 800) {
        [self clearStopAnnotations];
        self.showZoomWarning = YES;
        return;
    } else {
        self.showZoomWarning = NO;
    }
    
    [self placeBipAnnotationsInRegion:region withRadius:radio];
    [self placeStopAnnotationsInRegion:region withRadius:radio];
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
    
    CGPoint center = [self.mapView convertCoordinate:coordinate toPointToView:self];
    
    center.x -= offset.width;
    center.y -= offset.height;
    
    coordinate = [self.mapView convertPoint:center toCoordinateFromView:self];
    
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
    renderer.strokeColor = [UIColor colorWithHue:260.0/360.0 saturation:1 brightness:0.85 alpha:0.75];
    renderer.lineWidth = 5.0;
    return renderer;
}

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

@end