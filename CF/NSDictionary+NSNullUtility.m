//
//  NSDictionary+NSNullUtility.m
//  MMT
//
//  Created by Ana Heredia on 23-06-12.
//  Copyright (c) 2012 Onda. All rights reserved.
//

#import "NSDictionary+NSNullUtility.h"

@implementation NSDictionary (NSNullUtility)

- (id)objectForKeyNotNull:(id)aKey
{
    id object = [self objectForKey:aKey];
    if (object == [NSNull null]) return nil;
    return object;
}

@end
