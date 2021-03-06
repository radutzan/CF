//
//  CFMoreViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFMoreViewController.h"
#import "CFMoreContentViewController.h"
#import "CFWhatsNewViewController.h"
#import "CFStoreViewController.h"
#import "UIDevice+hardware.h"
#import <OLGhostAlertView/OLGhostAlertView.h>

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
    if (self.isPro) return 1;//2;
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 2;//3;
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
    cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];//fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];//fontWithName:DEFAULT_FONT_NAME_REGULAR size:12.0];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0 alpha:.5];
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
    } else if (indexPath.row == 0 && indexPath.section == lastSectionIndex) {
        cell.textLabel.text = NSLocalizedString(@"SHARE_THIS_APP", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"SHARE_SECOND_LINE", nil);
        cell.imageView.image = [[UIImage imageNamed:@"share"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (indexPath.row == 1 && indexPath.section == lastSectionIndex) {
        cell.textLabel.text = @"@cuantofaltapp";
        cell.detailTextLabel.text = NSLocalizedString(@"FOLLOW_US_TWITTER", nil);
        cell.imageView.image = [[UIImage imageNamed:@"twitter"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (indexPath.row == 2 && indexPath.section == lastSectionIndex) {
        cell.textLabel.text = @"Cuánto Falta";
        cell.detailTextLabel.text = NSLocalizedString(@"LIKE_US_FACEBOOK", nil);
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
        
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        NSString *aboutPath = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
        NSString *aboutString = [NSString stringWithContentsOfFile:aboutPath encoding:NSStringEncodingConversionAllowLossy error:nil];
        NSString *finalString = [NSString stringWithFormat:aboutString, [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        
        [webView loadHTMLString:finalString baseURL:baseURL];
        
        controller.title = NSLocalizedString(@"ABOUT", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
//    } else if (indexPath.section == 0 && indexPath.row == 2) {
//        CFWhatsNewViewController *whatsNew = [CFWhatsNewViewController new];
//        [self presentViewController:whatsNew animated:YES completion:nil];
        
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *contactURL = [@"http://api.cuantofalta.mobi" stringByAppendingFormat:@"/contact?local=%@&UDID=NULL&osver=%@&appver=%@&device=%@", [[NSLocale preferredLanguages] objectAtIndex:0], [[UIDevice currentDevice] systemVersion], appVersion, [UIDevice platform]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:contactURL]];
        [webView loadRequest:request];
        
        controller.title = NSLocalizedString(@"SEND_FEEDBACK", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
    } else if (!self.isPro && indexPath.section == 1 && indexPath.row == 0) {
        [self purchasePro];
        
    } else if (indexPath.section == lastSectionIndex && indexPath.row == 0) {
        NSArray *activityItems = [NSArray arrayWithObjects:NSLocalizedString(@"SHARE_TWEET_TEXT", nil), [NSURL URLWithString:@"https://itunes.apple.com/cl/app/id431174703"], nil];
        NSArray *excludeActivities = @[UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityController.excludedActivityTypes = excludeActivities;
        
        [self presentViewController:activityController animated:YES completion:NULL];
        
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
        
    } else if (indexPath.section == lastSectionIndex && indexPath.row == 2) {
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb://profile/173134206109710"]];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://facebook.com/cuantofaltapp"]];
        }
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
        nameLabel.font = [UIFont systemFontOfSize:24];//fontWithName:DEFAULT_FONT_NAME_REGULAR size:24.0];
        nameLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        nameLabel.textColor = theColor;
        [headerView addSubview:nameLabel];
        [nameLabel sizeToFit];
        nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y, nameLabel.bounds.size.width, 42.0);
        
        if (self.isPro) {
//            UIImageView *proBadge = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"badge-pro"]];
//            proBadge.frame = CGRectOffset(proBadge.frame, nameLabel.frame.origin.x + nameLabel.bounds.size.width + 7.0, 41.0);
//            proBadge.alpha = 0.3;
//            [headerView addSubview:proBadge];
        }
        
        UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x + 2.0, topMargin + 35.0, nameLabel.bounds.size.width, 20.0)];
        versionLabel.font = [UIFont systemFontOfSize:12];//fontWithName:DEFAULT_FONT_NAME_REGULAR size:12.0];
        versionLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"VERSION", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        versionLabel.textColor = theColor;
        [headerView addSubview:versionLabel];
        
        return headerView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sharingSectionIndex = (self.isPro) ? 1 : 2;
    if (!self.isPro && indexPath.section == 1) return 64;
    if (indexPath.section == sharingSectionIndex) return 54;
    return 48;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (!self.isPro && section == 1) return 44;
    return 0;
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
    OLGhostAlertView *wait = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_WAIT_TITLE", nil) message:NSLocalizedString(@"STORE_WAIT_MESSAGE", nil) timeout:100.0 dismissible:NO];
    wait.position = OLGhostAlertViewPositionCenter;
    [wait show];
}

- (void)restorePurchases
{
    OLGhostAlertView *wait = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_WAIT_TITLE", nil) message:NSLocalizedString(@"STORE_WAIT_MESSAGE", nil) timeout:100.0 dismissible:NO];
    wait.position = OLGhostAlertViewPositionCenter;
    [wait show];
    
}

- (BOOL)isPro
{
    return ([[NSUserDefaults standardUserDefaults] boolForKey:@"CF01"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"CF02"]);
}

@end
