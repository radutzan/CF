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

@interface CFMoreViewController () <UIWebViewDelegate>

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 3;
    if (section == 1) return 1;
    
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    cell.textLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
    
    if (indexPath.section != 2)
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (indexPath.row == 0 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"HELP", nil);
    } else if (indexPath.row == 1 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"ABOUT", nil);
//    } else if (indexPath.row == 2 && indexPath.section == 0) {
//        cell.textLabel.text = NSLocalizedString(@"WHATS_NEW", nil);
    } else if (indexPath.row == 2 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"SEND_FEEDBACK", nil);
    } else if (indexPath.row == 0 && indexPath.section == 1) {
        cell.textLabel.text = NSLocalizedString(@"STORE", nil);
    } else if (indexPath.row == 0 && indexPath.section == 2) {
        cell.textLabel.text = NSLocalizedString(@"SHARE_THIS_APP", nil);
    } else if (indexPath.row == 1 && indexPath.section == 2) {
        cell.textLabel.text = NSLocalizedString(@"FOLLOW_US_TWITTER", nil);
    } else if (indexPath.row == 2 && indexPath.section == 2) {
        cell.textLabel.text = NSLocalizedString(@"RATE_ON_APP_STORE", nil);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CFMoreContentViewController *controller = [CFMoreContentViewController new];
    
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
        
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        CFWhatsNewViewController *whatsNew = [CFWhatsNewViewController new];
        [self presentViewController:whatsNew animated:YES completion:nil];
        
        [mixpanel track:@"Opened What's New"];
        
    } else if (indexPath.section == 0 && indexPath.row == 3) {
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *contactURL = [@"http://api.cuantofalta.mobi" stringByAppendingFormat:@"/contact?local=%@&UDID=NULL&osver=%@&appver=%@&device=%@", [[NSLocale preferredLanguages] objectAtIndex:0], [[UIDevice currentDevice] systemVersion], appVersion, [UIDevice platform]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:contactURL]];
        [webView loadRequest:request];
        
        controller.title = NSLocalizedString(@"SEND_FEEDBACK", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
        [mixpanel track:@"Opened Send Feedback"];
        
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        CFStoreViewController *storeController = [[CFStoreViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController pushViewController:storeController animated:YES];
        
        [mixpanel track:@"Opened Store"];
        
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        NSArray *activityItems = [NSArray arrayWithObjects:NSLocalizedString(@"SHARE_TWEET_TEXT", nil), [NSURL URLWithString:@"https://itunes.apple.com/cl/app/id431174703"], nil];
        NSArray *excludeActivities = @[UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityController.excludedActivityTypes = excludeActivities;
        
        [self presentViewController:activityController animated:YES completion:NULL];
        
        [mixpanel track:@"Opened Share CF"];
        
    } else if (indexPath.section == 2 && indexPath.row == 1) {
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
        
    } else if (indexPath.section == 2 && indexPath.row == 2) {
        
        [mixpanel track:@"Opened Rate on the App Store"];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id431174703"]];
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
        
        UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x + 2.0, topMargin + 35.0, nameLabel.bounds.size.width, 20.0)];
        versionLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:12.0];
        versionLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"VERSION", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        versionLabel.textColor = theColor;
        [headerView addSubview:versionLabel];
        
        return headerView;
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

@end
