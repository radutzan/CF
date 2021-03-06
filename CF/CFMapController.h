//
//  CFMapController.h
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

@import UIKit;
@import MapKit;

typedef NS_ENUM(NSInteger, CFMapMode) {
    CFMapModeStops,
    CFMapModeServiceRoute,
    CFMapModeDirections
};

#import "CFSapoClient.h"
#import "CFStop.h"
#import "CFService.h"
#import "CustomPinAnnotationView.h"

@protocol CFMapControllerDelegate <NSObject>

- (void)mapControllerDidSelectStop:(CFStop *)stop;

@optional

- (void)mapControllerDidUpdateLocation;
- (void)mapControllerMapViewRegionDidChange;

@end

@interface CFMapController : UIView <MKMapViewDelegate>

- (void)setInitialRegionAnimated:(BOOL)animated;
- (void)performSearchWithString:(NSString *)searchString;
- (void)goToNearestBipSpot;
- (void)reloadStops;
- (void)displayStops;
- (void)displayServiceRoute:(NSString *)serviceName direction:(CFDirection)direction;
- (void)displayServiceRoute:(NSString *)serviceName directionString:(NSString *)directionString;

@property (nonatomic, strong) SMCalloutView *stopCalloutView;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, weak) id<CFMapControllerDelegate> delegate;
@property (nonatomic, assign) CLLocationCoordinate2D defaultCenterCoordinate;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic, assign, readonly) CFMapMode mapMode;
@property (nonatomic, strong, readonly) NSString *currentServiceName;
@property (nonatomic, assign, readonly) CFDirection currentDirection;
@property (nonatomic) BOOL showActivityIndicator;

@end