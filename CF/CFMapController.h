//
//  CFMapController.h
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

@import UIKit;
@import MapKit;

#import "SMCalloutView.h"

@protocol CFMapControllerDelegate <NSObject>

- (void)mapControllerDidSelectStop:(NSString *)stopCode;

@end

@interface CFMapController : UIView <MKMapViewDelegate>

- (void)performSearchWithString:(NSString *)searchString;
- (void)showDarkOverlay;
- (void)hideDarkOverlay;
- (void)goToNearestBipSpot;

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, weak) id<CFMapControllerDelegate> delegate;
@property (nonatomic, strong) UIView *darkOverlay;

@end

@interface CustomPinAnnotationView : MKAnnotationView
@property (strong, nonatomic) SMCalloutView *calloutView;
@end