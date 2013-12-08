//
//  CFMoreViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFMoreViewController.h"
#import "CFMoreContentViewController.h"
#import "UIDevice+hardware.h"

@interface CFMoreViewController ()

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    
    if (indexPath.section == 0) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == 0 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"HELP", nil);
    } else if (indexPath.row == 1 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"ABOUT", nil);
    } else if (indexPath.row == 2 && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"SEND_FEEDBACK", nil);
    } else if (indexPath.row == 0 && indexPath.section == 1) {
        cell.textLabel.text = NSLocalizedString(@"SHARE_THIS_APP", nil);
    } else if (indexPath.row == 1 && indexPath.section == 1) {
        cell.textLabel.text = NSLocalizedString(@"FOLLOW_US_TWITTER", nil);
    } else if (indexPath.row == 2 && indexPath.section == 1) {
        cell.textLabel.text = NSLocalizedString(@"RATE_ON_APP_STORE", nil);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CFMoreContentViewController *controller = [CFMoreContentViewController new];
    
    NSURL *baseURL = [[NSBundle mainBundle] resourceURL];
    UIWebView *webView = nil;
    
    if (indexPath.section == 0) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, self.navigationController.view.frame.size.height)];
        webView.backgroundColor = [UIColor whiteColor];
        webView.opaque = NO;
        
        controller.view = webView;
    }
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        NSString *helpPath = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
        NSData *help = [NSData dataWithContentsOfFile:helpPath];
        
        [webView loadData:help MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
        controller.title = NSLocalizedString(@"HELP", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        NSString *aboutPath = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
        NSData *about = [NSData dataWithContentsOfFile:aboutPath];
        
        [webView loadData:about MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
        controller.title = NSLocalizedString(@"ABOUT", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *contactURL = [@"http://api.cuantofalta.mobi" stringByAppendingFormat:@"/contact?local=%@&UDID=NULL&osver=%@&appver=%@&device=%@", [[NSLocale preferredLanguages] objectAtIndex:0], [[UIDevice currentDevice] systemVersion], appVersion, [UIDevice platform]];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:contactURL]];
        [webView loadRequest:request];
        
        controller.title = NSLocalizedString(@"SEND_FEEDBACK", nil);
        [self.navigationController pushViewController:controller animated:YES];
        
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        NSArray *activityItems = [NSArray arrayWithObjects:NSLocalizedString(@"SHARE_TWEET_TEXT", nil), [NSURL URLWithString:@"https://itunes.apple.com/cl/app/id431174703"], nil];
        NSArray *excludeActivities = @[UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityController.excludedActivityTypes = excludeActivities;
        
        [self presentViewController:activityController animated:YES completion:NULL];
        
    } else if (indexPath.section == 1 && indexPath.row == 1) {
        NSURL *URL = nil;
        NSArray *schemes = [NSArray arrayWithObjects:@"tweetbot:///follow/@%@?callback_url=cuantofalta://success", @"twitter:@%@", @"http://twitter.com/%@", nil];
        
        for (NSString *uri in schemes) {
            URL = [NSURL URLWithString:[NSString stringWithFormat:uri, @"cuantofaltapp"]];
            if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                break;
            }
        }
        
        [[UIApplication sharedApplication] openURL:URL];
        
    } else if (indexPath.section == 1 && indexPath.row == 2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id431174703"]];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
