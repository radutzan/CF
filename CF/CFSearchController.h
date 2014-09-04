//
//  CFSmartSearchList.h
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFSapoClient.h"
#import "CFSearchField.h"
#import "CFStop.h"
#import "CFService.h"

@protocol CFSearchControllerDelegate <NSObject>

- (void)searchControllerWillHide;
- (void)searchControllerDidBeginSearching;
- (void)searchControllerDidEndSearching;
- (void)searchControllerNeedsStopCardForStop:(CFStop *)stop;
- (void)searchControllerDidClearStopSuggestions;
- (void)searchControllerRequestedLocalSearch:(NSString *)searchString;
- (void)searchControllerDidSelectService:(CFService *)service direction:(CFDirection)direction;

@end

@interface CFSearchController : UIView

- (void)show;
- (void)hide;

@property (nonatomic, weak) id<CFSearchControllerDelegate> delegate;
@property (nonatomic, strong) CFSearchField *searchField;
@property (nonatomic, readonly) BOOL suggesting;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic, strong) UIView *containerView;

@end
