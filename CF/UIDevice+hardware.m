//
//  UIDevice+hardware.m
//  CuantoFaltaiOS
//
//  Created by Diego Torres on 2/13/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "UIDevice+Hardware.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation UIDevice (hardware)

static NSString *_platform;

+ (NSString *)platform
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        _platform = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return _platform;
}

@end
