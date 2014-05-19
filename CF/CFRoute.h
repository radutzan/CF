//
//  CFRoute.h
//  Hop Out
//
//  Created by Diego Torres on 8/9/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@class MKPolyline;

@interface CFRoute : NSObject <NSCoding>

/**
 Array of CFStop instances
*/
@property (nonatomic, readonly) NSArray *stops;
@property (nonatomic, readonly) NSString *name;


/**
 MKPolyline describing the shape of the route
 */
@property (nonatomic, readonly) MKPolyline *polyline;

+ (instancetype)routeWithServiceName:(NSString *)serviceName stops:(NSArray *)stops routeCoordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count;

- (instancetype)initWithServiceName:(NSString *)serviceName stops:(NSArray *)stops routeCoordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count;

@end
