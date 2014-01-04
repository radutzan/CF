//
//  CFStoreViewController.m
//  CF
//
//  Created by Radu Dutzan on 1/4/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <Mixpanel/Mixpanel.h>
#import <OLGhostAlertView/OLGhostAlertView.h>
#import "CFStoreViewController.h"
#import "OLCashier.h"

@interface CFStoreViewController ()

@end

@implementation CFStoreViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = NSLocalizedString(@"STORE", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    NSString *thisIdentifier;
    
    if (indexPath.section == 0)
        thisIdentifier = @"CF01";
    else if (indexPath.section == 1)
        thisIdentifier = @"CF02";
    
    if (indexPath.section == 0 || indexPath.section == 1) {
        SKProduct *currentProduct = [[[OLCashier defaultCashier] products] productForIdentifier:thisIdentifier];
        
        cell.textLabel.text = currentProduct.localizedTitle;
        
        NSString *priceOrNot = [currentProduct.price stringValue];
        if ([OLCashier hasProduct:thisIdentifier]) priceOrNot = NSLocalizedString(@"PURCHASED", nil);
        cell.detailTextLabel.text = priceOrNot;
    } else {
        cell.textLabel.text = NSLocalizedString(@"STORE_RESTORE", nil);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *thisIdentifier;
    
    if (indexPath.section == 0)
        thisIdentifier = @"CF01";
    else if (indexPath.section == 1)
        thisIdentifier = @"CF02";
    
    if ([OLCashier hasProduct:thisIdentifier]) return;
    
    OLGhostAlertView *wait = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_WAIT_TITLE", nil) message:NSLocalizedString(@"STORE_WAIT_MESSAGE", nil) timeout:100.0 dismissible:NO];
    wait.position = OLGhostAlertViewPositionCenter;
    [wait show];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    if (indexPath.section == 0 || indexPath.section == 1) {
        [mixpanel track:@"Triggered Purchase in Store"];
        
        [[OLCashier defaultCashier] buyProduct:thisIdentifier handler:^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
            SKPaymentTransaction *transaction = transactions.firstObject;
            [wait hide];
            
            if (error) {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@. %@", error.localizedDescription, NSLocalizedString(@"STORE_ERROR_MESSAGE", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
                [errorAlert show];
                
                if (indexPath.section == 0) {
                    [mixpanel track:@"Failed to Purchase Map"];
                } else {
                    [mixpanel track:@"Failed to Purchase Ad Removal"];
                }
                return;
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:thisIdentifier];
            [transaction finish];
            
            OLGhostAlertView *thanks = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_THANK_YOU_TITLE", nil) message:NSLocalizedString(@"STORE_THANK_YOU_MESSAGE_MAP", nil)];
            if (indexPath.section == 1) thanks.message = NSLocalizedString(@"STORE_THANK_YOU_MESSAGE_ADS", nil);
            thanks.position = OLGhostAlertViewPositionCenter;
            [thanks show];
            
            if (indexPath.section == 0) {
                [mixpanel track:@"Purchased Map"];
                [mixpanel registerSuperProperties:@{@"Has Map": @"Yes"}];
            } else {
                [mixpanel track:@"Removed Ads"];
            }
        }];
    } else {
        [mixpanel track:@"Triggered Restore Purchases"];
        
        [[OLCashier defaultCashier] restoreCompletedTransactions:^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
            [wait hide];
            
            if (error) {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@. %@", error.localizedDescription, NSLocalizedString(@"STORE_ERROR_MESSAGE", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
                [errorAlert show];
                
                [mixpanel track:@"Failed to Restore Purchases"];
                
                return;
            }
            
            for (SKPaymentTransaction *transaction in transactions) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:transaction.payment.productIdentifier];
                [transaction finish];
            }
            
            [mixpanel track:@"Successfully Restored Purchases"];
        }];
    }
}

@end
