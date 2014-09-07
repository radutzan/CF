//
//  CFService.h
//  CF
//
//  Created by Radu Dutzan on 8/25/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CFService : NSObject

+ (instancetype)serviceWithName:(NSString *)serviceName outwardDirectionName:(NSString *)outwardDirectionName inwardDirectionName:(NSString *)inwardDirectionName;
- (BOOL)isEqualToService:(CFService *)service;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *outwardDirectionName;
@property (nonatomic, readonly) NSString *inwardDirectionName;

// to-do: add operation times

@end
