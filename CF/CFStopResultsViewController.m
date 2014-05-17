//
//  CFStopResultsViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/17/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <Mixpanel/Mixpanel.h>
#import <Social/Social.h>
#import <OLGhostAlertView/OLGhostAlertView.h>
#import "CFStopResultsViewController.h"
#import "CFSapoClient.h"
#import "CFStopSignView.h"
#import "CFResultCell.h"
#import "CFNavigationController.h"
#import "OLShapeTintedButton.h"
#import "GADBannerView.h"
#import "OLCashier.h"

@interface CFStopResultsViewController () <CFStopSignViewDelegate, UIAlertViewDelegate, CFResultCellDelegate>

@property (nonatomic, strong) CFStopSignView *stopInfoView;
@property (nonatomic, strong) OLShapeTintedButton *favoriteButton;
@property (nonatomic, strong) NSMutableArray *responseEstimation;
@property (nonatomic, strong) NSMutableArray *finalData;
@property (nonatomic, strong) GADBannerView *bannerView;
@property (nonatomic, assign) BOOL refreshing;
@property (nonatomic, assign) BOOL removedAds;
@property (nonatomic) CGFloat initialBannerCenterX;

@end

@implementation CFStopResultsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _responseEstimation = [NSMutableArray new];
        _finalData = [NSMutableArray new];
        _refreshing = YES;
        
        self.title = @"Stop Results";
        
        self.tableView.separatorInset = UIEdgeInsetsZero;
        
        self.removedAds = [OLCashier hasProduct:@"CF02"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor clearColor];
    
    self.refreshControl = [UIRefreshControl new];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(performStopRequest) forControlEvents:UIControlEventValueChanged];
    
    UIView *earFuck = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 44.0)];
    
    self.stopInfoView = [[CFStopSignView alloc] initWithFrame:CGRectMake(-25.0, -11.0, 280.0, 52.0)];
    self.stopInfoView.delegate = self;
    self.stopInfoView.stopCodeLabel.hidden = YES;
    self.stopInfoView.favoriteContentView.userInteractionEnabled = YES;
    [earFuck addSubview:self.stopInfoView];
    self.navigationItem.titleView = earFuck;
    
    self.favoriteButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
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
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
    
    [self.navigationController setNavigationBarHidden:NO];
}

#pragma mark - Favorites and history

- (void)favButtonTapped:(UIButton *)sender
{
    CGFloat animationDuration = 0.25;
    
    sender.selected = !sender.selected;
    
    if (self.stop.isFavorite) {
        self.stop.favorite = NO;
        
        [self.stopInfoView.favoriteContentView endEditing:YES];
        
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
                                              
                                              UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STOP_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@\n%@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
                                              errorAlert.tag = 6009;
                                              [errorAlert show];
                                              
                                              Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                              [mixpanel track:@"Failed Stop Data Request" properties:@{@"Code": stopCode, @"Error": error.debugDescription}];
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
    
    if (!self.removedAds) {
        self.bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
        self.bannerView.rootViewController = self;
        self.bannerView.adUnitID = @"ca-app-pub-6226087428684107/3340545274";
        
        GADRequest *adRequest = [GADRequest request];
        [adRequest setLocationWithLatitude:stop.coordinate.latitude longitude:stop.coordinate.longitude accuracy:0];
        [self.bannerView loadRequest:adRequest];
    }
    
    [self.responseEstimation removeAllObjects];
    [self updateHistory];
    [self.tableView reloadData];
    [self performStopRequest];
    [self.refreshControl beginRefreshing];
}

- (void)performStopRequest
{
    self.refreshing = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.responseEstimation removeAllObjects];
    [self.tableView reloadData];
    
    [[CFSapoClient sharedClient] estimateAtBusStop:self.stop.code
                                          services:nil
                                           handler:^(NSError *error, id result) {
                                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                               
                                               if (result) {
                                                   NSArray *buses = result[@"estimation"][0];
                                                   
                                                   for (NSArray *busData in buses) {
                                                       NSDictionary *dict = [NSDictionary dictionaryWithObjects:busData forKeys:[NSArray arrayWithObjects:@"recorrido", @"tiempo", @"distancia", nil]];
                                                       [self.responseEstimation addObject:dict];
                                                   }
                                                   
                                                   [self processEstimationData];
                                                   
                                               } else if (error) {
                                                   NSLog(@"Consulta falló. Error: %@", error.description);
                                                   
                                                   UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STOP_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@\n%@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
                                                   [errorAlert show];
                                                   
                                                   Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                   [mixpanel track:@"Failed Estimation Request" properties:@{@"Code": self.stop.code, @"Error": error.debugDescription}];
                                               }
                                           }];
}

- (void)processEstimationData
{
    [self.finalData removeAllObjects];
    
    NSMutableArray *estimationlessServices = [NSMutableArray new];
    
    for (NSDictionary *service in self.stop.services) {
        NSMutableDictionary *moddedService = [service mutableCopy];
        NSMutableArray *estimations = [NSMutableArray new];
        NSString *serviceName = [service objectForKey:@"name"];
        CGFloat rawNearestDistance = CGFLOAT_MAX;
        
        for (NSDictionary *estimation in self.responseEstimation) {
            if ([[estimation objectForKey:@"recorrido"] isEqualToString:serviceName]) {
                NSMutableDictionary *thisEstimation = [NSMutableDictionary new];
                
                // take care of distance formatting
                CGFloat distance = [[estimation objectForKey:@"distancia"] integerValue];
                
                if (distance < rawNearestDistance) {
                    rawNearestDistance = distance;
                }
                
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
                
                NSString *finalDistanceString = [NSString stringWithFormat:@"%@ %@", distanceString, unit];
                
                [thisEstimation setObject:finalDistanceString forKey:@"distance"];
                
                // and time formatting
                NSString *time = [estimation objectForKey:@"tiempo"];
                NSString *finalTimeString;
                
                if ([time hasPrefix:@"Entre"]) {
                    NSRange fromRange = NSMakeRange(6, 2);
                    NSRange toRange = NSMakeRange(11, 2);
                    NSInteger fromMin = [[time substringWithRange:fromRange] integerValue];
                    NSInteger toMin = [[time substringWithRange:toRange] integerValue];
                    finalTimeString =  [NSString stringWithFormat:@"%d %@ %d min", fromMin, NSLocalizedString(@"TO_MINS", nil), toMin];
                } else {
                    finalTimeString = time;
                }
                
                [thisEstimation setObject:finalTimeString forKey:@"eta"];
                
                [estimations addObject:thisEstimation];
            }
        }
        
        [moddedService setObject:[NSNumber numberWithFloat:rawNearestDistance] forKey:@"rawNearestDistance"];
        [moddedService setObject:estimations forKey:@"estimations"];
        
        if (![estimations lastObject]) {
            [estimationlessServices addObject:moddedService];
        } else {
            [self.finalData addObject:moddedService];
        }
    }
    
    NSSortDescriptor *distanceSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"rawNearestDistance" ascending:YES];
    [self.finalData sortUsingDescriptors:@[distanceSortDescriptor]];
    
    [self.finalData addObjectsFromArray:estimationlessServices];
    
    self.refreshing = NO;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 6009) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
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
    static NSString *CellIdentifier = @"Result Cell";
    CFResultCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.delegate = self;
    
    if (cell == nil)
        cell = [[CFResultCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    NSDictionary *serviceDictionary;
    
    if ([self.finalData lastObject])
        serviceDictionary = [self.finalData objectAtIndex:indexPath.row];
    else
        serviceDictionary = [self.stop.services objectAtIndex:indexPath.row];
    
    cell.backgroundColor = [UIColor blackColor];
    
    cell.serviceLabel.text = [serviceDictionary objectForKey:@"name"];
    cell.directionLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"TO_DIRECTION", nil), [[serviceDictionary objectForKey:@"destino"] capitalizedString]];
    cell.estimations = [serviceDictionary objectForKey:@"estimations"];
    
    NSString *operatorID = [cell.serviceLabel.text substringToIndex:1];
    
    UIColor *badgeColor = [UIColor whiteColor];
    
    if ([operatorID isEqualToString:@"1"]) // alsacia
        badgeColor = [UIColor colorWithRed:0.00 green:0.62 blue:0.91 alpha:1.0];
    else if ([operatorID isEqualToString:@"2"] || [operatorID isEqualToString:@"G"]) // subus
        badgeColor = [UIColor colorWithRed:39.0/255.0 green:58.0/255.0 blue:145.0/255.0 alpha:1];
    else if ([operatorID isEqualToString:@"3"] || [operatorID isEqualToString:@"E"] || [operatorID isEqualToString:@"H"] || [operatorID isEqualToString:@"I"]) // vule
        badgeColor = [UIColor colorWithRed:0 green:167.0/255.0 blue:126.0/255.0 alpha:1];
    else if ([operatorID isEqualToString:@"4"] || [operatorID isEqualToString:@"D"]) // express
        badgeColor = [UIColor colorWithRed:247.0/255.0 green:148.0/255.0 blue:29.0/255.0 alpha:1];
    else if ([operatorID isEqualToString:@"5"] || [operatorID isEqualToString:@"J"]) // metbus
        badgeColor = [UIColor colorWithRed:0.00 green:0.68 blue:0.72 alpha:1.0];
    else if ([operatorID isEqualToString:@"6"] || [operatorID isEqualToString:@"B"] || [operatorID isEqualToString:@"C"]) // veolia
        badgeColor = [UIColor colorWithRed:237.0/255.0 green:28.0/255.0 blue:36.0/255.0 alpha:1];
    else if ([operatorID isEqualToString:@"F"]) // stp
        badgeColor = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0 alpha:1];
    
    cell.badgeColor = badgeColor;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.removedAds)
        return 0;
    else
        return 50.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20.0)];
    
    UILabel *service = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 0, 90.0, 20.0)];
    service.text = NSLocalizedString(@"SERVICE", nil);
    service.font = [UIFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
    [headerView addSubview:service];
    
    UILabel *estimate = [[UILabel alloc] initWithFrame:CGRectMake(160.0, 0, 100.0, 20.0)];
    estimate.text = NSLocalizedString(@"ESTIMATION", nil);
    estimate.font = [UIFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
    [headerView addSubview:estimate];
    
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.removedAds) return nil;
    if (!self.stop) return nil;
    
    return self.bannerView;
}

- (void)sendComplaintTweetForService:(NSString *)service
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *complaintTweet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [complaintTweet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"NO_INFO_COMPLAINT_TWEET", nil), service, self.stop.code]];
        [self presentViewController:complaintTweet animated:YES completion:nil];
    }
}

#pragma mark - Store

- (BOOL)removedAds
{
    return ([OLCashier hasProduct:@"CF01"] || [OLCashier hasProduct:@"CF02"]);
}

- (void)removeAds
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Triggered Ad Removal"];
    
    NSString *noAdsIdentifier = @"CF02";
    
    OLGhostAlertView *wait = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_WAIT_TITLE", nil) message:NSLocalizedString(@"STORE_WAIT_MESSAGE", nil) timeout:100.0 dismissible:NO];
    wait.position = OLGhostAlertViewPositionCenter;
    [wait show];
    
    [[OLCashier defaultCashier] buyProduct:noAdsIdentifier handler:^(NSError *error, NSArray *transactions, NSDictionary *userInfo) {
        SKPaymentTransaction *transaction = transactions.firstObject;
        [wait hide];
        
        if (error) {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_ERROR_TITLE", nil) message:[NSString stringWithFormat:@"%@.\n%@", error.localizedDescription, NSLocalizedString(@"ERROR_MESSAGE_TRY_AGAIN", nil)] delegate:self cancelButtonTitle:NSLocalizedString(@"ERROR_DISMISS", nil) otherButtonTitles:nil];
            [errorAlert show];
            
            [mixpanel track:@"Failed to Purchase Ad Removal"];
            return;
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:noAdsIdentifier];
        [transaction finish];
        
        [UIView animateWithDuration:0.25 animations:^{
            self.bannerView.frame = CGRectMake(0, self.view.bounds.size.height, self.bannerView.bounds.size.width, self.bannerView.bounds.size.width);
            self.bannerView.alpha = 0;
        } completion:^(BOOL finished) {
            self.bannerView.hidden = YES;
            [self.tableView reloadData];
        }];
        
        OLGhostAlertView *thanks = [[OLGhostAlertView alloc] initWithTitle:NSLocalizedString(@"STORE_THANK_YOU_TITLE", nil) message:NSLocalizedString(@"STORE_THANK_YOU_MESSAGE_ADS", nil)];
        thanks.position = OLGhostAlertViewPositionCenter;
        [thanks show];
        
        [mixpanel track:@"Removed Ads"];
    }];
}

@end
