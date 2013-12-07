//
//  NSString+Digest.h
//  CuantoFaltaiOS
//
//  Created by Diego Torres on 14-03-12.
//  Copyright (c) 2012 Onda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Digest)

- (NSString *)sha1;
- (NSString *)md5;

@end
