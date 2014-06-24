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

@protocol CFSearchControllerDelegate <NSObject>

- (void)searchControllerDidBeginSearching;
- (void)searchControllerDidEndSearching;
- (void)searchControllerRequestedLocalSearch:(NSString *)searchString;
- (void)searchControllerDidSelectStop:(NSString *)stopCode;
- (void)searchControllerDidSelectService:(NSString *)serviceName direction:(CFDirection)direction;
- (void)searchControllerDidSelectService:(NSString *)serviceName directionString:(NSString *)directionString;

@end

@interface CFSearchController : UIView

- (void)show;
- (void)hide;

@property (nonatomic, weak) id<CFSearchControllerDelegate> delegate;
@property (nonatomic, strong) CFSearchField *searchField;
@property (nonatomic, readonly) BOOL suggesting;
@property (nonatomic) UIEdgeInsets contentInset;

@end
