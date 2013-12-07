//
//  CLLocation+UTMUtilities.h
//  CuantoFaltaiOS
//
//  Created by Diego Torres on 16-11-12.
//  Copyright (c) 2012 Onda. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

typedef struct {
    double x;
    double y;
    int zone;
} UTMCoordinate;

typedef struct {
    UTMCoordinate origin;
    CGSize size;
} UTMRect;

@interface CLLocation (UTMUtilities)

- (UTMCoordinate)UTMCordinate;

@end

extern UTMCoordinate UTMCoordinateFromCLLocationCoordinate2D(CLLocationCoordinate2D coordinate);
//extern CLLocationCoordinate2D CLLocationCoordinate2DFromUTMCoordinate(UTMCoordinate coordinate);

