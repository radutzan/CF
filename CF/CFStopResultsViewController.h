//
//  CFStopResultsViewController.h
//  CF
//
//  Created by Radu Dutzan on 11/17/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFStop.h"

typedef NS_ENUM(NSInteger, CFStopResultsDisplayMode) {
    CFStopResultsDisplayModePresented,
    CFStopResultsDisplayModeContained,
    CFStopResultsDisplayModeMinimized,
    CFStopResultsDisplayModeNone
};

@protocol CFStopResultsViewControllerDelegate <NSObject>

- (void)stopResultsViewWasPromotedFromContainment;
- (void)stopResultsViewControllerDidUpdateUserData;
- (void)stopResultsViewControllerDidRequestServiceRoute:(NSString *)serviceName directionString:(NSString *)directionString;

@end

@interface CFStopResultsViewController : UIViewController

// these add self to a parent view controller if there is none, and just expand if there already is one
- (void)presentOnViewController:(UIViewController *)onViewController;
- (void)presentFromRect:(CGRect)rect onViewController:(UIViewController *)onViewController;

/* Contains the view in the requested `rect` without interfering with the rest of the chrome. If there is no `parentViewController` assigned (the view is not currently on screen), this method will assign the instance to the `onViewController` and animate the view in. This method can also be called when the instance is already contained and a change of frame is required.
 */
- (void)containOnRect:(CGRect)rect onViewController:(UIViewController *)onViewController;

/* Expands the view to a presented mode. This method assumes there is an assigned `parentViewController` (the view is currently on screen). If there isn't, this method does nothing.
 */
- (void)expand;

/* Minimizes the view to the bottom of the screen, so that only the title portion is visible. This method assumes there is an assigned `parentViewController` (the view is currently on screen). If there isn't, this method does nothing.
 */
- (void)minimize;

/* Animates the view out of the screen and removes it from the `parentViewController`.
 */
- (void)dismiss;

@property (nonatomic, strong) NSString *stopCode;
@property (nonatomic, strong) CFStop *stop;
@property (nonatomic, assign, readonly) CFStopResultsDisplayMode displayMode;
@property (nonatomic, assign) id<CFStopResultsViewControllerDelegate> delegate;

@end
