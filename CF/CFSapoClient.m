//
//  CFSapoClient.m
//  CuantoFaltaiOS
//
//  Created by Diego Torres on 15-11-12.
//  Copyright (c) 2012 Onda. All rights reserved.
//

#import "CFSapoClient.h"
#import <AFNetworking/AFJSONRequestOperation.h>
#import "UIDevice+hardware.h"
#import "NSString+Digest.h"

static dispatch_once_t onceToken;
static CFSapoClient *_sharedSapoClient;
NSString * const APIVersion = @"1.3.0";
NSString * const baseURLString = @"http://api.cuantofalta.mobi";
NSString * const queryKeySalt = @"4ESMLSVB_ONDA";

@implementation CFSapoClient

+ (id)sharedClient
{
    dispatch_once(&onceToken, ^{
        NSString *urlString = baseURLString;
        #ifdef DEBUG
//        urlString = [urlString stringByAppendingString:@":3000"];
        #endif
        _sharedSapoClient = (CFSapoClient *)[self clientWithBaseURL:[NSURL URLWithString:urlString]];
        [_sharedSapoClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [_sharedSapoClient setDefaultHeader:@"Accept" value:@"application/json"];
        [_sharedSapoClient setDefaultHeader:@"X-Api-Version" value:APIVersion];

        [_sharedSapoClient setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@ %@ rv:%@ (%@; iOS %@; %@)",[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],(__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey],[[UIDevice currentDevice] model],[[UIDevice currentDevice] systemVersion],[[NSLocale currentLocale] localeIdentifier]]];
    });
    return _sharedSapoClient;
}

- (void)estimateAtBusStop:(NSString *)busStop services:(NSArray *)requestedServices handler:(CFSapoResultBlock)handler
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setObject:busStop forKey:@"parada"];
    //[params setObject:[requestedServices componentsJoinedByString:@","] forKey:@"servicios"];
    [params setObject:[UIDevice platform] forKey:@"device"];
    
    NSString *keyUnhashed = [NSString stringWithFormat:@"%@%@%@%@", queryKeySalt, [UIDevice platform], busStop, APIVersion];
    [params setObject:[keyUnhashed sha1] forKey:@"queryKey"];
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:@"/bus_stops/estimate" parameters:params];
    [request setTimeoutInterval:180];
    AFHTTPRequestOperation *oper = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        AFJSONRequestOperation *JSONop = (AFJSONRequestOperation *)operation;
        if (handler) {
            handler(nil, JSONop.responseJSON);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (handler) {
            handler(error, nil);
        }
    }];
    [self enqueueHTTPRequestOperation:oper];
}

- (void)busStopsWithinUTMRect:(UTMRect)rect handler:(CFSapoResultBlock)handler
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"UTM"] = @{@"x": [NSNumber numberWithDouble:rect.origin.x],
                       @"y": [NSNumber numberWithDouble:rect.origin.y],
                       @"length": [NSNumber numberWithDouble:MIN(rect.size.height, rect.size.width)]};
    [self getPath:@"/bus_stops" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        AFJSONRequestOperation *JSONop = (AFJSONRequestOperation *)operation;
        if (handler) {
            handler(nil, JSONop.responseJSON);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (handler) {
            handler(error, nil);
        }
    }];
}

- (void)busStopsAroundCoordinate:(CLLocationCoordinate2D)coordinate radius:(double)radius handler:(CFSapoResultBlock)handler
{
    NSDictionary *params = @{@"lat": [NSNumber numberWithDouble:coordinate.latitude],
                             @"long": [NSNumber numberWithDouble:coordinate.longitude],
                             @"range": radius > 0 ? [NSNumber numberWithDouble:radius] : @"nearest"};
    
    [self getPath:@"/bus_stops" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        AFJSONRequestOperation *JSONop = (AFJSONRequestOperation *)operation;
        if (handler) {
            handler(nil, JSONop.responseJSON);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (handler) {
            handler(error, nil);
        }
    }];
}

- (void)bipSpotsAroundCoordinate:(CLLocationCoordinate2D)coordinate radius:(double)radius handler:(CFSapoResultBlock)handler
{
    NSDictionary *params = @{@"lat": [NSNumber numberWithDouble:coordinate.latitude],
                             @"long": [NSNumber numberWithDouble:coordinate.longitude],
                             @"range": radius > 0 ? [NSNumber numberWithDouble:radius] : @"nearest"};
    
    [self getPath:@"/bip_spots" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        AFJSONRequestOperation *JSONop = (AFJSONRequestOperation *)operation;
        if (handler) {
            handler(nil, JSONop.responseJSON);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (handler) {
            handler(error, nil);
        }
    }];
}

- (void)fetchBusStop:(NSString *)busStop handler:(CFSapoResultBlock)handler
{
    NSDictionary *params = @{@"stop_code" : busStop };
    [self getPath:@"/bus_stops" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        AFJSONRequestOperation *JSONop = (AFJSONRequestOperation *)operation;
        if (handler) {
            handler(nil, JSONop.responseJSON);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (handler) {
            handler(error, nil);
        }
    }];
}

@end
