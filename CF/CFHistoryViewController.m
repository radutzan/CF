//
//  CFHistoryViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFHistoryViewController.h"

@interface CFHistoryViewController ()

@property (nonatomic, strong) NSArray *historyArray;
@property (nonatomic, strong) NSMutableArray *mutableHistoryArray;

@end

@implementation CFHistoryViewController

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

- (NSArray *)historyArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *histArray = [defaults arrayForKey:@"history"];
    
    return histArray;
}

- (NSMutableArray *)mutableHistoryArray
{
    NSMutableArray *mutableHistory = [self.historyArray mutableCopy];
    
    return mutableHistory;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = [self.mutableHistoryArray count];
    if (rows > 10) rows = 10;
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    CFStopCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[CFStopCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.frame = CGRectMake(cell.contentView.frame.origin.x, cell.contentView.frame.origin.y, cell.contentView.bounds.size.width, 52.0);
    
    cell.codeLabel.text = [[self.mutableHistoryArray objectAtIndex:indexPath.row] objectForKey:@"codigo"];
    
    NSString *street = [[self.mutableHistoryArray objectAtIndex:indexPath.row] objectForKey:@"calle"];
    NSString *intersection = [[self.mutableHistoryArray objectAtIndex:indexPath.row] objectForKey:@"interseccion"];
    
    cell.nameLabel.text = street;
    
    if (intersection)
        cell.nameLabel.text = [NSString stringWithFormat:@"%@\n%@ %@", street, @"and", intersection];
    
    NSInteger number = [[[self.mutableHistoryArray objectAtIndex:indexPath.row] objectForKey:@"numero"] integerValue];
    
    if (number > 0) {
        cell.numberLabel.hidden = NO;
        cell.numberLabel.text = [NSString stringWithFormat:@"%d", number];
    }
    
    BOOL isMetro = [[[self.mutableHistoryArray objectAtIndex:indexPath.row] objectForKey:@"metro"] boolValue];
    
    if (isMetro)
        cell.metroBadge.hidden = NO;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


@end
