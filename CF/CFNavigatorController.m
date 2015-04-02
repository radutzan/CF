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
@property (nonatomic) BOOL navigating;

@end

@implementation CFNavigatorController

- (void)loadView
{
    self.view = [[CFTransparentView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.localNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, -128.0, self.view.bounds.size.width, 128.0)];
    self.localNavigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.localNavigationBar];
    
    UIBarButtonItem *exitButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(exitNavigation)];
    
    UINavigationItem *navItem = [UINavigationItem new];
    navItem.rightBarButtonItems = @[exitButtonItem];
    [self.localNavigationBar pushNavigationItem:navItem animated:NO];
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
    } completion:^(BOOL finished) {
        self.navigating = NO;
    }];
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
