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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (NSArray *)favoritesArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *favsArray = [defaults arrayForKey:@"favorites"];
    
    return favsArray;
}

- (void)saveFavoritesWithArray:(NSArray *)array
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:array forKey:@"favorites"];
    [defaults synchronize];
}

- (void)longPressRecognized:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (!self.tableView.editing)
            [self.tableView setEditing:YES animated:YES];
        else
            [self.tableView setEditing:NO animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.favoritesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    CFFavoriteCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSInteger index = [self.favoritesArray count] - indexPath.row - 1;
    NSDictionary *stopDictionary = [self.favoritesArray objectAtIndex:index];
    
    if (cell == nil)
        cell = [[CFFavoriteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
//    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognized:)];
//    [cell addGestureRecognizer:longPressGesture];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.frame = CGRectMake(cell.contentView.frame.origin.x, cell.contentView.frame.origin.y, cell.contentView.bounds.size.width, CELL_HEIGHT);
    
    cell.codeLabel.text = [stopDictionary objectForKey:@"codigo"];
    cell.nameLabel.text = [stopDictionary objectForKey:@"nombre"];
    
    NSString *favoriteName = [stopDictionary objectForKey:@"favoriteName"];
    
    if ([favoriteName isEqualToString:@""]) {
        cell.favoriteNameLabel.text = NSLocalizedString(@"NAMELESS_FAVORITE", nil);
        cell.favoriteNameLabel.font = [UIFont italicSystemFontOfSize:19.0];
    } else {
        cell.favoriteNameLabel.text = favoriteName;
        cell.favoriteNameLabel.font = [UIFont systemFontOfSize:19.0];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *mutableFavoritesArray = [self.favoritesArray mutableCopy];
        
        NSInteger index = [mutableFavoritesArray count] - indexPath.row - 1;
        [mutableFavoritesArray removeObjectAtIndex:index];
        [self saveFavoritesWithArray:mutableFavoritesArray];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *mutableFavoritesArray = [self.favoritesArray mutableCopy];
    
    NSInteger oldIndex = [mutableFavoritesArray count] - fromIndexPath.row - 1;
    NSInteger newIndex = [mutableFavoritesArray count] - toIndexPath.row - 1;
    
    NSDictionary *movedStop = [mutableFavoritesArray objectAtIndex:oldIndex];
    
    [mutableFavoritesArray removeObjectAtIndex:oldIndex];
    [mutableFavoritesArray insertObject:movedStop atIndex:newIndex];
}

@end
