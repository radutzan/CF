//
//  CFServiceRouteViewController.h
//  CF
//
//  Created by Radu Dutzan on 5/18/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFSapoClient.h"
#import "CFMapController.h"

@interface CFServiceRouteViewController : UIViewController

- (id)initWithService:(NSString *)service;
- (id)initWithService:(NSString *)service direction:(CFDirection)direction;
- (id)initWithService:(NSString *)service directionString:(NSString *)directionString;

@end
