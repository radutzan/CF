//
//  TodayViewController.m
//  YetAnotherAttempt
//
//  Created by Radu Dutzan on 7/14/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "CFFavoriteCell.h"

@interface TodayViewController () <NCWidgetProviding, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) UIEdgeInsets marginInsets;

@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic, strong) UIButton *openCFButton;
@property (nonatomic, assign) BOOL placeholderVisible;

@property (nonatomic, strong) NSArray *favorites;
@property (nonatomic, strong) NSArray *storedFavorites;

@end

@implementation TodayViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0, self.favorites.count * CELL_HEIGHT)];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.preferredContentSize = self.view.bounds.size;
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.scrollEnabled = NO;
    self.tableView.rowHeight = CELL_HEIGHT;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorEffect = [UIVibrancyEffect notificationCenterVibrancyEffect];
    [self.view addSubview:self.tableView];
    
    self.placeholderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280.0, CELL_HEIGHT)];
    self.placeholderView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.placeholderView.hidden = YES;
    [self.view addSubview:self.placeholderView];
    
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect notificationCenterVibrancyEffect]];
    vibrancyView.frame = self.placeholderView.bounds;
    vibrancyView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    vibrancyView.translatesAutoresizingMaskIntoConstraints = YES;
    [self.placeholderView addSubview:vibrancyView];
    
    UILabel *noFavoritesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200.0, self.placeholderView.bounds.size.height)];
    noFavoritesLabel.text = NSLocalizedString(@"NO_FAVORITES", nil);
    noFavoritesLabel.font = [UIFont systemFontOfSize:15.0];
    noFavoritesLabel.numberOfLines = 0;
    noFavoritesLabel.textColor = [UIColor whiteColor];
    [vibrancyView.contentView addSubview:noFavoritesLabel];
    
    self.openCFButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.openCFButton.frame = CGRectMake(90.0, 0, 90.0, CELL_HEIGHT);
    self.openCFButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, 0);
    self.openCFButton.tintColor = [UIColor whiteColor];
    [self.openCFButton setTitle:NSLocalizedString(@"OPEN_CF", nil) forState:UIControlStateNormal];
    [self.openCFButton setImage:[UIImage imageNamed:@"icon-widget"] forState:UIControlStateNormal];
    [self.openCFButton addTarget:self action:@selector(openCF) forControlEvents:UIControlEventTouchUpInside];
    [self.placeholderView addSubview:self.openCFButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.storedFavorites = self.favorites;
    [self updateContent];
}

- (void)viewWillLayoutSubviews
{
    if (self.placeholderVisible) {
        self.placeholderView.frame = CGRectMake(self.marginInsets.left, 0, self.view.bounds.size.width - self.marginInsets.left, CELL_HEIGHT);
        self.openCFButton.frame = CGRectMake(self.placeholderView.bounds.size.width - self.openCFButton.bounds.size.width, 0, self.openCFButton.bounds.size.width, CELL_HEIGHT);
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, size.width, size.height);
//        self.tableView.frame = self.view.bounds;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

#pragma mark - Content updating

- (void)updateContent
{
    [self.tableView reloadData];
    
    self.preferredContentSize = (self.placeholderVisible) ? CGSizeMake(self.tableView.contentSize.width, CELL_HEIGHT) : self.tableView.contentSize;
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

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets
{
    self.marginInsets = defaultMarginInsets;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.placeholderView.frame = CGRectMake(defaultMarginInsets.left, 0, self.view.bounds.size.width - defaultMarginInsets.left, CELL_HEIGHT);
    [self updateContent];
    
    return UIEdgeInsetsMake(0, 0, 20.0, 0);
}

- (void)setPlaceholderVisible:(BOOL)placeholderVisible
{
    _placeholderVisible = placeholderVisible;
    
    self.placeholderView.hidden = !placeholderVisible;
    self.tableView.hidden = placeholderVisible;
}

#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    self.placeholderVisible = (self.favorites.count == 0) ? YES : NO;
    return self.favorites.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    CFFavoriteCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSInteger index = self.favorites.count - indexPath.row - 1;
    NSDictionary *stopDictionary = [self.favorites objectAtIndex:index];
    
    if (cell == nil)
        cell = [[CFFavoriteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.separatorInset = self.marginInsets;
    
    NSString *favoriteName = [stopDictionary objectForKey:@"favoriteName"];
    
    if ([favoriteName isEqualToString:@""]) {
        cell.favoriteNameLabel.text = NSLocalizedString(@"NAMELESS_FAVORITE", nil);
        cell.favoriteNameLabel.font = [UIFont italicSystemFontOfSize:19.0];
    } else {
        cell.favoriteNameLabel.text = favoriteName;
        cell.favoriteNameLabel.font = [UIFont systemFontOfSize:19.0];
    }
    
    cell.codeLabel.text = [stopDictionary objectForKey:@"codigo"];
    cell.nameLabel.text = [stopDictionary objectForKey:@"nombre"];
    
    cell.favoriteNameLabel.textColor = [UIColor whiteColor];
    cell.nameLabel.textColor = [UIColor lightTextColor];
    cell.nameLabel.alpha = 1;
    
    cell.contentInsets = UIEdgeInsetsMake(0, self.marginInsets.left, 0, self.marginInsets.right);
    
    //    cell.backgroundColor = [UIColor clearColor];
    
    UIVisualEffectView *cellBackgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect notificationCenterVibrancyEffect]];
    cellBackgroundView.frame = cell.contentView.bounds;
    
    UIView *fillView = [[UIView alloc] initWithFrame:cell.bounds];
    fillView.backgroundColor = [UIColor whiteColor];
    [cellBackgroundView.contentView addSubview:fillView];
    
    cell.selectedBackgroundView = cellBackgroundView;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CFStopCell *selectedCell = (CFStopCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    NSString *stopCode = selectedCell.codeLabel.text;
    [self openStop:stopCode];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    NSUserDefaults *defaults;
#ifdef DEV_VERSION
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfbetagroup"];
#else
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfgroup"];
#endif
    
    if ([defaults objectForKey:@"favorites"]) {
        return [defaults objectForKey:@"favorites"];
    } else {
        return @[];
    }
}

@end
