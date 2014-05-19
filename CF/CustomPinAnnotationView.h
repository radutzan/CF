//
//  CustomPinAnnotationView.h
//  CF
//
//  Created by Radu Dutzan on 5/19/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

@interface CustomPinAnnotationView : MKAnnotationView

@property (strong, nonatomic) SMCalloutView *calloutView;

@end