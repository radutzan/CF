//
//  CFNavigatorController.m
//  CF
//
//  Created by Radu Dutzan on 4/2/15.
//  Copyright (c) 2015 Onda. All rights reserved.
//

#import "CFNavigatorController.h"
#import "CFTransparentView.h"

@interface CFNavigatorController ()

@property (nonatomic, strong) UINavigationBar *localNavigationBar;
@property (nonatomic, strong) UIToolbar *localToolbar;
@property (nonatomic) BOOL navigating;

@end

@implementation CFNavigatorController

- (void)loadView
{
    self.view = [[CFTransparentView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.localNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, -128.0, self.view.bounds.size.width, 128.0)];
    self.localNavigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.localNavigationBar];
    
    self.localToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 44)];
    [self.view addSubview:self.localToolbar];
    
    UIBarButtonItem *exitButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Exit Navigation" style:UIBarButtonItemStyleDone target:self action:@selector(exitNavigation)];
    
    UIBarButtonItem *flexSpace1Item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.locationButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    [self.locationButton setImage:[[UIImage imageNamed:@"location"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.locationButton setImage:[[UIImage imageNamed:@"location-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    [self.locationButton addTarget:self action:@selector(goToUserLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.locationButton sizeToFit];
    UIBarButtonItem *locationButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.locationButton];
    
    self.localToolbar.items = @[exitButtonItem, flexSpace1Item, locationButtonItem];
}

- (void)enterNavigation
{
    self.navigating = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigatorWillTakeOver)]) {
        [self.delegate navigatorWillTakeOver];
    }
    
    // display navigation search bar (two textfields, etc)
    // display bottom buttons (exit navigation, current location)
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
        self.localNavigationBar.center = CGPointMake(self.localNavigationBar.center.x, self.localNavigationBar.center.y + self.localNavigationBar.bounds.size.height);
        self.localToolbar.center = CGPointMake(self.localToolbar.center.x, self.localToolbar.center.y - self.localToolbar.bounds.size.height);
    } completion:nil];
}

// maybe methods to pause/hide (vs quitting)
// entering navigation should be as state-agnostic as possible in order to automatically restore whatever was up

- (void)exitNavigation
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigatorWillTakeOver)]) {
        [self.delegate navigatorWillRetreat];
    }
    
    // hide all currently displayed navigator UI
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
        self.localNavigationBar.center = CGPointMake(self.localNavigationBar.center.x, self.localNavigationBar.center.y - self.localNavigationBar.bounds.size.height);
        self.localToolbar.center = CGPointMake(self.localToolbar.center.x, self.localToolbar.center.y + self.localToolbar.bounds.size.height);
    } completion:^(BOOL finished) {
        self.navigating = NO;
    }];
}

- (void)goToUserLocation
{
    [self.mapController setInitialRegionAnimated:YES];
    self.locationButton.selected = YES;
}

- (void)findDirectionsFromCurrentLocationToSearchablePlace:(NSString *)placeSearchString
{
    // get current location
    // do local search
    // present options if any
    // send them over:
    //    [self findDirectionsFrom:currentLocCoord to:destinationCoord];
}

- (void)findDirectionsFrom:(CLLocationCoordinate2D)originCoordinate to:(CLLocationCoordinate2D)destinationCoordinate
{
    // direction magic TBD
}

@end
