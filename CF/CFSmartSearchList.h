//
//  CFSmartSearchList.h
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFSapoClient.h"

@protocol CFSmartSearchListDelegate <NSObject>

- (void)smartSearchListDidSelectStop:(NSString *)stopCode;
- (void)smartSearchListDidSelectService:(NSString *)serviceName direction:(CFDirection)direction;
- (void)smartSearchListDidSelectService:(NSString *)serviceName directionString:(NSString *)directionString;

@end

@interface CFSmartSearchList : UIView

- (void)processSearchString:(NSString *)searchString;

@property (nonatomic, weak) id<CFSmartSearchListDelegate> delegate;

@end
