//
//  CFStopResultsViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/17/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFStopResultsViewController.h"
#import "CFSapoClient.h"
#import "CFStopSignView.h"
#import "CFNavigationController.h"

@interface CFStopResultsViewController () <CFStopSignViewDelegate>

@property (nonatomic, strong) CFStopSignView *stopInfoView;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) NSMutableArray *estimation;
@property (assign) BOOL refreshing;

@end

@implementation CFStopResultsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _estimation = [NSMutableArray new];
        _refreshing = YES;
        
        self.title = @"Stop Results";
        
        self.tableView.separatorInset = UIEdgeInsetsZero;
        self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.3];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(performStopRequest) forControlEvents:UIControlEventValueChanged];
    
    UIView *earFuck = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 44.0)];
    
    self.stopInfoView = [[CFStopSignView alloc] initWithFrame:CGRectMake(-25.0, -11.0, 280.0, 52.0)];
    self.stopInfoView.delegate = self;
    self.stopInfoView.stopCodeLabel.hidden = YES;
    self.stopInfoView.favoriteContentView.userInteractionEnabled = YES;
    [earFuck addSubview:self.stopInfoView];
    self.navigationItem.titleView = earFuck;
    
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.favoriteButton.frame = CGRectMake(earFuck.bounds.size.width - 38.0, -5.0, 42.0, 42.0);
    self.favoriteButton.enabled = NO;
    [self.favoriteButton setImage:[UIImage imageNamed:@"button-favorites"] forState:UIControlStateNormal];
    [self.favoriteButton setImage:[UIImage imageNamed:@"button-favorites-selected"] forState:UIControlStateSelected];
    [self.favoriteButton addTarget:self action:@selector(favButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [earFuck addSubview:self.favoriteButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    if (self.refreshing) {
        [self.refreshControl beginRefreshing];
        [UIView animateWithDuration:0.2 animations:^{
            self.tableView.contentOffset = CGPointMake(0, -134.0);
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma mark - Favorites and history

- (void)favButtonTapped:(UIButton *)sender
{
    CGFloat animationDuration = 0.25;
    
    sender.selected = !sender.selected;
    
    if (self.stop.isFavorite) {
        self.stop.favorite = NO;
        
        [self.view endEditing:YES];
        
        [UIView animateWithDuration:(animationDuration / 2) animations:^{
            self.stopInfoView.favoriteContentView.alpha = 0;
        } completion:^(BOOL finished) {
            self.stopInfoView.favoriteContentView.hidden = YES;
            self.stopInfoView.contentView.hidden = NO;
            
            [UIView animateWithDuration:animationDuration animations:^{
                self.stopInfoView.contentView.alpha = 1;
            } completion:nil];
        }];
    } else {
        self.stop.favorite = YES;
        
        [self.stopInfoView.favoriteNameField becomeFirstResponder];
        
        [UIView animateWithDuration:(animationDuration / 2) animations:^{
            self.stopInfoView.contentView.alpha = 0;
        } completion:^(BOOL finished) {
            self.stopInfoView.contentView.hidden = YES;
            self.stopInfoView.favoriteContentView.hidden = NO;
            
            [UIView animateWithDuration:animationDuration animations:^{
                self.stopInfoView.favoriteContentView.alpha = 1;
            } completion:nil];
        }];
    }
    
    BOOL didKillImageView = NO;
    for (UIView *view in sender.subviews) {
        if ([view isKindOfClass:[UIImageView class]] && !didKillImageView) {
            view.hidden = YES;
            didKillImageView = YES;
        }
    }
}

- (void)stopSignView:(UIView *)signView didEditFavoriteNameWithString:(NSString *)string
{
    [self.stop setFavoriteName:string];
}

- (void)updateHistory
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *history = [defaults arrayForKey:@"history"];
    
    if (!history) {
        history = [NSArray new];
    }
    
    NSMutableArray *mutableHistory = [history mutableCopy];
    
    for (NSDictionary *stop in history) {
        if ([[stop objectForKey:@"codigo"] isEqualToString:self.stop.code])
            [mutableHistory removeObject:stop];
    }
    
    [mutableHistory addObject:[self.stop asDictionary]];
    
    [defaults setObject:mutableHistory forKey:@"history"];
    [defaults synchronize];
}

#pragma mark - Stop logic

- (void)setStopCode:(NSString *)stopCode
{
    _stopCode = stopCode;
    
    [[CFSapoClient sharedClient] fetchBusStop:stopCode
                                      handler:^(NSError *error, id result) {
                                          if (result) {
                                              for (NSDictionary *stopData in result) {
                                                  CLLocationCoordinate2D coordinate;
                                                  coordinate.latitude = [[stopData objectForKey:@"latitude"] doubleValue];
                                                  coordinate.longitude = [[stopData objectForKey:@"longitude"] doubleValue];
                                                  
                                                  CFStop *stop = [CFStop stopWithCoordinate:coordinate code:[stopData objectForKey:@"codigo"] name:[stopData objectForKey:@"nombre"] services:[stopData objectForKey:@"recorridos"]];
                                                  self.stop = stop;
                                              }
                                          } else {
                                              [self.refreshControl endRefreshing];
                                              NSLog(@"Couldn't fetch stop. %@", error);
                                          }
                                      }];
}

- (void)setStop:(CFStop *)stop
{
    _stop = stop;
    
    self.title = @"";
    
    self.stopInfoView.stop = stop;
    self.favoriteButton.enabled = YES;
    if (stop.isFavorite) self.favoriteButton.selected = YES;
    
    [self.estimation removeAllObjects];
    [self.tableView reloadData];
    [self updateHistory];
    [self performStopRequest];
    [self.refreshControl beginRefreshing];
}

- (void)performStopRequest
{
    self.refreshing = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.estimation removeAllObjects];
    [self.tableView reloadData];
    
    [[CFSapoClient sharedClient] estimateAtBusStop:self.stop.code
                                          services:nil
                                           handler:^(NSError *error, id result) {
                                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                               
                                               if (result) {
                                                   NSArray *buses = result[@"estimation"][0];
                                                   
                                                   for (NSArray *busData in buses) {
                                                       NSDictionary *dict = [NSDictionary dictionaryWithObjects:busData forKeys:[NSArray arrayWithObjects:@"recorrido", @"tiempo", @"distancia", nil]];
                                                       [self.estimation addObject:dict];
                                                   }
                                                   
                                                   self.refreshing = NO;
                                                   [self.tableView reloadData];
                                                   [self.refreshControl endRefreshing];
                                                   
                                               } else if (error) {
                                                   NSLog(@"Consulta falló. Error: %@", error.description);
                                               }
                                           }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.stop.services count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    cell.backgroundColor = [UIColor clearColor];
    
    cell.textLabel.text = [[self.stop.services objectAtIndex:indexPath.row] objectForKey:@"name"];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25.0];
    
    if (!self.refreshing) cell.detailTextLabel.text = NSLocalizedString(@"NO_INFO", nil);
    
    if ([self.estimation count] == 0 || indexPath.row >= [self.estimation count]) return cell;
    
    for (NSDictionary *estimation in self.estimation) {
        if ([[estimation objectForKey:@"recorrido"] isEqualToString:cell.textLabel.text]) {
            CGFloat distance = [[estimation objectForKey:@"distancia"] integerValue];
            NSString *distanceString;
            NSString *unit = @"m";
            
            if (distance >= 1000) {
                unit = @"km";
                distance = distance / 1000;
                distanceString = [NSString stringWithFormat:@"%.2f", distance];
            } else {
                unit = @"m";
                distanceString = [NSString stringWithFormat:@"%.0f", distance];
            }
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", distanceString, unit];
            cell.detailTextLabel.textColor = [UIColor whiteColor];
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 52.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0;
}

- (float)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20.0)];
    
    UILabel *service = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 0, 100.0, 20.0)];
    service.text = NSLocalizedString(@"SERVICE", nil);
    service.font = [UIFont systemFontOfSize:13.0];
    [headerView addSubview:service];
    
    UILabel *estimate = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 0, 290.0, 20.0)];
    estimate.text = NSLocalizedString(@"ESTIMATION", nil);
    estimate.font = [UIFont systemFontOfSize:13.0];
    estimate.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:estimate];
    
    UILabel *distance = [[UILabel alloc] initWithFrame:CGRectMake(205.0, 0, 100.0, 20.0)];
    distance.text = NSLocalizedString(@"DISTANCE", nil);
    distance.font = [UIFont systemFontOfSize:13.0];
    distance.textAlignment = NSTextAlignmentRight;
    [headerView addSubview:distance];
    
    return headerView;
}

@end
