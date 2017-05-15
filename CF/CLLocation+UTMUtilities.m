//
//  CLLocation+UTMUtilities.m
//  CuantoFaltaiOS
//
//  Created by Diego Torres on 16-11-12.
//  Copyright (c) 2012 Onda. All rights reserved.
//

#import "CLLocation+UTMUtilities.h"

#define EQUITORIAL_RADIUS 6378137
#define POLAR_RADIUS 6356752.3142
#define UTM_SCALE_FACTOR 0.9996

double radiansToDegrees(double radians) {
    return radians * 180 / M_PI;
}

double degreesToRadians(double degrees) {
    return degrees / 180 * M_PI;
}

int UTMZoneForCLLocationCoordinate2D(CLLocationCoordinate2D coordinate)
{
    if( (coordinate.latitude >  84.0 && coordinate.latitude <  90.0) ||  // North pole
       (coordinate.latitude > -80.0 && coordinate.latitude < -90.0) ) { // South pole
        // This indicates we should UPS.
        return 0;
    }
    // Adjust for projections.
    if ( coordinate.latitude >= 56 && coordinate.latitude < 64.0 &&
        coordinate.longitude >= 3.0 && coordinate.longitude < 12.0 ) {
        return 32;
    }
    
    if( coordinate.latitude >= 72.0  && coordinate.latitude < 84.0 ) {
        if ( coordinate.longitude >= 0.0  && coordinate.longitude < 9.0  )
            return 31;
        if ( coordinate.longitude >= 9.0  && coordinate.longitude < 21.0 )
            return 33;
        if ( coordinate.longitude >= 21.0 && coordinate.longitude < 33.0 )
            return 35;
        if ( coordinate.longitude >= 33.0 && coordinate.longitude < 42.0 )
            return 37;
    }
    
    // Recast from [-180,180) to [0,360).
    // The w<->w is then divided into 60 zones from 1-60.
    int zone = fabs(floor((coordinate.longitude + 180.0) / 6) + 1);
    if (coordinate.latitude < 0) {
        zone = zone*-1;
    }
    return zone;
}

double meridianForZone(int zone)
{
    zone = abs(zone);
    return degreesToRadians(-183.0 + (zone * 6.0));
}

double arcLengthOfMeridian (double latitudeInRadians)
{
    double alpha;
    double beta;
    double gamma;
    double delta;
    double epsilon;
    double n;
    
    double result;
    
    /* Precalculate n */
    n = (EQUITORIAL_RADIUS - POLAR_RADIUS) / (EQUITORIAL_RADIUS + POLAR_RADIUS);
    
    /* Precalculate alpha */
    alpha = ((EQUITORIAL_RADIUS + POLAR_RADIUS) / 2.0) * (1.0 + (pow(n, 2.0) / 4.0) + (pow(n, 4.0) / 64.0));
    
    /* Precalculate beta */
    beta = (-3.0 * n / 2.0) + (9.0 * pow(n, 3.0) / 16.0) + (-3.0 * pow(n, 5.0) / 32.0);
    
    /* Precalculate gamma */
    gamma = (15.0 * pow(n, 2.0) / 16.0) + (-15.0 * pow(n, 4.0) / 32.0);
    
    /* Precalculate delta */
    delta = (-35.0 * pow(n, 3.0) / 48.0) + (105.0 * pow(n, 5.0) / 256.0);
    
    /* Precalculate epsilon */
    epsilon = (315.0 * pow(n, 4.0) / 512.0);
    
    /* Now calculate the sum of the series and return */
    result = alpha * (latitudeInRadians + (beta * sin(2.0 * latitudeInRadians)) + (gamma * sin(4.0 * latitudeInRadians)) + (delta * sin(6.0 * latitudeInRadians)) + (epsilon * sin(8.0 * latitudeInRadians)));
    
    return result;
}

	UTMCoordinate latitudeAndLongitudeToTMCoordinates(CLLocationCoordinate2D coordinate, double meridian)
{
    UTMCoordinate tmCoordinates;
    
    double N, nu2, ep2, t, t2, l;
    double l3coef, l4coef, l5coef, l6coef, l7coef, l8coef;
    
    double phi = coordinate.latitude; // Latitude in radians
    double lambda = coordinate.longitude; // Longitude in radians
    
    /* Precalculate ep2 */
    ep2 = (pow(EQUITORIAL_RADIUS, 2.0) - pow(POLAR_RADIUS, 2.0)) / pow(POLAR_RADIUS, 2.0);
    
    /* Precalculate nu2 */
    nu2 = ep2 * pow(cos(phi), 2.0);
    
    /* Precalculate N */
    N = pow(EQUITORIAL_RADIUS, 2.0) / (POLAR_RADIUS * sqrt(1 + nu2));
    
    /* Precalculate t */
    t = tan(phi);
    t2 = t * t;
    
    /* Precalculate l */
    l = lambda - meridian;
    
    /* Precalculate coefficients for l**n in the equations below
     so a normal human being can read the expressions for easting
     and northing
     -- l**1 and l**2 have coefficients of 1.0 */
    l3coef = 1.0 - t2 + nu2;
    l4coef = 5.0 - t2 + 9 * nu2 + 4.0 * (nu2 * nu2);
    l5coef = 5.0 - 18.0 * t2 + (t2 * t2) + 14.0 * nu2 - 58.0 * t2 * nu2;
    l6coef = 61.0 - 58.0 * t2 + (t2 * t2) + 270.0 * nu2 - 330.0 * t2 * nu2;
    l7coef = 61.0 - 479.0 * t2 + 179.0 * (t2 * t2) - (t2 * t2 * t2);
    l8coef = 1385.0 - 3111.0 * t2 + 543.0 * (t2 * t2) - (t2 * t2 * t2);
    
    /* Calculate easting (x) */
    tmCoordinates.x = N * cos(phi) * l + (N / 6.0 * pow(cos(phi), 3.0) * l3coef * pow(l, 3.0)) + (N / 120.0 * pow(cos(phi), 5.0) * l5coef * pow(l, 5.0)) + (N / 5040.0 * pow(cos(phi), 7.0) * l7coef * pow(l, 7.0));
    
    /* Calculate northing (y) */
    tmCoordinates.y = arcLengthOfMeridian(phi) + (t / 2.0 * N * pow(cos(phi), 2.0) * pow(l, 2.0)) + (t / 24.0 * N * pow(cos(phi), 4.0) * l4coef * pow(l, 4.0)) + (t / 720.0 * N * pow(cos(phi), 6.0) * l6coef * pow(l, 6.0)) + (t / 40320.0 * N * pow(cos(phi), 8.0) * l8coef * pow(l, 8.0));
    
    return tmCoordinates;
}

@implementation CLLocation (UTMUtilities)

- (UTMCoordinate)UTMCordinate {
    return UTMCoordinateFromCLLocationCoordinate2D(self.coordinate);
}

@end

UTMCoordinate UTMCoordinateFromCLLocationCoordinate2D(CLLocationCoordinate2D coordinate)
{
    UTMCoordinate utmcoordinate;
    utmcoordinate.zone = UTMZoneForCLLocationCoordinate2D(coordinate);
    
    double meridian = meridianForZone(utmcoordinate.zone);
    
    coordinate.latitude = degreesToRadians(coordinate.latitude);
    coordinate.longitude = degreesToRadians(coordinate.longitude);
    
    UTMCoordinate tmcoordinate = latitudeAndLongitudeToTMCoordinates(coordinate, meridian);
    
    utmcoordinate.x = tmcoordinate.x * UTM_SCALE_FACTOR + 500000.0;
    utmcoordinate.y = tmcoordinate.y * UTM_SCALE_FACTOR;
    
    if (utmcoordinate.y < 0.0) {
        utmcoordinate.y += 10000000.0;
    }
    
    return utmcoordinate;
}
