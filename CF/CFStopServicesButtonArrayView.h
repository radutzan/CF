//
//  CFStopServicesButtonArrayView.h
//  CF
//
//  Created by Radu Dutzan on 5/19/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CFStopServicesButtonArrayViewDelegate <NSObject>

- (void)servicesButtonArrayViewDidSelectService:(NSString *)serviceName;

@end

@interface CFStopServicesButtonArrayView : UIView

@property (nonatomic, strong) NSArray *services;
@property (nonatomic, weak) id<CFStopServicesButtonArrayViewDelegate> delegate;

@end
