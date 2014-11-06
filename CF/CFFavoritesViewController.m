//
//  CFFavoritesViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFFavoritesViewController.h"
#import "CFFavoriteCell.h"

@interface CFFavoritesViewController ()

@property (nonatomic, strong) NSArray *favoritesArray;

@end

@implementation CFFavoritesViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.placeholderImage = [UIImage starImageWithSize:CGSizeMake(145.0, 145.0) filled:NO];
        self.placeholderTitle = NSLocalizedString(@"FAVORITES_PLACEHOLDER_TITLE", nil);
        self.placeholderMessage = NSLocalizedString(@"FAVORITES_PLACEHOLDER_MESSAGE", nil);
        self.footerString = @"Reordena un favorito presionando, manteniendo y arrastrándolo donde quieras."; 
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognized:)];
    [self.tableView addGestureRecognizer:longPressGesture];
}

- (NSArray *)favoritesArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *favsArray = [defaults arrayForKey:@"favorites"];
    [defaults synchronize];
    
#ifdef DEV_VERSION
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfbetagroup"];
    [sharedDefaults setObject:favsArray forKey:@"favorites"];
    [sharedDefaults synchronize];
#else
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfgroup"];
    [sharedDefaults setObject:favsArray forKey:@"favorites"];
    [sharedDefaults synchronize];
#endif
    
    return favsArray;
}

- (void)setFavoritesArray:(NSArray *)favoritesArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:favoritesArray forKey:@"favorites"];
    [defaults synchronize];
    
#ifdef DEV_VERSION
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfbetagroup"];
    [sharedDefaults setObject:favoritesArray forKey:@"favorites"];
    [sharedDefaults synchronize];
#else
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfgroup"];
    [sharedDefaults setObject:favoritesArray forKey:@"favorites"];
    [sharedDefaults synchronize];
#endif
}

- (void)saveFavoritesWithArray:(NSArray *)array
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:array forKey:@"favorites"];
    [defaults synchronize];
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ondalabs.cfbetagroup"];
    [sharedDefaults setObject:array forKey:@"favorites"];
    [sharedDefaults synchronize];
}

- (void)longPressRecognized:(UILongPressGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
    
    static UIView *snapshot = nil;
    static NSIndexPath *sourceIndexPath = nil;
    static NSMutableArray *mutableFavorites = nil;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (indexPath) {
            sourceIndexPath = indexPath;
            mutableFavorites = [self.favoritesArray mutableCopy];
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            snapshot = [cell snapshotViewAfterScreenUpdates:YES];
            snapshot.layer.masksToBounds = NO;
            snapshot.layer.shadowOffset = CGSizeMake(0, 2);
            snapshot.layer.shadowRadius = 0;
            snapshot.layer.shadowOpacity = 0;
            snapshot.layer.shadowPath = [UIBezierPath bezierPathWithRect:snapshot.bounds].CGPath;
            
            __block CGPoint center = cell.center;
            snapshot.center = center;
            [self.tableView addSubview:snapshot];
            
            cell.hidden = YES;
            
            [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
                snapshot.layer.shadowRadius = 5.0;
                snapshot.layer.shadowOpacity = 0.1;
                center.y = location.y;
                snapshot.center = center;
                snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
                snapshot.alpha = 0.98;
                
            } completion:^(BOOL finished) {
            }];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint center = snapshot.center;
        center.y = location.y;
        snapshot.center = center;
        
        // Is destination valid and is it different from source?
        if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
            // data source is inverted, so stupidity ensues
            NSInteger index = [self.favoritesArray count] - indexPath.row - 1;
            NSInteger sourceIndex = [self.favoritesArray count] - sourceIndexPath.row - 1;
            
            NSLog(@"exchange %ld (%@) for %ld (%@)", (long)indexPath.row, mutableFavorites[index][@"favoriteName"], (long)sourceIndexPath.row, mutableFavorites[sourceIndex][@"favoriteName"]);
            [mutableFavorites exchangeObjectAtIndex:index withObjectAtIndex:sourceIndex];
            NSLog(@"did it work? %ld (%@), %ld (%@)", (long)indexPath.row, mutableFavorites[index][@"favoriteName"], (long)sourceIndexPath.row, mutableFavorites[sourceIndex][@"favoriteName"]);
            
            [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
            sourceIndexPath = indexPath;
        }
        
        BOOL scrolledToBottom = (self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.size.height));
        
        if (!scrolledToBottom && (location.y >= (self.tableView.bounds.size.height - 50))) {
            self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + 1.0);
        }
        
        BOOL scrolledToTop = (self.tableView.contentOffset.y <= 0);
        
        if (!scrolledToTop && (location.y <= 50)) {
            self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + 1.0);
        }
    } else {
        // ... update data source.
        self.favoritesArray = [mutableFavorites copy];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
        
        [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:0 animations:^{
            snapshot.layer.shadowRadius = 0;
            snapshot.layer.shadowOpacity = 0;
            snapshot.center = cell.center;
            snapshot.transform = CGAffineTransformIdentity;
            snapshot.alpha = 1.0;
            
        } completion:^(BOOL finished) {
            [snapshot removeFromSuperview];
            cell.hidden = NO;
            
            sourceIndexPath = nil;
            mutableFavorites = nil;
            snapshot = nil;
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    self.placeholderVisible = (self.favoritesArray.count == 0) ? YES : NO;
    return self.favoritesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Favorite Cell";
    CFFavoriteCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSInteger index = [self.favoritesArray count] - indexPath.row - 1;
    NSDictionary *stopDictionary = [self.favoritesArray objectAtIndex:index];
    
    if (cell == nil)
        cell = [[CFFavoriteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    
    cell.codeLabel.text = [stopDictionary objectForKey:@"codigo"];
    cell.nameLabel.text = [stopDictionary objectForKey:@"nombre"];
    
    NSString *favoriteName = [stopDictionary objectForKey:@"favoriteName"];
    
    if ([favoriteName isEqualToString:@""]) {
        cell.favoriteNameLabel.text = NSLocalizedString(@"NAMELESS_FAVORITE", nil);
        cell.favoriteNameLabel.font = [UIFont fontWithName:@"AvenirNext-MediumItalic" size:18.0];
    } else {
        cell.favoriteNameLabel.text = favoriteName;
        cell.favoriteNameLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:18.0];
    }
    
    return cell;
}

@end
