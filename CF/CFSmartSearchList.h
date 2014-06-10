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
- (void)show;
- (void)hide;

@property (nonatomic, weak) id<CFSmartSearchListDelegate> delegate;
@property (nonatomic, readonly) BOOL suggesting;
@property (nonatomic) UIEdgeInsets contentInset;

@end
