//
//  CFAppDelegate.m
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFAppDelegate.h"
#import <Mixpanel/Mixpanel.h>
#import "Crittercism.h"
#import "OLCashier.h"
#import "CFFavoriteManager.h"

@interface CFAppDelegate ()

@property (nonatomic, strong) CFMainViewController *mainViewController;

@end

@implementation CFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Mixpanel sharedInstanceWithToken:@"9fda86f01e8e8821542524d96b1f7cfb"];
    
    [Crittercism enableWithAppID: @"52c8e7844002052b9f000004"];
    
    OLCashier *cashier = [OLCashier defaultCashier];
    
    [cashier setDefaultTransactionHandler:^(NSError *error, NSArray *transactions, NSDictionary *userInfo){
        SKPaymentTransaction *transaction = transactions.firstObject;
        if (error) {
            return;
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:transaction.payment.productIdentifier];
        [transaction finish];
    }];
    
    [cashier setProductsWithIdentifiers:[NSSet setWithObjects:@"CF01", @"CF02", nil] handler:NULL];
    
    self.mainViewController = [CFMainViewController new];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    self.window.tintColor = [UIColor colorWithHue:135.0/360.0 saturation:0.70 brightness:0.80 alpha:1];
    [self.window makeKeyAndVisible];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cloudKeyValueStoreDidChange:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:[NSUbiquitousKeyValueStore defaultStore]];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (url) {
        [self.mainViewController processExternalURL:url];
    }
    return YES;
}

- (void)cloudKeyValueStoreDidChange:(NSNotification *)notification
{
    NSArray *updatedFavorites = [[NSUbiquitousKeyValueStore defaultStore] objectForKey:@"favorites"];
    [[CFFavoriteManager sharedManager] saveFavoritesArray:updatedFavorites];
    
    [self.mainViewController reloadUserData];
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
