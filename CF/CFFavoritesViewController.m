//
//  CFFavoritesViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFFavoritesViewController.h"

@interface CFFavoritesViewController ()

@property (nonatomic, strong) NSArray *favoritesArray;
@property (nonatomic, strong) NSMutableArray *mutableFavoritesArray;

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

- (NSMutableArray *)mutableFavoritesArray
{
    NSMutableArray *mutableFavorites = [self.favoritesArray mutableCopy];
    
    return mutableFavorites;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.mutableFavoritesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    CFStopCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSInteger index = [self.mutableFavoritesArray count] - indexPath.row - 1;
    NSDictionary *stopDictionary = [self.mutableFavoritesArray objectAtIndex:index];
    
    if (cell == nil)
        cell = [[CFStopCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.frame = CGRectMake(cell.contentView.frame.origin.x, cell.contentView.frame.origin.y, cell.contentView.bounds.size.width, 52.0);
    
    cell.codeLabel.text = [stopDictionary objectForKey:@"codigo"];
    
    NSString *street = [stopDictionary objectForKey:@"calle"];
    NSString *intersection = [stopDictionary objectForKey:@"interseccion"];
    
    cell.nameLabel.text = street;
    
    if (intersection)
        cell.nameLabel.text = [NSString stringWithFormat:@"%@\n%@ %@", street, @"and", intersection];
    
    NSInteger number = [[stopDictionary objectForKey:@"numero"] integerValue];
    
    if (number > 0) {
        cell.numberLabel.hidden = NO;
        cell.numberLabel.text = [NSString stringWithFormat:@"%d", number];
    }
    
    BOOL isMetro = [[stopDictionary objectForKey:@"metro"] boolValue];
    
    if (isMetro)
        cell.metroBadge.hidden = NO;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

@end
