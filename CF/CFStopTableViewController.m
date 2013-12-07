//
//  CFStopTableViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/19/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFStopTableViewController.h"

@interface CFStopTableViewController ()

@end

@implementation CFStopTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CFStopCell *selectedCell = (CFStopCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    NSString *stopCode = selectedCell.codeLabel.text;
    [self.delegate stopTableView:self.tableView didSelectCellWithStop:stopCode];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
