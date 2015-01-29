//
//  CFMoreViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Mixpanel/Mixpanel.h>
#import "CFMoreViewController.h"
#import "CFMoreContentViewController.h"
#import "CFWhatsNewViewController.h"
#import "CFStoreViewController.h"
#import "UIDevice+hardware.h"
#import <OLGhostAlertView/OLGhostAlertView.h>
#import "OLCashier.h"

@interface CFMoreViewController () <UIWebViewDelegate>

@property (nonatomic) BOOL isPro;

@end

@implementation CFMoreViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:0 alpha:0.15];
    
    [[OLCashier defaultCashier] addObserver:self forKeyPath:NSStringFromSelector(@selector(products)) options:0 context:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.scrollingDelegate drawerScrollViewDidScroll:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self.scrollingDelegate drawerScrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections - 1)] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.isPro) return 2;
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 3;
    if (!self.isPro && section == 1) return 1;
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    cell.textLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.imageView.image = nil;
    
    NSInteger lastSectionIndex = (self.isPro) ? 1 : 2;
    
    if (indexPath.section == 0) cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (indexPath.row == 0 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"HELP", nil);
    } else if (indexPath.row == 1 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"ABOUT", nil);
//    } else if (indexPath.row == 2 && indexPath.section == 0) {
//        cell.textLabel.text = NSLocalizedString(@"WHATS_NEW", nil);
    } else if (indexPath.row == 2 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"SEND_FEEDBACK", nil);
    } else if (!self.isPro && indexPath.row == 0 && indexPath.section == 1) {
        cell.textLabel.text = NSLocalizedString(@"REMOVE_ADS", nil);
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = NSLocalizedString(@"BUY_PRO", nil);
        cell.detailTextLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:12.0];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0 alpha:.5];
        
        SKProduct *currentProduct = [[[OLCashier defaultCashier] products] productForIdentifier:@"CF01"];
        NSLog(@"product: %@", currentProduct);
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:currentProduct.priceLocale];
        NSString *priceString = [numberFormatter stringFromNumber:currentProduct.price];
        if (!priceString) priceString = @"nil";
        NSLog(@"price: %@", priceString);
        
        UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 44.0)];
        priceLabel.text = priceString;
        priceLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:17.0];
        priceLabel.textColor = self.view.tintColor;
        priceLabel.textAlignment = NSTextAlignmentRight;
        cell.accessoryView = priceLabel;
        
    } else if (indexPath.row == 0 && indexPath.section == lastSectionIndex) {
        cell.textLabel.text = NSLocalizedString(@"SHARE_THIS_APP", nil);
        cell.imageView.image = [[UIImage imageNamed:@"share"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (indexPath.row == 1 && indexPath.section == lastSectionIndex) {
        cell.textLabel.text = @"@cuantofaltapp";
        cell.imageView.image = [[UIImage imageNamed:@"twitter"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (indexPath.row == 2 && indexPath.section == lastSectionIndex) {
        cell.textLabel.text = @"Cuánto Falta";
        cell.imageView.image = [[UIImage imageNamed:@"facebook"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    if (indexPath.section == lastSectionIndex) {
        cell.imageView.contentMode = UIViewContentModeCenter;
        cell.imageView.tintColor = [UIColor colorWithWhite:0 alpha:.32];
    }
    
    UIView *selectedBackgroundView = [UIView new];
    selectedBackgroundView.backgroundColor = [UIColor whiteColor];
    selectedBackgroundView.layer.borderWidth = 0.5;
    selectedBackgroundView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.15].CGColor;
    cell.selectedBackgroundView = selectedBackgroundView;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CFMoreContentViewController *controller = [CFMoreContentViewController new];
    
    NSInteger lastSectionIndex = (self.isPro) ? 1 : 2;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSURL *baseURL = [[NSBundle mainBundle] resourceURL];
    UIWebView *webView = nil;
    
    if (indexPath.section == 0) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, self.navigationController.view.frame.size.height)];
        webView.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
        webView.opaque = NO;
        webView.delegate = self;
        
        controller.view = webView;
    }
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        NSString *helpPath = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
        NSData *help = [NSData dataWithContentsOfFile:helpPath];
        
        if (!webView) NSLog(@"no webview lol");
        
        [webView loadData:help MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
        
        controller.title = NSLocalizedString(@"HELP", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
        [mixpanel track:@"Opened Help"];
        
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        NSString *aboutPath = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
        NSString *aboutString = [NSString stringWithContentsOfFile:aboutPath encoding:NSStringEncodingConversionAllowLossy error:nil];
        NSString *finalString = [NSString stringWithFormat:aboutString, [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        
        [webView loadHTMLString:finalString baseURL:baseURL];
        
        controller.title = NSLocalizedString(@"ABOUT", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
        [mixpanel track:@"Opened About"];
        
//    } else if (indexPath.section == 0 && indexPath.row == 2) {
//        CFWhatsNewViewController *whatsNew = [CFWhatsNewViewController new];
//        [self presentViewController:whatsNew animated:YES completion:nil];
//        
//        [mixpanel track:@"Opened What's New"];
        
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *contactURL = [@"http://api.cuantofalta.mobi" stringByAppendingFormat:@"/contact?local=%@&UDID=NULL&osver=%@&appver=%@&device=%@", [[NSLocale preferredLanguages] objectAtIndex:0], [[UIDevice currentDevice] systemVersion], appVersion, [UIDevice platform]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:contactURL]];
        [webView loadRequest:request];
        
        controller.title = NSLocalizedString(@"SEND_FEEDBACK", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
        [mixpanel track:@"Opened Send Feedback"];
        
    } else if (!self.isPro && indexPath.section == 1 && indexPath.row == 0) {
        [self purchasePro];
        
    } else if (indexPath.section == lastSectionIndex && indexPath.row == 0) {
        NSArray *activityItems = [NSArray arrayWithObjects:NSLocalizedString(@"SHARE_TWEET_TEXT", nil), [NSURL URLWithString:@"https://itunes.apple.com/cl/app/id431174703"], nil];
        NSArray *excludeActivities = @[UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityController.excludedActivityTypes = excludeActivities;
        
        [self presentViewController:activityController animated:YES completion:NULL];
        
        [mixpanel track:@"Opened Share CF"];
        
    } else if (indexPath.section == lastSectionIndex && indexPath.row == 1) {
        NSURL *URL = nil;
        NSArray *schemes = [NSArray arrayWithObjects:@"tweetbot:///user_profile/%@", @"twitter:@%@", @"http://twitter.com/%@", nil];
        
        for (NSString *uri in schemes) {
            URL = [NSURL URLWithString:[NSString stringWithFormat:uri, @"cuantofaltapp"]];
            if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                break;
            }
        }
        
        [[UIApplication sharedApplication] openURL:URL];
        
        [mixpanel track:@"Opened Follow Us link"];
        
    } else if (indexPath.section == lastSectionIndex && indexPath.row == 2) {
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb://profile/173134206109710"]];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://facebook.com/cuantofaltapp"]];
        }
//        [mixpanel track:@"Opened Rate on the App Store"];
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id431174703"]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) return 105.0;
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        CGFloat horizontalMargin = 15.0;
        CGFloat topMargin = 30.0;
        UIColor *theColor = [UIColor colorWithWhite:0 alpha:.3];
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 105.0)];
        headerView.tintColor = theColor;
        
        UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"icon-outline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        iconImageView.frame = CGRectOffset(iconImageView.frame, horizontalMargin, topMargin);
        [headerView addSubview:iconImageView];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalMargin + iconImageView.bounds.size.width + 10.0, topMargin, self.view.bounds.size.width - iconImageView.bounds.size.width - 10.0 - horizontalMargin, 42.0)];
        nameLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:24.0];
        nameLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        nameLabel.textColor = theColor;
        [headerView addSubview:nameLabel];
        [nameLabel sizeToFit];
        nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y, nameLabel.bounds.size.width, 42.0);
        
        if (self.isPro) {
            UIImageView *proBadge = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"badge-pro"]];
            proBadge.frame = CGRectOffset(proBadge.frame, nameLabel.frame.origin.x + nameLabel.bounds.size.width + 7.0, 41.0);
            proBadge.alpha = 0.3;
            [headerView addSubview:proBadge];
            
            UILabel *proLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x + nameLabel.bounds.size.width + 10.0, topMargin, 50.0, 42.0)];
            proLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0];
            proLabel.text = @"PRO";
            proLabel.textColor = theColor;
            proLabel.textAlignment = NSTextAlignmentCenter;
            proLabel.layer.borderColor = theColor.CGColor;
            proLabel.layer.borderWidth = 1.0;
            proLabel.layer.cornerRadius = 5.0;
            [proLabel sizeToFit];
            proLabel.frame = CGRectMake(proLabel.frame.origin.x, proLabel.frame.origin.y + 10.0, proLabel.bounds.size.width + 14.0, proLabel.bounds.size.height + 0.0);
        }
        
        UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x + 2.0, topMargin + 35.0, nameLabel.bounds.size.width, 20.0)];
        versionLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:12.0];
        versionLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"VERSION", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        versionLabel.textColor = theColor;
        [headerView addSubview:versionLabel];
        
        return headerView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isPro && indexPath.section == 1) return 64;
    return 48;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (!self.isPro && section == 1) return 44;
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (!self.isPro && section == 1) {
        UIView *restoreFooterView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, self.view.bounds.size.width - 20, 30)];
        
        UILabel *alreadyPurchasedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, restoreFooterView.bounds.size.width, 30)];
        alreadyPurchasedLabel.text = NSLocalizedString(@"ALREADY_PURCHASED_QUESTION", nil);
        alreadyPurchasedLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:14.0];
        alreadyPurchasedLabel.textColor = [UIColor colorWithWhite:0 alpha:.3];
        [alreadyPurchasedLabel sizeToFit];
        [restoreFooterView addSubview:alreadyPurchasedLabel];
        
        NSDictionary *buttonAttributes = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSFontAttributeName: [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:14.0]};

        UIButton *restorePurchasesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        restorePurchasesButton.frame = CGRectMake(alreadyPurchasedLabel.bounds.size.width + 4, 0, 400, 30);
        [restorePurchasesButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"STORE_RESTORE", nil) attributes:buttonAttributes] forState:UIControlStateNormal];
        [restorePurchasesButton setTitleColor:[UIColor colorWithWhite:0 alpha:.3] forState:UIControlStateNormal];
        [restorePurchasesButton addTarget:self action:@selector(restorePurchases) forControlEvents:UIControlEventTouchUpInside];
        restorePurchasesButton.alpha = .3;
        [restorePurchasesButton sizeToFit];
        [restoreFooterView addSubview:restorePurchasesButton];
        
        alreadyPurchasedLabel.frame = CGRectMake(14, 0, alreadyPurchasedLabel.bounds.size.width, restorePurchasesButton.bounds.size.height);
        restorePurchasesButton.frame = CGRectMake(alreadyPurchasedLabel.bounds.size.width + 18, 0, restorePurchasesButton.bounds.size.width, restorePurchasesButton.bounds.size.height);
        
        return restoreFooterView;
    }
    
    return nil;
}

#pragma mark - WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([[request.URL host] isEqualToString:@"twitter.com"]) {
            NSURL *URL = nil;
            NSArray *schemes = [NSArray arrayWithObjects:@"tweetbot:///user_profile/%@", @"twitter:@%@", @"http://twitter.com/%@", nil];
            
            for (NSString *uri in schemes) {
                URL = [NSURL URLWithString:[NSString stringWithFormat:uri, [request.URL lastPathComponent]]];
                if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                    break;
                }
            }
            
            [[UIApplication sharedApplication] openURL:URL];
            
            return NO;
        }
        
        if ([[UIApplication sharedApplication] canOpenURL:[request URL]]) {
            [[UIApplication sharedApplication] openURL:[request URL]];
        }
        return NO;
    }
    
    return YES;
}

#pragma mark - Commerce

- (void)purchasePro
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Triggered Pro Purchase"];
    
    NSString *proIdentifier = @"CF01";
    
    OLGhostAlertView *wait = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_WAIT_TITLE", nil) message:NSLocalizedString(@"STORE_WAIT_MESSAGE", nil) timeout:100.0 dismissible:NO];
    wait.position = OLGhostAlertViewPositionCenter;
    [wait show];
    
    [[OLCashier defaultCashier] buyProduct:proIdentifier handler:^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
        SKPaymentTransaction *transaction = transactions.firstObject;
        [wait hide];
        
        if (error) {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@. %@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
            [errorAlert show];
            
            [mixpanel track:@"Failed to Purchase Pro" properties:@{@"Error:": error.description}];
            return;
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:proIdentifier];
        [transaction finish];
        
        OLGhostAlertView *thanks = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_THANK_YOU_TITLE", nil) message:NSLocalizedString(@"STORE_THANK_YOU_MESSAGE_MAP", nil)];
        thanks.position = OLGhostAlertViewPositionCenter;
        [thanks show];
        
        [mixpanel track:@"Purchased Pro"];
        [mixpanel registerSuperProperties:@{@"Has Pro": @"Yes"}];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections - 1)] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)restorePurchases
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Triggered Restore Purchases"];
    
    OLGhostAlertView *wait = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_WAIT_TITLE", nil) message:NSLocalizedString(@"STORE_WAIT_MESSAGE", nil) timeout:100.0 dismissible:NO];
    wait.position = OLGhostAlertViewPositionCenter;
    [wait show];
    
    [[OLCashier defaultCashier] restoreCompletedTransactions:^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
        [wait hide];
        
        if (error) {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@. %@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
            [errorAlert show];
            
            [mixpanel track:@"Failed to Restore Purchases"];
            return;
        }
        
        for (SKPaymentTransaction *transaction in transactions) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:transaction.payment.productIdentifier];
            [transaction finish];
        }
        
        [mixpanel track:@"Successfully Restored Purchases"];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections - 1)] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (BOOL)isPro
{
    return ([[NSUserDefaults standardUserDefaults] boolForKey:@"CF01"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"CF02"]);
}

@end
