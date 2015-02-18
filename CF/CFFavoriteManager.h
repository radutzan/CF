//
//  CFFavoriteManager.h
//  CF
//
//  Created by Radu Dutzan on 2/17/15.
//  Copyright (c) 2015 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CFStop.h"

@interface CFFavoriteManager : NSObject

+ (instancetype)sharedManager;
- (void)addFavorite:(CFStop *)favorite;
- (void)addFavorite:(CFStop *)favorite withName:(NSString *)favoriteName;
- (void)setName:(NSString *)newName forFavorite:(CFStop *)favorite;
- (NSString *)nameForFavorite:(CFStop *)favorite;
- (void)removeFavorite:(CFStop *)favorite;
- (void)saveFavoritesArray:(NSArray *)favoritesArray;
- (BOOL)isStopFavorite:(CFStop *)stop;
- (NSArray *)favoritesArray;

@end
