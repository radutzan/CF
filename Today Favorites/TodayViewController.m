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

@property (nonatomic, strong) NSArray *favorites;
@property (nonatomic, strong) NSArray *storedFavorites;

@end

@implementation TodayViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0, self.favorites.count * CELL_HEIGHT)];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.preferredContentSize = self.view.bounds.size;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.scrollEnabled = NO;
    self.tableView.rowHeight = CELL_HEIGHT;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorEffect = [UIVibrancyEffect notificationCenterVibrancyEffect];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.storedFavorites = self.favorites;
    [self updateContent];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, size.width, size.height);
        self.tableView.frame = self.view.bounds;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

#pragma mark - Content updating

- (void)updateContent
{
    [self.tableView reloadData];
    self.tableView.frame = CGRectMake(0, 0, self.tableView.contentSize.width, self.tableView.contentSize.height);
    
    self.preferredContentSize = self.tableView.contentSize;
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
    [self updateContent];
    
    return UIEdgeInsetsMake(0, 0, 40.0, 0);
}

#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    self.placeholderVisible = (self.favoritesArray.count == 0) ? YES : NO;
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
    
    cell.contentView.frame = CGRectMake(cell.contentView.frame.origin.x, cell.contentView.frame.origin.y, cell.contentView.bounds.size.width, CELL_HEIGHT);
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
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfbetagroup"];
    NSArray *favorites = [defaults objectForKey:@"favorites"];
    return favorites;
}

@end
