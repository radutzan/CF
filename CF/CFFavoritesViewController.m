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
    
//    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognized:)];
//    [cell addGestureRecognizer:longPressGesture];
    
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
