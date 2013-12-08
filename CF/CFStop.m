//
//  HOStop.m
//  Hop Out
//
//  Created by Diego Torres on 9/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFStop.h"
#import "math.h"

static NSRegularExpression *regexParadaConNumero;
static NSRegularExpression *regexInterseccion;
static NSRegularExpression *regexMetroSinNumero;

@interface CFStop ()

@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *code;
@property (nonatomic, readwrite) NSArray *services;
@property (strong, nonatomic, readwrite) NSString *street;
@property (strong, nonatomic, readwrite) NSString *intersection;
@property (nonatomic, readwrite, getter = isMetro) BOOL metro;
@property (nonatomic, readwrite) NSUInteger number;

@end

@implementation CFStop

+ (instancetype)stopWithCoordinate:(CLLocationCoordinate2D)coords code:(NSString *)code name:(NSString *)name services:(NSArray *)services
{
    CFStop *stop = [[self alloc] init];
    stop.coordinate = coords;
    stop.code = [code copy];
    stop.name = [name copy];
    stop.services = [NSArray arrayWithArray:services];
    return stop;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ – %@ (%f, %f)", self.code, self.name, self.coordinate.latitude, self.coordinate.longitude];
}

- (NSString *)title
{
    return self.name;
}

- (void)setName:(NSString *)name
{
    _name = name;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSRegularExpressionOptions options = (NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators);
        regexParadaConNumero = [NSRegularExpression regularExpressionWithPattern:@"^PARADA ([0-9]+) / (\\(M\\))? ?(.*)$" options:options error:NULL];
        regexInterseccion = [NSRegularExpression regularExpressionWithPattern:@"(.*) / (.*)" options:options error:NULL];
        regexMetroSinNumero = [NSRegularExpression regularExpressionWithPattern:@"\\(M\\)(.*)" options:options error:NULL];
    });
    
    NSRange rangoNombre = NSMakeRange(0, self.name.length);
    
    //Probamos Parada con Numero
    NSTextCheckingResult *result = [regexParadaConNumero firstMatchInString:self.name options:0 range:rangoNombre];
    
    //Probamos Interseccion
    if (!result) {
        result = [regexInterseccion firstMatchInString:self.name options:0 range:rangoNombre];
    }
    
    //Debe ser un Metro sin numero...
    if (!result) {
        result = [regexMetroSinNumero firstMatchInString:self.name options:0 range:rangoNombre];
    }
    
    if (result.regularExpression == regexParadaConNumero) {
        NSRange rangoMetro = [result rangeAtIndex:2];
        
        self.metro = (rangoMetro.location != NSNotFound);
        self.number = [[self.name substringWithRange:[result rangeAtIndex:1]] integerValue];
        
        NSRange rangoResto = [result rangeAtIndex:3];
        NSString *nombreParcial = [self.name substringWithRange:rangoResto];
        NSArray *intersecciones = [nombreParcial componentsSeparatedByString:@" - "];
        
        if ([intersecciones count] == 2) {
            self.street = intersecciones[0];
            self.intersection = intersecciones[1];
        } else {
            self.street = nombreParcial;
        }
        
    } else if (result.regularExpression == regexInterseccion) {
        self.street = [self.name substringWithRange:[result rangeAtIndex:1]];
        self.intersection = [self.name substringWithRange:[result rangeAtIndex:2]];
        
    } else if (result.regularExpression == regexMetroSinNumero) {
        self.metro = YES;
        self.street = [self.name substringWithRange:[result rangeAtIndex:1]];
        
    } else {
        self.street = self.name;
    }
    
    self.street = [[self.street lowercaseString] capitalizedString];
    self.intersection = [[self.intersection lowercaseString] capitalizedString];
    
    NSString *assembledName = [[name lowercaseString] capitalizedString];
    
    _name = assembledName;
}

#pragma mark - Favorite support

- (NSDictionary *)asDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:self.name forKey:@"nombre"];
    [dict setObject:self.code forKey:@"codigo"];
    [dict setObject:self.street forKey:@"calle"];
    if (self.intersection) [dict setObject:self.intersection forKey:@"interseccion"];
    [dict setObject:[NSNumber numberWithBool:self.metro] forKey:@"metro"];
    [dict setObject:[NSNumber numberWithInt:self.number] forKey:@"numero"];
    if (self.favoriteName) [dict setObject:self.favoriteName forKey:@"favoriteName"];
    [dict setObject:[NSNumber numberWithBool:self.isFavorite] forKey:@"favorite"];
    
    return dict;
}

+ (NSArray *)favoritesArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *favorites = [defaults arrayForKey:@"favorites"];
    
    if (!favorites) {
        favorites = [NSArray new];
    }
    
    return favorites;
}

+ (void)saveFavoritesWithArray:(NSArray *)array
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:array forKey:@"favorites"];
    [defaults synchronize];
}

- (void)setFavoriteWithName:(NSString *)favoriteName
{
    self.favorite = YES;
    self.favoriteName = favoriteName;
}

- (void)setFavoriteName:(NSString *)favoriteName
{
    NSMutableArray *mutableFavoritesArray = [[CFStop favoritesArray] mutableCopy];
    
    if (self.isFavorite) {
        for (NSDictionary *stop in mutableFavoritesArray) {
            if ([[stop objectForKey:@"codigo"] isEqualToString:self.code]) {
                NSMutableDictionary *mutableStop = [stop mutableCopy];
                [mutableFavoritesArray removeObject:stop];
                [mutableStop setValue:favoriteName forKey:@"favoriteName"];
                [mutableFavoritesArray addObject:mutableStop];
            }
        }
        
        [CFStop saveFavoritesWithArray:mutableFavoritesArray];
    }
}

- (NSString *)favoriteName
{
    if (self.isFavorite) {
        for (NSDictionary *stop in [CFStop favoritesArray]) {
            if ([[stop objectForKey:@"codigo"] isEqualToString:self.code])
                return [stop objectForKey:@"favoriteName"];
        }
    }
    return nil;
}

- (void)setFavorite:(BOOL)favorite
{
    NSMutableArray *mutableFavoritesArray = [[CFStop favoritesArray] mutableCopy];
    
    if (favorite) {
        BOOL added = NO;
        
        for (NSDictionary *stop in [CFStop favoritesArray]) {
            NSString *checkedStopCode = [stop objectForKey:@"codigo"];
            
            if ([checkedStopCode isEqualToString:self.code]) added = YES;
        }
        
        if (!added) {
            [mutableFavoritesArray addObject:[self asDictionary]];
        }
    } else {
        for (NSDictionary *stop in [CFStop favoritesArray]) {
            NSString *checkedStopCode = [stop objectForKey:@"codigo"];
            
            if ([checkedStopCode isEqualToString:self.code]) [mutableFavoritesArray removeObject:stop];
        }
    }
    
    NSArray *favoritesToWrite = [mutableFavoritesArray copy];
    [CFStop saveFavoritesWithArray:favoritesToWrite];
}

- (BOOL)isFavorite
{
    for (NSDictionary *stop in [CFStop favoritesArray]) {
        NSString *checkedStopCode = [stop objectForKey:@"codigo"];
        
        if ([checkedStopCode isEqualToString:self.code]) return YES;
    }
    
    return NO;
}

#pragma mark - Coding

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.coordinate = CLLocationCoordinate2DMake([decoder decodeDoubleForKey:@"latitude"], [decoder decodeDoubleForKey:@"longitude"]);
    self.code = [decoder decodeObjectForKey:@"code"];
    self.name = [decoder decodeObjectForKey:@"name"];
    self.services = [decoder decodeObjectForKey:@"services"];
    self.favorite = [decoder decodeBoolForKey:@"favorite"];
    self.favoriteName = [decoder decodeObjectForKey:@"favoriteName"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeDouble:self.coordinate.latitude forKey:@"latitude"];
    [encoder encodeDouble:self.coordinate.longitude forKey:@"longitude"];
    [encoder encodeObject:self.code forKey:@"code"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.services forKey:@"services"];
    [encoder encodeBool:self.favorite forKey:@"favorite"];
    [encoder encodeObject:self.favoriteName forKey:@"favoriteName"];
}

#pragma mark - Equality and hashing

- (BOOL)isEqual:(CFStop *)object {
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    if (fabs(object.coordinate.latitude - self.coordinate.latitude) > DBL_EPSILON) {
        return NO;
    }
    
    if (fabs(object.coordinate.longitude - object.coordinate.longitude) > DBL_EPSILON) {
        return NO;
    }
    
    return YES;
}

#define HASHFACTOR 2654435761U

CF_INLINE NSUInteger HOHashDouble(double d) {
    double dInt;
    if (d < 0) d = -d;
    dInt = floor(d+0.5);
    CFHashCode integralHash = HASHFACTOR * (CFHashCode)fmod(dInt, (double)ULONG_MAX);
    return (CFHashCode)(integralHash + (CFHashCode)((d - dInt) * ULONG_MAX));
}

- (NSUInteger)hash
{
    return [self.code hash] ^ HOHashDouble(self.coordinate.latitude) ^ HOHashDouble(self.coordinate.longitude);
}

@end
