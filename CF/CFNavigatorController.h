//
//  CFNavigatorController.h
//  CF
//
//  Created by Radu Dutzan on 4/2/15.
//  Copyright (c) 2015 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MapKit;

@protocol CFNavigatorDelegate <NSObject>

- (void)navigatorWillTakeOver;
- (void)navigatorWillRetreat;

@end

@interface CFNavigatorController : UIViewController

- (void)enterNavigation;
- (void)exitNavigation;
- (void)findDirectionsFrom:(CLLocationCoordinate2D)originCoordinate to:(CLLocationCoordinate2D)destinationCoordinate;
- (void)findDirectionsFromCurrentLocationToSearchablePlace:(NSString *)placeSearchString;

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, weak) id<CFNavigatorDelegate>delegate;

@end
