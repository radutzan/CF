//
//  HOFunctions.m
//  Hop Out
//
//  Created by Diego Torres on 9/21/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "HOFunctions.h"

inline BOOL HOLocation2DCoordinateEqualToCoordinate(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2)
{
    return (fabs(coord1.latitude - coord2.latitude) <= DBL_EPSILON &&
            fabs(coord1.longitude - coord2.longitude) <= DBL_EPSILON);
}