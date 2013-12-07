//
//  CFBipSpot.h
//  CF
//
//  Created by Radu Dutzan on 12/7/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <MapKit/MKAnnotation.h>

@interface CFBipSpot : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

+ (instancetype)bipSpotWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title subtitle:(NSString *)subtitle;

@end
