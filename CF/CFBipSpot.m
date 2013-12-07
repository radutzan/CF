//
//  CFBipSpot.m
//  CF
//
//  Created by Radu Dutzan on 12/7/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFBipSpot.h"

@interface CFBipSpot ()

@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) NSString *subtitle;

@end

@implementation CFBipSpot

+ (instancetype)bipSpotWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title subtitle:(NSString *)subtitle
{
    CFBipSpot *spot = [CFBipSpot new];
    spot.coordinate = coordinate;
    spot.title = [title copy];
    spot.subtitle = [subtitle copy];
    
    return spot;
}

@end
