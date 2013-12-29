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

- (void)saveHistoryWithArray:(NSArray *)array
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:array forKey:@"history"];
    [defaults synchronize];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = [self.historyArray count];
    if (rows > 10) rows = 10;
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    CFStopCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSInteger index = [self.historyArray count] - indexPath.row - 1;
    NSDictionary *stopDictionary = [self.historyArray objectAtIndex:index];
    
    if (cell == nil)
        cell = [[CFStopCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.frame = CGRectMake(cell.contentView.frame.origin.x, cell.contentView.frame.origin.y, cell.contentView.bounds.size.width, CELL_HEIGHT);
    
    cell.codeLabel.text = [stopDictionary objectForKey:@"codigo"];
    
    NSString *street = [stopDictionary objectForKey:@"calle"];
    NSString *intersection = [stopDictionary objectForKey:@"interseccion"];
    
    if (intersection) {
        NSRange firstLineRange = NSMakeRange(0, [street length]);
        
        UIFont *boldFont = [UIFont boldSystemFontOfSize:15.0];
        UIFont *regularFont = [UIFont systemFontOfSize:15.0];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName, nil];
        NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil];
        
        NSString *fullString = [NSString stringWithFormat:@"%@\n%@ %@", street, NSLocalizedString(@"AND_BUS_STOP", nil), intersection];
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:fullString attributes:attrs];
        [attributedText setAttributes:subAttrs range:firstLineRange];
        
        [cell.nameLabel setAttributedText:attributedText];
        
    } else {
        cell.nameLabel.text = street;
    }
    
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

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        NSMutableArray *mutableHistoryArray = [self.historyArray mutableCopy];
//        
//        NSInteger index = [mutableHistoryArray count] - indexPath.row - 1;
//        [mutableHistoryArray removeObjectAtIndex:index];
//        [self saveHistoryWithArray:mutableHistoryArray];
//        
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    }
//}


@end
