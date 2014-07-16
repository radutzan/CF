//
//  TodayViewController.m
//  YetAnotherAttempt
//
//  Created by Radu Dutzan on 7/14/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic, strong) UILabel *helloLabel;
@property (nonatomic, strong) NSArray *favorites;
@property (nonatomic, strong) NSArray *storedFavorites;

@end

@implementation TodayViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 50)];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.preferredContentSize = self.view.bounds.size;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.helloLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 25.0)];
    self.helloLabel.textColor = [UIColor lightTextColor];
    [self.view addSubview:self.helloLabel];
    
    UIButton *openCFButton = [UIButton buttonWithType:UIButtonTypeSystem];
    openCFButton.frame = CGRectMake(0, 25.0, self.view.bounds.size.width, 25.0);
    [openCFButton setTitle:@"open CF!" forState:UIControlStateNormal];
    [openCFButton addTarget:self action:@selector(openCF) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:openCFButton];
    
    self.storedFavorites = self.favorites;
    [self updateContent];
}

#pragma mark - Content updating

- (void)updateContent
{
    self.helloLabel.text = [NSString stringWithFormat:@"%d Favorites", self.favorites.count];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler
{
    [self updateContent];
    
    NCUpdateResult updateResult;
    
    if (![self.storedFavorites isEqualToArray:self.favorites]) {
        updateResult = NCUpdateResultNewData;
    } else if ([self.storedFavorites isEqualToArray:self.favorites]) {
        updateResult = NCUpdateResultNoData;
    } else {
        updateResult = NCUpdateResultFailed;
    }
    
    self.storedFavorites = self.favorites;
    
    completionHandler(updateResult);
}

#pragma mark - Helpers

- (void)openCF
{
    NSURL *cf = [NSURL URLWithString:@"cuantofalta://"];
    [self.extensionContext openURL:cf completionHandler:nil];
}

- (void)openStop:(NSString *)stopName
{
    NSString *URLString = [NSString stringWithFormat:@"cuantofalta://stop/%@", stopName];
    NSURL *cfStop = [NSURL URLWithString:URLString];
    [self.extensionContext openURL:cfStop completionHandler:nil];
}

- (NSArray *)favorites
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfbetagroup"];
    NSArray *favorites = [defaults objectForKey:@"favorites"];
    return favorites;
}

@end
