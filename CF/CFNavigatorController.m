//
//  CFNavigatorController.m
//  CF
//
//  Created by Radu Dutzan on 4/2/15.
//  Copyright (c) 2015 Onda. All rights reserved.
//

#import "CFNavigatorController.h"
#import "CFTransparentView.h"
#import "CFNavigatorTextField.h"

@interface CFNavigatorController () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) UINavigationBar *localNavigationBar;
@property (nonatomic, strong) UIToolbar *localToolbar;
@property (nonatomic, strong) CFNavigatorTextField *topTextField;
@property (nonatomic, strong) CFNavigatorTextField *bottomTextField;
@property (nonatomic, strong) OLShapeTintedButton *switchTextFieldsButton;
@property (nonatomic, strong) OLShapeTintedButton *submitButton;

@property (nonatomic) BOOL navigating;

@end

@implementation CFNavigatorController

- (void)loadView
{
    self.view = [[CFTransparentView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.overlay.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
    self.overlay.alpha = 0;
    [self.view addSubview:self.overlay];
    
    UITapGestureRecognizer *overlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overayTapped)];
    [self.overlay addGestureRecognizer:overlayTap];
    
    self.localNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, -128.0, self.view.bounds.size.width, 128.0)];
    self.localNavigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.localNavigationBar];
    
    self.topTextField = [[CFNavigatorTextField alloc] initWithFrame:CGRectMake(55, 28, self.localNavigationBar.bounds.size.width - 110, 40)];
    self.topTextField.placeholder = NSLocalizedString(@"FROM", nil);
    self.topTextField.delegate = self;
    [self.localNavigationBar addSubview:self.topTextField];
    
    self.bottomTextField = [[CFNavigatorTextField alloc] initWithFrame:CGRectOffset(self.topTextField.frame, 0, self.topTextField.bounds.size.height + 10)];
    self.bottomTextField.placeholder = NSLocalizedString(@"TO", nil);
    self.bottomTextField.delegate = self;
    [self.localNavigationBar addSubview:self.bottomTextField];
    
    self.switchTextFieldsButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    self.switchTextFieldsButton.frame = CGRectMake(0, 0, 44, 44);
    self.switchTextFieldsButton.center = CGPointMake(28, (self.localNavigationBar.bounds.size.height / 2) + 10);
    [self.switchTextFieldsButton setImage:[[UIImage imageNamed:@"button-switch"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.switchTextFieldsButton addTarget:self action:@selector(switchTextFields) forControlEvents:UIControlEventTouchUpInside];
    self.switchTextFieldsButton.layer.zPosition = 1000;
    [self.localNavigationBar addSubview:self.switchTextFieldsButton];
    
    self.submitButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
    self.submitButton.frame = CGRectMake(0, 0, 44, 44);
    self.submitButton.center = CGPointMake(self.topTextField.frame.origin.x + self.topTextField.bounds.size.width + 28, (self.localNavigationBar.bounds.size.height / 2) + 10);
    [self.submitButton setImage:[[UIImage imageNamed:@"searchfield-glyph"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate
                                 ] forState:UIControlStateNormal];
    [self.localNavigationBar addSubview:self.submitButton];
    
    // toolbar
    self.localToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 44)];
    [self.view addSubview:self.localToolbar];
    
    UIBarButtonItem *exitButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"EXIT_NAVIGATION", nil) style:UIBarButtonItemStyleDone target:self action:@selector(exitNavigation)];
    
    [exitButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:16],
                                             NSForegroundColorAttributeName: [UIApplication sharedApplication].keyWindow.tintColor} forState:UIControlStateNormal];
    
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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [UIView animateWithDuration:.3 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
        self.overlay.alpha = 1;
    } completion:nil];
}

- (void)overayTapped
{
    [UIView animateWithDuration:.42 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
        self.overlay.alpha = 0;
        [self.view endEditing:YES];
    } completion:nil];
}

- (void)switchTextFields
{
    CGPoint originalTopTFCenter = self.topTextField.center;
    CGPoint originalBottomTFCenter = self.bottomTextField.center;
    CGPoint centerCenter = CGPointMake(self.topTextField.center.x, (self.localNavigationBar.bounds.size.height / 2) + 10);
    self.switchTextFieldsButton.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.switchTextFieldsButton.layer.transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);
    } completion:^(BOOL finished) {
        self.switchTextFieldsButton.layer.transform = CATransform3DIdentity;
    }];
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.topTextField.center = centerCenter;
        self.topTextField.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.bottomTextField.center = centerCenter;
        self.bottomTextField.transform = CGAffineTransformMakeScale(.9, .9);
//        self.switchTextFieldsButton.layer.transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);
    } completion:^(BOOL finished) {
        self.topTextField.placeholder = NSLocalizedString(@"TO", nil);
        self.bottomTextField.placeholder = NSLocalizedString(@"FROM", nil);
        
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
            self.topTextField.center = originalBottomTFCenter;
            self.topTextField.transform = CGAffineTransformIdentity;
            self.bottomTextField.center = originalTopTFCenter;
            self.bottomTextField.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            NSString *bottomStorage = self.bottomTextField.text;
            self.bottomTextField.text = self.topTextField.text;
            self.bottomTextField.center = originalBottomTFCenter;
            self.bottomTextField.placeholder = NSLocalizedString(@"TO", nil);
            self.topTextField.text = bottomStorage;
            self.topTextField.center = originalTopTFCenter;
            self.topTextField.placeholder = NSLocalizedString(@"FROM", nil);
            self.switchTextFieldsButton.userInteractionEnabled = YES;
        }];
    }];
}

@end
