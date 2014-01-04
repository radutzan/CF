//
//  CFAppDelegate.m
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFAppDelegate.h"
#import <Mixpanel/Mixpanel.h>
#import "OLCashier.h"

@implementation CFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[CFNavigationController alloc] initWithNavigationBarClass:[CFNavigationBar class] toolbarClass:nil];
    self.window.tintColor = [UIColor colorWithHue:130.0/360.0 saturation:0.9 brightness:0.9 alpha:1];
    [self.window makeKeyAndVisible];
    
    OLCashier *cashier = [OLCashier defaultCashier];
    
    [cashier setDefaultTransactionHandler:^(NSError *error, NSArray *transactions, NSDictionary *userInfo){
        SKPaymentTransaction *transaction = transactions.firstObject;
        if (error) {
#warning Handle Error
            return;
        }
#warning Handle successful purchase.
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:transaction.payment.productIdentifier];
        [transaction finish];
    }];
    
    [cashier setProductsWithIdentifiers:[NSSet setWithObjects:@"CF01", @"CF02", nil] handler:NULL];
    
    [Mixpanel sharedInstanceWithToken:@"9fda86f01e8e8821542524d96b1f7cfb"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
