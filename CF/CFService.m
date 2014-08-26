//
//  CFService.m
//  CF
//
//  Created by Radu Dutzan on 8/25/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFService.h"

@interface CFService ()

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *outwardDirectionName;
@property (nonatomic, readwrite) NSString *inwardDirectionName;

@end

@implementation CFService

+ (instancetype)serviceWithName:(NSString *)serviceName outwardDirectionName:(NSString *)outwardDirectionName inwardDirectionName:(NSString *)inwardDirectionName
{
    CFService *service = [[self alloc] initWithName:serviceName outwardDirectionName:outwardDirectionName inwardDirectionName:inwardDirectionName];
    return service;
}

- (instancetype)initWithName:(NSString *)serviceName outwardDirectionName:(NSString *)outwardDirectionName inwardDirectionName:(NSString *)inwardDirectionName
{
    self = [super init];
    if (self) {
        self.name = serviceName;
        self.outwardDirectionName = outwardDirectionName;
        self.inwardDirectionName = inwardDirectionName;
    }
    return self;
}

@end
