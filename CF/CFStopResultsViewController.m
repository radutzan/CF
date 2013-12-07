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
#import "CFStopNavigationBar.h"

@interface CFStopResultsViewController ()

@property (nonatomic, strong) CFStopNavigationBar *customNavBar;
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
        
        self.tableView.separatorInset = UIEdgeInsetsZero;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(performStopRequest) forControlEvents:UIControlEventValueChanged];
    
    UIView *earFuck = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44.0)];
//    earFuck.backgroundColor = [UIColor purpleColor];
    
    self.stopInfoView = [[CFStopSignView alloc] initWithFrame:CGRectMake(-25.0, 0.0, 280.0, 44.0)];
//    self.stopInfoView.backgroundColor = [UIColor greenColor];
    self.stopInfoView.stopCodeLabel.hidden = YES;
    [earFuck addSubview:self.stopInfoView];
    self.navigationItem.titleView = earFuck;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.title = @"Calmao…";
    
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.favoriteButton.frame = CGRectMake(0, 0, 42, 42);
    [self.favoriteButton setImage:[UIImage imageNamed:@"button-favorites"] forState:UIControlStateNormal];
    [self.favoriteButton setImage:[UIImage imageNamed:@"button-favorites-selected"] forState:UIControlStateSelected];
    [self.favoriteButton addTarget:self action:@selector(favButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
//    UIBarButtonItem *favoriteItem = [[UIBarButtonItem alloc] initWithCustomView:self.favoriteButton];
//    self.navigationItem.rightBarButtonItem = favoriteItem;
    
    if (self.refreshing) {
        [self.refreshControl beginRefreshing];
        [UIView animateWithDuration:0.2 animations:^{
            self.tableView.contentOffset = CGPointMake(0, -124.0);
        }];
    }
}

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
    
    if (stop.isFavorite) self.favoriteButton.selected = YES;
    
    [self.estimation removeAllObjects];
    [self.tableView reloadData];
    [self updateHistory];
    [self performStopRequest];
    self.refreshing = YES;
    [self.refreshControl beginRefreshing];
}

- (void)performStopRequest
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.estimation removeAllObjects];
    
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
                                                   
                                                   [self.tableView reloadData];
                                                   [self.refreshControl endRefreshing];
                                                   self.refreshing = NO;
                                                   
                                               } else if (error) {
                                                   NSLog(@"Consulta falló. Error: %@", error.description);
                                               }
                                           }];
}

- (void)favButtonTapped:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (self.stop.isFavorite) {
//        self.stop.favorite = NO;
        
//        self.headerView.favoriteContentView.hidden = YES;
//        self.headerView.contentView.hidden = NO;
    } else {
//        self.stop.favorite = YES;
        
//        self.headerView.favoriteContentView.hidden = NO;
//        self.headerView.contentView.hidden = YES;
    }
}

- (void)updateHistory
{
    NSLog(@"updating history: %@", self.stop.code);
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.estimation count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    cell.backgroundColor = [UIColor clearColor];
    
    cell.textLabel.text = [[self.estimation objectAtIndex:indexPath.row] objectForKey:@"recorrido"];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25.0];
    
    CGFloat distance = [[[self.estimation objectAtIndex:indexPath.row] objectForKey:@"distancia"] integerValue];
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

@end
