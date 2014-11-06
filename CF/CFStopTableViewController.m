//
//  CFStopTableViewController.m
//  CF
//
//  Created by Radu Dutzan on 11/19/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFStopTableViewController.h"

@interface CFStopTableViewController ()

@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong) UILabel *placeholderTitleLabel;
@property (nonatomic, strong) UILabel *placeholderMessageLabel;
@property (nonatomic, assign) BOOL placeholderViewWasLaidOut;
@property (nonatomic, strong) UILabel *footerLabel;

@end

@implementation CFStopTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _placeholderView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:_placeholderView];
        
        _placeholderImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-favorites"]];
        _placeholderImageView.tintColor = [UIColor colorWithWhite:0 alpha:.2];
        [_placeholderView addSubview:_placeholderImageView];
        
        _placeholderTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeholderTitleLabel.textAlignment = NSTextAlignmentCenter;
        _placeholderTitleLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_BOLD size:17.0];
        _placeholderTitleLabel.textColor = [UIColor colorWithWhite:0 alpha:0.4];
        [_placeholderView addSubview:_placeholderTitleLabel];
        
        _placeholderMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeholderMessageLabel.numberOfLines = 3;
        _placeholderMessageLabel.textAlignment = NSTextAlignmentCenter;
        _placeholderMessageLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:15.0];
        _placeholderMessageLabel.textColor = [UIColor colorWithWhite:0 alpha:0.4];
        [_placeholderView addSubview:_placeholderMessageLabel];
        
        _placeholderViewWasLaidOut = NO;
        
        _footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 100.0, self.tableView.bounds.size.width - 30.0, 0)];
        _footerLabel.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:14.0];
        _footerLabel.textColor = [UIColor colorWithWhite:0 alpha:.5];
        _footerLabel.textAlignment = NSTextAlignmentCenter;
        _footerLabel.numberOfLines = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:0 alpha:0.15];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    CGFloat footerLabelHeight = (self.footerString) ? [self calculateHeightForString:self.footerString] : 0;
    self.footerLabel.frame = CGRectMake(15.0, self.footerLabel.frame.origin.y, self.view.bounds.size.width - 30.0, footerLabelHeight);
    
    if (!self.placeholderViewWasLaidOut) {
        self.placeholderView.frame = self.view.bounds;
        
        CGFloat verticalMargin = 12.0;
        CGFloat imageOriginY = floorf((self.view.bounds.size.height - 256.0) / 2);
        
        self.placeholderImageView.center = CGPointMake(self.placeholderView.bounds.size.width / 2, imageOriginY + self.placeholderImageView.image.size.height / 2);
        self.placeholderTitleLabel.frame = CGRectMake(0, self.placeholderImageView.frame.origin.y + self.placeholderImageView.bounds.size.height + verticalMargin, self.placeholderView.bounds.size.width, 25);
        self.placeholderMessageLabel.frame = CGRectMake(50, self.placeholderTitleLabel.frame.origin.y + self.placeholderTitleLabel.bounds.size.height + verticalMargin / 2, self.placeholderView.bounds.size.width - 100, 62);
        
        if (imageOriginY < 20) {
            self.placeholderImageView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            self.placeholderImageView.center = CGPointMake(self.placeholderImageView.center.x, self.placeholderImageView.center.y + 14.0);
        }
        
        self.placeholderViewWasLaidOut = YES;
    }
}

#pragma mark - Views

- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
    self.placeholderImageView.image = placeholderImage;
    [self.placeholderImageView sizeToFit];
}

- (void)setPlaceholderTitle:(NSString *)placeholderTitle
{
    _placeholderTitle = placeholderTitle;
    self.placeholderTitleLabel.text = placeholderTitle;
}

- (void)setPlaceholderMessage:(NSString *)placeholderMessage
{
    _placeholderMessage = placeholderMessage;
    self.placeholderMessageLabel.text = placeholderMessage;
}

- (void)setPlaceholderVisible:(BOOL)placeholderVisible
{
    _placeholderVisible = placeholderVisible;
    self.placeholderView.hidden = !placeholderVisible;
    self.footerLabel.hidden = placeholderVisible;
}

- (void)setFooterString:(NSString *)footerString
{
    _footerString = footerString;
    [self.tableView reloadData];
}

- (CGFloat)calculateHeightForString:(NSString *)string
{
    CGRect stringRect = [string boundingRectWithSize:CGSizeMake(self.footerLabel.bounds.size.width, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName: self.footerLabel.font}
                                             context:nil];
    return ceilf(stringRect.size.height);
}

#pragma mark - UITableViewDelegate

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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.scrollingDelegate drawerScrollViewDidScroll:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self.scrollingDelegate drawerScrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.footerString) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0)];
        
        self.footerLabel.text = self.footerString;
        self.footerLabel.frame = CGRectMake(15.0, 10.0, footerView.bounds.size.width - 30.0, [self calculateHeightForString:self.footerString]);
        if (!self.footerLabel.superview) [footerView addSubview:self.footerLabel];
        
        return footerView;
    } else return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.footerString) return [self calculateHeightForString:self.footerString] + 15.0; else return 0;
}

@end
