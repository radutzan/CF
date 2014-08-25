//
//  CFStopResultsViewController.h
//  CF
//
//  Created by Radu Dutzan on 11/17/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFStop.h"

@protocol CFStopResultsViewControllerDelegate <NSObject>

- (void)stopResultsViewControllerDidRequestServiceRoute:(NSString *)serviceName;

@end

@interface CFStopResultsViewController : UIViewController

- (instancetype)initWithStopCode:(NSString *)stopCode;
- (void)presentFromViewController:(UIViewController *)fromViewController;
- (void)presentFromRect:(CGRect)rect fromViewController:(UIViewController *)fromViewController;
- (void)expand;
- (void)minimize;
- (void)dismiss;

@property (nonatomic, strong) NSString *stopCode;
@property (nonatomic, strong) CFStop *stop;
@property (nonatomic, assign) id<CFStopResultsViewControllerDelegate> delegate;

@end
