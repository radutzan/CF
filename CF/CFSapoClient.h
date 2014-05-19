//
//  CFSapoClient.h
//  CuantoFaltaiOS
//
//  Created by Diego Torres on 15-11-12.
//  Copyright (c) 2012 Onda. All rights reserved.
//

#import "AFHTTPClient.h"
#import "CLLocation+UTMUtilities.h"

typedef NS_ENUM(NSUInteger, CFDirection) {
    CFDirectionOutward = 0,
    CFDirectionInward = 1
};

typedef void(^CFSapoResultBlock)(NSError *error, id result);

@interface CFSapoClient : AFHTTPClient

/**
 Creates and initializes an `CFSapoClient` object.
  
 @return the shared instance of `CFSapoClient`
*/
+ (id)sharedClient;

/**
 Obtain an estimate of buses approaching a bus stop.
 
 @param busStop Identifier of the bus stop as defined by Transantiago. This argument must not be `nil`.
 
 @param requestedServices Set of strings with service identifiers you want the estimate as defined by Transantiago.
 
 @param handler Asynchronously called block to handle the response (result is an array)
 
 @discussion requestedServices can be nil, in that case all the bus services of the bus stop are requested.
  
*/
- (void)estimateAtBusStop:(NSString *)busStop services:(NSArray *)requestedServices handler:(CFSapoResultBlock)handler;

/**
 Fetches the bus stops inside a UTM Rect
 
 @param rect The UTM rect with equal sides (a square). This argument must not be `nil`.
 
 @param handler Asynchronously called block to handle the response (result is an array)
 
 @discussion In case the rect is not square, the minimum length is used.
 
*/
- (void)busStopsWithinUTMRect:(UTMRect)rect handler:(CFSapoResultBlock)handler;

/**
 Fetches the bus stops within radius of a coordinate
 
 @param coordinate The coordinates to center. This argument must not be `nil`.
 
 @param radius The radius around the coordinate. This argument must not be `nil`. 
 
 @param handler Asynchronously called block to handle the response (result is an array)
 
 @discussion If the radius is 0, the nearest bus stop is fetched.
 
 */
- (void)busStopsAroundCoordinate:(CLLocationCoordinate2D)coordinate radius:(double)radius handler:(CFSapoResultBlock)handler;

/**
 Fetches the bip spots within radius of a coordinate
 
 @param coordinate The coordinates to center. This argument must not be `nil`.
 
 @param radius The radius around the coordinate. This argument must not be `nil`.
 
 @param handler Asynchronously called block to handle the response (result is an array)
 
 @discussion If the radius is 0, the nearest bus stop is fetched.
 
 */
- (void)bipSpotsAroundCoordinate:(CLLocationCoordinate2D)coordinate radius:(double)radius handler:(CFSapoResultBlock)handler;

/**
 Fetches the route of a bus service
 
 @param service Identifier of the service as defined by Transantiago. This argument must not be `nil`.
 
 @param direction Direction for the requested route.
 
 @param handler Asynchronously called block to handle the response (result is an array)
 
 */
- (void)serviceInfoForService:(NSString *)service handler:(CFSapoResultBlock)handler;

/**
 Fetches the route of a bus service
 
 @param service Identifier of the service as defined by Transantiago. This argument must not be `nil`.
 
 @param direction Direction for the requested route.
 
 @param handler Asynchronously called block to handle the response (result is an array)

*/
- (void)routeForBusService:(NSString *)service direction:(CFDirection)direction handler:(CFSapoResultBlock)handler;

/**
 Fetches a bus stop object
 
 @param busStop Identifier of the bus stop as defined by Transantiago. This argument must not be `nil`.
 
 @param handler Asynchronously called block to handle the response (result is a dictionary)
 
 */
- (void)fetchBusStop:(NSString *)busStop handler:(CFSapoResultBlock)handler;

@end
