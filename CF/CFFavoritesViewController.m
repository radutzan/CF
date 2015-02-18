//
//  CFFavoritesViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFFavoriteManager.h"
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
        self.footerString = NSLocalizedString(@"FAVORITES_TABLE_FOOTER_LABEL", nil); 
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
    return [[CFFavoriteManager sharedManager] favoritesArray];
}

- (void)setFavoritesArray:(NSArray *)favoritesArray
{
    [[CFFavoriteManager sharedManager] saveFavoritesArray:favoritesArray];
}

- (void)longPressRecognized:(UILongPressGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
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
            
            // update data source
            self.favoritesArray = [mutableFavorites copy];
            
            [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
            sourceIndexPath = indexPath;
        }
        
        if (self.tableView.contentSize.height > self.tableView.bounds.size.height) {
            CGFloat locationYConsideringScroll = location.y - self.tableView.contentOffset.y;
            CGFloat scrollArea = 70.0;
            
            // auto-scroll down
            BOOL scrolledToBottom = (self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.size.height));
            
            if (!scrolledToBottom && (locationYConsideringScroll >= (self.tableView.bounds.size.height - scrollArea))) {
                CGFloat relativeLocation = locationYConsideringScroll - self.tableView.bounds.size.height + scrollArea;
                CGFloat scrollFactor = relativeLocation / 7;
                scrollFactor = MAX(2.0, scrollFactor);
                [UIView animateWithDuration:0.1 animations:^{
                    self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + scrollFactor);
                }];
            }
            
            // auto-scroll up
            BOOL scrolledToTop = (self.tableView.contentOffset.y <= 0);
            
            if (!scrolledToTop && (locationYConsideringScroll <= scrollArea)) {
                CGFloat relativeLocation = scrollArea - locationYConsideringScroll;
                CGFloat scrollFactor = relativeLocation / 7;
                scrollFactor = MAX(2.0, scrollFactor);
                self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y - scrollFactor);
            }
        }
        
    } else {
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
            
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
            
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
    
    UIView *selectedBackgroundView = [UIView new];
    selectedBackgroundView.backgroundColor = [UIColor whiteColor];
    selectedBackgroundView.layer.borderWidth = 0.5;
    selectedBackgroundView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.15].CGColor;
    cell.selectedBackgroundView = selectedBackgroundView;
    
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
