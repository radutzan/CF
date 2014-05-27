//
//  CFNavigationController.m
//  CF
//
//  Created by Radu Dutzan on 12/8/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFNavigationController.h"
#import "CFNavigationBar.h"
#import "CFMainViewController.h"

@interface CFNavigationController ()

@end

@implementation CFNavigationController

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
    self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
    if (self) {
        [self setViewControllers:@[[CFMainViewController new]]];
    }
    return self;
}

@end
