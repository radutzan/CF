//
//  HOStop.h
//  Hop Out
//
//  Created by Diego Torres on 9/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <MapKit/MKAnnotation.h>

@interface CFStop : NSObject <NSCoding, MKAnnotation>

@property (nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *street;
@property (strong, nonatomic, readonly) NSString *intersection;
@property (nonatomic, readonly) NSUInteger number;

@property (nonatomic, readonly, getter = isMetro) BOOL metro;
@property (nonatomic, assign, getter = isFavorite) BOOL favorite;
@property (nonatomic, strong) NSString *favoriteName;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSString *code;
@property (nonatomic, readonly) NSArray *services;

+ (instancetype)stopWithCoordinate:(CLLocationCoordinate2D)coords code:(NSString *)code name:(NSString *)name services:(NSArray *)services;
- (NSDictionary *)asDictionary;

@end
