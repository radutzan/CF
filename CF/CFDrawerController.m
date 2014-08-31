//
//  CFDrawerController.m
//  CF
//
//  Created by Radu Dutzan on 8/18/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <Mixpanel/Mixpanel.h>

#import "CFDrawerController.h"
#import "CFFavoritesViewController.h"
#import "CFHistoryViewController.h"
#import "CFMoreViewController.h"
#import "OLShapeTintedButton.h"

@interface CFTransparentView : UIView

@end

@implementation CFTransparentView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    id hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil;
    else return hitView;
}

@end

@interface CFDrawerController () <UIScrollViewDelegate, CFStopTableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIView *drawer;
@property (nonatomic, strong) CALayer *borderLayer;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *closeDrawerButton;
@property (nonatomic, strong) UIView *gripper;

@property (nonatomic, strong) NSArray *tabs;
@property (nonatomic, strong) UIView *tabBar;
@property (nonatomic, strong) CFFavoritesViewController *favoritesController;
@property (nonatomic, strong) CFHistoryViewController *historyController;
@property (nonatomic, strong) CFMoreViewController *moreController;

@property (nonatomic, assign) CGFloat drawerCurrentDragCenterY;
@property (nonatomic, assign) CGFloat drawerOpenCenterY;

@end

@implementation CFDrawerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"";
    }
    return self;
}

- (void)loadView
{
    CGRect windowBounds = [UIApplication sharedApplication].keyWindow.rootViewController.view.bounds;
    CGSize windowSize = windowBounds.size;
    
    self.view = [[CFTransparentView alloc] initWithFrame:windowBounds];
    
    CGRect drawerFrame = CGRectMake(10.0, windowSize.height - TAB_BAR_HEIGHT, windowSize.width - 20.0, windowSize.height - DRAWER_ORIGIN_Y);
    
    if (NSClassFromString(@"UIVisualEffectView")) {
        self.drawer = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        self.drawer.frame = drawerFrame;
    } else {
        self.drawer = [[UINavigationBar alloc] initWithFrame:drawerFrame];
    }
    
    self.drawer.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.drawer.frame = drawerFrame;
    [self.view addSubview:self.drawer];
    
    self.borderLayer = [CALayer layer];
    self.borderLayer.frame = CGRectInset(self.drawer.bounds, -0.5, -0.5);
    self.borderLayer.borderWidth = 0.5;
    self.borderLayer.borderColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
    [self.drawer.layer addSublayer:self.borderLayer];
    
    self.drawerOpenCenterY = DRAWER_ORIGIN_Y + self.drawer.bounds.size.height;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.drawer.bounds.size.width, self.drawer.bounds.size.height - TAB_BAR_HEIGHT)];
    self.scrollView.delegate = self;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * 3, self.scrollView.bounds.size.height);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.alpha = 0;
    [self.drawer addSubview:self.scrollView];
    
    self.gripper = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gripper"]];
    self.gripper.userInteractionEnabled = YES;
    self.gripper.frame = CGRectMake(0, 0, self.drawer.bounds.size.width, 30);
    self.gripper.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.gripper.alpha = 0;
    self.gripper.contentMode = UIViewContentModeCenter;
    [self.drawer addSubview:self.gripper];
    
    UIPanGestureRecognizer *gripDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrawerDragGesture:)];
    [self.gripper addGestureRecognizer:gripDrag];
    
    self.tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, TAB_BAR_HEIGHT)];
    self.tabBar.tintColor = [UIColor colorWithWhite:0.42 alpha:1];
    [self.view addSubview:self.tabBar];
    
    UIPanGestureRecognizer *openDrawerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrawerDragGesture:)];
    [self.tabBar addGestureRecognizer:openDrawerDrag];
    
    self.closeDrawerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeDrawerButton.frame = self.view.bounds;
    self.closeDrawerButton.hidden = YES;
    [self.closeDrawerButton addTarget:self action:@selector(closeDrawerWithAnimation) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:self.closeDrawerButton atIndex:0];
    
    UIPanGestureRecognizer *closeDrawerButtonDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrawerDragGesture:)];
    [self.closeDrawerButton addGestureRecognizer:closeDrawerButtonDrag];
    
    [self initTabs];
}

- (void)reloadUserData
{
    [self.favoritesController.tableView reloadData];
    [self.historyController.tableView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    self.view.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)viewWillLayoutSubviews
{
    CGFloat drawerOriginY = (self.drawerOpen) ? DRAWER_ORIGIN_Y : self.view.bounds.size.height - TAB_BAR_HEIGHT;
    self.drawer.frame = CGRectMake(10.0, drawerOriginY, self.view.bounds.size.width - 20.0, self.view.bounds.size.height - DRAWER_ORIGIN_Y);
    self.borderLayer.frame = CGRectInset(self.drawer.bounds, -0.5, -0.5);
    self.drawerOpenCenterY = DRAWER_ORIGIN_Y + self.drawer.bounds.size.height;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * 3, self.scrollView.bounds.size.height);
    self.tabBar.frame = CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, TAB_BAR_HEIGHT);
    
    for (UIView *subview in self.scrollView.subviews) {
        if (![subview isKindOfClass:[UIImageView class]]) {
            subview.frame = CGRectMake(self.scrollView.bounds.size.width * [self.scrollView.subviews indexOfObject:subview], 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
        }
    }
    
    CGFloat tabButtonWidth = floorf(self.drawer.bounds.size.width / self.tabs.count);
    for (UIButton *subview in self.tabBar.subviews) {
        subview.frame = CGRectMake(10.0 + tabButtonWidth * [self.tabBar.subviews indexOfObject:subview], 0, tabButtonWidth, TAB_BAR_HEIGHT);
        if (subview.selected) {
            [self tabButtonPressed:subview];
        }
    }
}

#pragma mark - Tabs

- (void)initTabs
{
    self.favoritesController = [[CFFavoritesViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.favoritesController.delegate = self;
    
    self.historyController = [[CFHistoryViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.historyController.delegate = self;
    
    self.moreController = [[CFMoreViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    self.tabs = @[@{@"controller": self.favoritesController,
                    @"title": @"Favorites",
                    @"button": [UIImage imageNamed:@"button-favorites"],
                    @"button-selected": [UIImage imageNamed:@"button-favorites-selected"]},
                  @{@"controller": self.historyController,
                    @"title": @"History",
                    @"button": [UIImage imageNamed:@"button-history"],
                    @"button-selected": [UIImage imageNamed:@"button-history-selected"]},
                  @{@"controller": self.moreController,
                    @"title": @"More",
                    @"button": [UIImage imageNamed:@"button-more"],
                    @"button-selected": [UIImage imageNamed:@"button-more-selected"]}];
}

- (void)setTabs:(NSArray *)tabs
{
    _tabs = tabs;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * tabs.count, self.scrollView.bounds.size.height);
    
    CGFloat tabButtonWidth = floorf(300 / tabs.count);
    
    for (NSDictionary *tab in tabs) {
        UIViewController *thisTabController = tab[@"controller"];
        thisTabController.view.frame = CGRectMake(self.scrollView.bounds.size.width * [tabs indexOfObject:tab], 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
        thisTabController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addChildViewController:thisTabController];
        [self.scrollView addSubview:thisTabController.view];
        
        OLShapeTintedButton *thisTabButton = [OLShapeTintedButton buttonWithType:UIButtonTypeCustom];
        thisTabButton.frame = CGRectMake(10.0 + tabButtonWidth * [tabs indexOfObject:tab], 0, tabButtonWidth, TAB_BAR_HEIGHT);
        [thisTabButton setImage:tab[@"button"] forState:UIControlStateNormal];
        [thisTabButton setImage:tab[@"button-selected"] forState:UIControlStateSelected];
        [thisTabButton addTarget:self action:@selector(tabButtonPressed:) forControlEvents:UIControlEventTouchDown];
        [thisTabButton addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabBar addSubview:thisTabButton];
    }
    
    UILongPressGestureRecognizer *clearHistory = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognized:)];
    [[self.tabBar.subviews objectAtIndex:1] addGestureRecognizer:clearHistory];
}

- (void)tabButtonPressed:(UIButton *)button
{
    [self selectTabButton:button];
    
    NSUInteger index = [[self.tabBar subviews] indexOfObject:button];
    
    [self switchToTab:index];
}

- (void)tabButtonTapped:(UIButton *)button
{
    [self selectTabButton:button];
    self.drawerOpen = YES;
    
    NSUInteger index = [[self.tabBar subviews] indexOfObject:button];
    
    [self switchToTab:index];
}

- (void)selectTabButton:(UIButton *)button
{
    for (UIButton *b in self.tabBar.subviews) {
        b.selected = NO;
        b.tintColor = nil;
    }
    
    button.selected = YES;
    button.tintColor = [[UIApplication sharedApplication] keyWindow].tintColor;
}

- (void)switchToTab:(NSUInteger)tabIndex
{
    CGFloat newOffset = self.scrollView.frame.size.width * tabIndex;
    self.scrollView.contentOffset = CGPointMake(newOffset, 0.0);
    
    switch (tabIndex) {
        case 0:
            [self.favoritesController.tableView flashScrollIndicators];
            break;
            
        case 1:
            [self.historyController.tableView flashScrollIndicators];
            break;
            
        case 2:
            [self.moreController.tableView flashScrollIndicators];
            break;
            
        default:
            break;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    [self.view endEditing:YES];
    
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSUInteger page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (page <= self.tabs.count - 1) {
        UIButton *thisButton = (UIButton *)[[self.tabBar subviews] objectAtIndex:page];
        [self selectTabButton:thisButton];
    }
}

#pragma mark - Opening and closing

- (void)setDrawerOpen:(BOOL)drawerOpen
{
    _drawerOpen = drawerOpen;
    
    if (drawerOpen) {
        if (self.scrollView.alpha < 1) {
            [UIView animateWithDuration:0.33 delay:0.0 options:(7 >> 16) animations:^{
                [self openDrawer];
            } completion:nil];
        }
        
        self.closeDrawerButton.hidden = NO;
        
    } else {
        if (self.scrollView.alpha > 0) {
            [UIView animateWithDuration:0.33 delay:0.0 options:(7 >> 16) animations:^{
                [self closeDrawer];
            } completion:nil];
        }
        
        self.closeDrawerButton.hidden = YES;
    }
}

- (void)handleDrawerDragGesture:(UIPanGestureRecognizer *)recognizer
{
    // opening refers to the drawer, not the map
    BOOL opening = !([recognizer.view isEqual:self.gripper] || [recognizer.view isEqual:self.closeDrawerButton]);
    
    if (opening && self.drawerOpen) {
        return;
    }
    
    CGFloat draggableHeight = self.drawer.bounds.size.height - TAB_BAR_HEIGHT;
    CGFloat moveDiff = [recognizer translationInView:self.drawer].y;
    
    // dragFactor: opening is negative / closing is positive
    CGFloat dragFactor = moveDiff / draggableHeight;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.drawerCurrentDragCenterY = self.drawer.center.y;
        
        [self.view endEditing:YES];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Used Map Drag Gesture" properties:nil];
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(self.drawer.center.x, self.drawerCurrentDragCenterY + moveDiff);
        
        // alphaFactor provides a normalized factor for fading drawer contents from 0 to 1 while opening and 1 to 0 while closing
        CGFloat alphaFactor = (opening) ? fabs(dragFactor) : 1.0 - fabs(dragFactor);
        //        NSLog(@"%f, drag: %f, alpha: %f", moveDiff, dragFactor, alphaFactor);
        
        if ((!opening && (dragFactor >= 0 && dragFactor <= 1.0)) || (opening && (dragFactor <= 0 && dragFactor >= -1.0))) {
            self.drawer.center = newCenter;
            self.scrollView.alpha = alphaFactor;
            self.gripper.alpha = alphaFactor;
        } else if ((opening && dragFactor < 0) || dragFactor < 1.0) {
            CGFloat scaleFactor = 1.0 + fabs((moveDiff + draggableHeight * opening) / draggableHeight) * 0.25;
            self.drawer.transform = CGAffineTransformMakeScale(1.0, scaleFactor);
        }
        
    } else {
        CGFloat terminalVelocity = [recognizer velocityInView:self.view].y;
        
        if (terminalVelocity < -250 || (opening && dragFactor <= -0.25)) {
            [self openDrawerWithVelocity:terminalVelocity];
        } else if (terminalVelocity > 40 || (!opening && dragFactor > 0.25)) {
            [self closeDrawerWithVelocity:terminalVelocity];
        } else {
            // you didn't want it enough
            if (opening) {
                [self closeDrawerWithVelocity:terminalVelocity];
            } else {
                [self openDrawerWithVelocity:terminalVelocity];
            }
        }
    }
}

- (void)openDrawer
{
    self.drawer.center = CGPointMake(self.drawer.center.x, self.drawerOpenCenterY);
    self.scrollView.alpha = 1;
    self.gripper.alpha = 1;
    self.closeDrawerButton.hidden = NO;
}

- (void)closeDrawer
{
    self.drawer.transform = CGAffineTransformIdentity;
    self.drawer.frame = CGRectMake(self.drawer.frame.origin.x, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.drawer.bounds.size.width, self.drawer.bounds.size.height);
    self.scrollView.alpha = 0;
    self.gripper.alpha = 0;
    self.closeDrawerButton.hidden = YES;
    
    [self.view endEditing:YES];
    
    for (UIButton *b in self.tabBar.subviews) {
        b.selected = NO;
        b.tintColor = nil;
    }
}

- (void)closeDrawerWithAnimation
{
    self.drawerOpen = NO;
}

- (void)openDrawerWithVelocity:(CGFloat)velocity
{
    velocity = MIN(abs(velocity), 3500);
    CGFloat velocityFactor = velocity / 3500;
    CGFloat animationDuration = 0.3 * (1 - velocityFactor);
    CGFloat scaleFactor = 1 + velocityFactor * 0.2;
    
    [UIView animateWithDuration:animationDuration delay:0 options:0 animations:^{
        [self openDrawer];
        
        if (CGAffineTransformIsIdentity(self.drawer.transform)) {
            self.drawer.transform = CGAffineTransformMakeScale(1.0, scaleFactor);
        }
        
    } completion:^(BOOL finished) {
        if (CGAffineTransformIsIdentity(self.drawer.transform)) {
            self.drawerOpen = YES;
        } else {
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.25 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.drawer.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.drawerOpen = YES;
            }];
        }
    }];
}

- (void)closeDrawerWithVelocity:(CGFloat)velocity
{
    velocity = MIN(abs(velocity), 3500);
    CGFloat velocityFactor = velocity / 3500;
    CGFloat animationDuration = 0.3 * (1 - velocityFactor);
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self closeDrawer];
    } completion:^(BOOL finished) {
        self.drawerOpen = NO;
    }];
}

#pragma mark - Other

- (void)stopTableView:(UITableView *)tableView didSelectCellWithStop:(NSString *)stopCode
{
    [self.delegate drawerDidSelectCellWithStop:stopCode];
}

- (void)longPressRecognized:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        UIActionSheet *clearSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) destructiveButtonTitle:NSLocalizedString(@"CLEAR_ALL_HISTORY", nil) otherButtonTitles:nil];
        [clearSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        NSArray *emptyArray = [NSArray new];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:emptyArray forKey:@"history"];
        [defaults synchronize];
        
        [self.historyController.tableView reloadData];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Cleared History" properties:nil];
    }
}

@end
