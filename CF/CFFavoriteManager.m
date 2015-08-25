//
//  CFFavoriteManager.m
//  CF
//
//  Created by Radu Dutzan on 2/17/15.
//  Copyright (c) 2015 Onda. All rights reserved.
//

#import "CFFavoriteManager.h"
#import <WatchConnectivity/WatchConnectivity.h>

@interface CFFavoriteManager () <WCSessionDelegate>

@property (nonatomic) WCSession *session;

@end

@implementation CFFavoriteManager

+ (instancetype)sharedManager
{
    static CFFavoriteManager *favoriteManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        favoriteManager = [self new];
        if (NSClassFromString(@"WCSession")) {
            if ([WCSession isSupported]) {
                favoriteManager.session = [WCSession defaultSession];
                favoriteManager.session.delegate = favoriteManager;
                [favoriteManager.session activateSession];
            }
        }
    });
    return favoriteManager;
}

- (void)addFavorite:(CFStop *)favorite
{
    if (!favorite) return;
    NSMutableArray *mutableFavoritesArray = [[self favoritesArray] mutableCopy];
    
    BOOL added = NO;
    
    for (NSDictionary *stop in [self favoritesArray]) {
        NSString *checkedStopCode = [stop objectForKey:@"codigo"];
        if ([checkedStopCode isEqualToString:favorite.code]) added = YES;
    }
    
    if (!added) [mutableFavoritesArray addObject:[favorite asDictionary]];
    
    [self saveFavoritesArray:[mutableFavoritesArray copy]];
}

- (void)addFavorite:(CFStop *)favorite withName:(NSString *)favoriteName
{
    [self addFavorite:favorite];
    [self setName:favoriteName forFavorite:favorite];
}

- (void)setName:(NSString *)newName forFavorite:(CFStop *)favorite
{
    NSMutableArray *mutableFavoritesArray = [[self favoritesArray] mutableCopy];
    
    if (favorite.isFavorite) {
        for (NSDictionary *stop in [self favoritesArray]) {
            if ([[stop objectForKey:@"codigo"] isEqualToString:favorite.code]) {
                NSMutableDictionary *mutableStop = [stop mutableCopy];
                [mutableFavoritesArray removeObject:stop];
                [mutableStop setValue:newName forKey:@"favoriteName"];
                [mutableFavoritesArray addObject:mutableStop];
            }
        }
        
        [self saveFavoritesArray:[mutableFavoritesArray copy]];
    }
}

- (NSString *)nameForFavorite:(CFStop *)favorite
{
    if ([self isStopFavorite:favorite]) {
        for (NSDictionary *stop in [self favoritesArray]) {
            if ([[stop objectForKey:@"codigo"] isEqualToString:favorite.code])
                return [stop objectForKey:@"favoriteName"];
        }
    }
    return nil;
}

- (void)removeFavorite:(CFStop *)favorite
{
    if (!favorite) return;
    NSMutableArray *mutableFavoritesArray = [[self favoritesArray] mutableCopy];
    
    for (NSDictionary *stop in [self favoritesArray]) {
        NSString *checkedStopCode = [stop objectForKey:@"codigo"];
        if ([checkedStopCode isEqualToString:favorite.code]) [mutableFavoritesArray removeObject:stop];
    }
    
    [self saveFavoritesArray:[mutableFavoritesArray copy]];
}

- (void)saveFavoritesArray:(NSArray *)favoritesArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:favoritesArray forKey:@"favorites"];
    [defaults synchronize];
    
    [self synchronize];
}

- (NSArray *)favoritesArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *favorites = [defaults arrayForKey:@"favorites"];
    
    if (!favorites) favorites = [NSArray new];
    
    return favorites;
}

- (BOOL)isStopFavorite:(CFStop *)stop
{
    for (NSDictionary *favoriteStop in [self favoritesArray]) {
        NSString *checkedStopCode = [favoriteStop objectForKey:@"codigo"];
        if ([checkedStopCode isEqualToString:stop.code]) return YES;
    }
    
    return NO;
}

- (void)synchronize
{
    NSArray *favoritesArray = [self favoritesArray];
    
#ifdef DEV_VERSION
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfbetagroup"];
    [sharedDefaults setObject:favoritesArray forKey:@"favorites"];
    [sharedDefaults synchronize];
#else
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfgroup"];
    [sharedDefaults setObject:favoritesArray forKey:@"favorites"];
    [sharedDefaults synchronize];
#endif
    
    [[NSUbiquitousKeyValueStore defaultStore] setArray:favoritesArray forKey:@"favorites"];
    
    if (NSClassFromString(@"WCSession")) {
        if ([WCSession isSupported]) {
            if (self.session.paired) {
                if (self.session.watchAppInstalled) {
                    NSDictionary *favContext = @{@"favorites": favoritesArray};
                    [self.session updateApplicationContext:favContext error:nil];
                }
            }
        }
    }
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
    NSLog(@"got message");
    replyHandler(@{@"favorites": [self favoritesArray]});
}

@end
