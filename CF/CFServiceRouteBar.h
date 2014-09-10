//
//  CFServiceSuggestionView.h
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFService.h"

@class CFServiceRouteBar;

@protocol CFServiceRouteBarDelegate <NSObject>

/**
 indexes: 0 is outward, 1 is inward
 */
- (void)serviceRouteBar:(CFServiceRouteBar *)serviceRouteBar selectedButtonAtIndex:(NSUInteger)index service:(CFService *)service;

@optional
- (void)serviceRouteBarDidDismiss:(CFServiceRouteBar *)serviceRouteBar;

@end

@interface CFServiceRouteBar : UIView

@property (nonatomic, strong) CFService *service;
@property (nonatomic, strong) NSString *outwardDirectionString;
@property (nonatomic, strong) NSString *inwardDirectionString;
@property (nonatomic, weak) id<CFServiceRouteBarDelegate> delegate;
@property (nonatomic, assign) NSUInteger selectedDirection;
@property (nonatomic, assign) BOOL dismissible;

@end
