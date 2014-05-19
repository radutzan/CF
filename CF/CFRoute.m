//
//  CFRoute.m
//  Hop Out
//
//  Created by Diego Torres on 8/9/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "HOFunctions.h"
#import "CFRoute.h"
#import "CFStop.h"
#import <MapKit/MKPolyline.h>

static inline NSArray *HOOverlaysFromStopsAndCoordinates(NSArray *stops, CLLocationCoordinate2D *coordinates, NSUInteger count)
{
    //There will be stops - 1 overlays. 
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:([stops count] -1)];
    NSRange currentRange = NSMakeRange(0, 0);
    for (CFStop *stop in stops) {
        while (!HOLocation2DCoordinateEqualToCoordinate(stop.coordinate, coordinates[NSMaxRange(currentRange)])) {
            currentRange.length += 1;
        }
        currentRange.length += 1;
        if (currentRange.length < 2) {
            continue;
        }
        //Populate a subarray of coordinates until the stop
        CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D)*currentRange.length);
        NSUInteger maxRange = NSMaxRange(currentRange);
        for (NSUInteger i = currentRange.location; i < maxRange; i++) {
            coords[(i-currentRange.location)] = coordinates[i];
        }
        
        MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:currentRange.length];
        free(coords);
        [array addObject:polyline];
        
        //Move the location, reset the length.
        currentRange.location = NSMaxRange(currentRange)-1;
        currentRange.length = 0;
    }
    return array;
}

@interface CFRoute ()

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSArray *stops;
@property (nonatomic, readwrite) MKPolyline *polyline;
@property (nonatomic, readwrite) CLLocationCoordinate2D *coordinates;
@property (nonatomic, readwrite) NSUInteger coordinatesCount;

@end

@implementation CFRoute

+ (instancetype)routeWithServiceName:(NSString *)serviceName stops:(NSArray *)stops routeCoordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count
{
    CFRoute *route = [[self alloc] initWithServiceName:serviceName stops:stops routeCoordinates:coordinates count:count];
    return route;
}

- (id)initWithServiceName:(NSString *)serviceName stops:(NSArray *)stops routeCoordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count
{
    self = [super init];
    if (self) {
        self.stops = [stops copy];
        self.coordinatesCount = count;
        self.name = serviceName;
        size_t coordsSize = sizeof(CLLocationCoordinate2D)*count;
        CLLocationCoordinate2D *newCoords = malloc(coordsSize);
        memcpy(newCoords, coordinates, coordsSize);
        self.coordinates = newCoords;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    NSString *name = [decoder decodeObjectForKey:@"name"];
    NSArray *stops = [decoder decodeObjectForKey:@"stops"];
    NSUInteger coordinatesCount = [decoder decodeInt64ForKey:@"coordinatesCount"];
    NSData *coordsData = [decoder decodeObjectForKey:@"coordinates"];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)coordsData.bytes;
    return [self initWithServiceName:name stops:stops routeCoordinates:coordinates count:coordinatesCount];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.stops forKey:@"stops"];
    [encoder encodeInt64:self.coordinatesCount forKey:@"coordinatesCount"];
    
    NSData *coordsData = [NSData dataWithBytes:self.coordinates length:sizeof(CLLocationCoordinate2D)*self.coordinatesCount];
    [encoder encodeObject:coordsData forKey:@"coordinates"];
}

- (MKPolyline *)polyline
{
    if (!_polyline && self.coordinatesCount > 0 && self.coordinates != nil) {
        _polyline = [MKPolyline polylineWithCoordinates:self.coordinates count:self.coordinatesCount];
    }
    return _polyline;
}

- (BOOL)isEqual:(CFRoute *)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    if (![object.stops isEqualToArray:self.stops]) {
        return NO;
    }
    
    return YES;
}

@end
