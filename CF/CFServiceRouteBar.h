//
//  CFServiceSuggestionView.h
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFService.h"

@protocol CFServiceRouteBarDelegate <NSObject>

/**
 indexes: 0 is outward, 1 is inward
 */
- (void)serviceRouteBarSelectedButtonAtIndex:(NSUInteger)index service:(CFService *)service;

@end

@interface CFServiceRouteBar : UIView

@property (nonatomic, strong) CFService *service;
@property (nonatomic, strong) NSString *outwardDirectionString;
@property (nonatomic, strong) NSString *inwardDirectionString;
@property (nonatomic, weak) id<CFServiceRouteBarDelegate> delegate;

@end
