//
//  CFHistoryViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFHistoryViewController.h"
#import "CFFavoriteCell.h"

@interface CFHistoryViewController ()

@property (nonatomic, strong) NSArray *historyArray;

@end

@implementation CFHistoryViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.placeholderImage = [[UIImage imageNamed:@"placeholder-history"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.placeholderTitle = NSLocalizedString(@"HISTORY_PLACEHOLDER_TITLE", nil);
        self.placeholderMessage = NSLocalizedString(@"HISTORY_PLACEHOLDER_MESSAGE", nil);
        self.footerString = NSLocalizedString(@"HISTORY_TABLE_FOOTER_LABEL", nil);
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
    self.placeholderVisible = (self.historyArray.count == 0) ? YES : NO;
    NSInteger rows = self.historyArray.count;
    if (rows > 10) rows = 10;
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = [self.historyArray count] - indexPath.row - 1;
    NSDictionary *stopDictionary = [self.historyArray objectAtIndex:index];
    
    BOOL isFavorite = [[stopDictionary objectForKey:@"favorite"] boolValue];
    
    CFStopCell *cell;
    
    if (isFavorite) {
        static NSString *CellIdentifier = @"Favorite Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) cell = [[CFFavoriteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        CFFavoriteCell *favoriteCell = (CFFavoriteCell *)cell;
        
        favoriteCell.favoriteBadge.hidden = NO;
        favoriteCell.nameLabel.text = [stopDictionary objectForKey:@"nombre"];
        
        NSString *favoriteName = [stopDictionary objectForKey:@"favoriteName"];
        
        if ([favoriteName isEqualToString:@""]) {
            favoriteCell.favoriteNameLabel.text = NSLocalizedString(@"NAMELESS_FAVORITE", nil);
            favoriteCell.favoriteNameLabel.font = [UIFont italicSystemFontOfSize:17];//fontWithName:@"AvenirNext-MediumItalic" size:18.0];
        } else {
            favoriteCell.favoriteNameLabel.text = favoriteName;
            favoriteCell.favoriteNameLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];//[UIFont fontWithName:@"AvenirNext-Medium" size:18.0];
        }
    } else {
        static NSString *CellIdentifier = @"History Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) cell = [[CFStopCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        NSString *street = [stopDictionary objectForKey:@"calle"];
        NSString *intersection = [stopDictionary objectForKey:@"interseccion"];
        
        if (intersection) {
            NSRange firstLineRange = NSMakeRange(0, [street length]);
            
            UIFont *boldFont = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];//fontWithName:DEFAULT_FONT_NAME_BOLD size:LABEL_FONT_SIZE];
            UIFont *regularFont = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];//fontWithName:DEFAULT_FONT_NAME_MEDIUM size:LABEL_FONT_SIZE];
            
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
            cell.numberLabel.text = [NSString stringWithFormat:@"%ld", (long)number];
        }
        
        BOOL isMetro = [[stopDictionary objectForKey:@"metro"] boolValue];
        if (isMetro) cell.metroBadge.hidden = NO;
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    cell.codeLabel.text = [stopDictionary objectForKey:@"codigo"];
    
    UIView *selectedBackgroundView = [UIView new];
    selectedBackgroundView.backgroundColor = [UIColor whiteColor];
    selectedBackgroundView.layer.borderWidth = 0.5;
    selectedBackgroundView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.15].CGColor;
    cell.selectedBackgroundView = selectedBackgroundView;
    
    return cell;
}

@end
