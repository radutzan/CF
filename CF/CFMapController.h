//
//  CFMapController.h
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

@import UIKit;
@import MapKit;

#import "CustomPinAnnotationView.h"

@protocol CFMapControllerDelegate <NSObject>

- (void)mapControllerDidSelectStop:(NSString *)stopCode;

@optional

- (void)mapControllerDidUpdateLocation;

@end

@interface CFMapController : UIView <MKMapViewDelegate>

- (void)performSearchWithString:(NSString *)searchString;
- (void)showDarkOverlay;
- (void)hideDarkOverlay;
- (void)goToNearestBipSpot;

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, weak) id<CFMapControllerDelegate> delegate;
@property (nonatomic, strong) UIView *darkOverlay;
@property (nonatomic, assign) CLLocationCoordinate2D defaultCenterCoordinate;

@end