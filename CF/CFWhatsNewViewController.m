//
//  CFWhatsNewViewController.m
//  CF
//
//  Created by Radu Dutzan on 5/25/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFWhatsNewViewController.h"
#import "UIImage+ImageEffects.h"

#define BUTTON_HEIGHT 72.0
#define OUTER_MARGIN 20.0
#define INNER_MARGIN 15.0
#define VERTICAL_MARGIN 20.0

@interface CFWhatsNewViewController ()

@property (nonatomic, strong) UIImageView *snapshotImageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL tinyScreen;

@end

@implementation CFWhatsNewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    
    self.tinyScreen = (self.view.bounds.size.height < 500);
    CGFloat titleLabelOriginY = (self.tinyScreen) ? VERTICAL_MARGIN : VERTICAL_MARGIN * 2;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(OUTER_MARGIN, titleLabelOriginY, self.view.bounds.size.width - OUTER_MARGIN * 2, 120.0)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:36.0];
    titleLabel.numberOfLines = 2;
    titleLabel.textColor = [UIColor colorWithWhite:0 alpha:.8];
    titleLabel.text = NSLocalizedString(@"WHATS_NEW_TITLE", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, titleLabel.bounds.size.height + titleLabel.frame.origin.y, self.view.bounds.size.width, self.view.bounds.size.height - BUTTON_HEIGHT - titleLabel.frame.origin.y - titleLabel.bounds.size.height)];
    self.scrollView.contentInset = UIEdgeInsetsMake(VERTICAL_MARGIN, 0.0, VERTICAL_MARGIN, 0.0);
    [self.view addSubview:self.scrollView];
    
    NSArray *contentArray = @[@{@"image": [UIImage imageNamed:@"feature-map"],
                                @"title": NSLocalizedString(@"WHATS_NEW_MAP_TITLE", nil),
                                @"description": NSLocalizedString(@"WHATS_NEW_MAP_DESCRIPTION", nil)},
                              @{@"image": [UIImage imageNamed:@"feature-service"],
                                @"title": NSLocalizedString(@"WHATS_NEW_ROUTES_TITLE", nil),
                                @"description": NSLocalizedString(@"WHATS_NEW_ROUTES_DESCRIPTION", nil)},
                              @{@"image": [UIImage imageNamed:@"feature-pro"],
                                @"title": NSLocalizedString(@"WHATS_NEW_PRO_TITLE", nil),
                                @"description": NSLocalizedString(@"WHATS_NEW_PRO_DESCRIPTION", nil)}];
    
    CGFloat itemOriginY = 0;
    CGFloat labelOriginX;
    
    for (NSDictionary *content in contentArray) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[content objectForKey:@"image"]];
        imageView.frame = CGRectOffset(imageView.frame, OUTER_MARGIN, itemOriginY);
        imageView.alpha = 0.8;
        [self.scrollView addSubview:imageView];
        
        labelOriginX = imageView.frame.size.width + OUTER_MARGIN + INNER_MARGIN;
        
        UILabel *itemTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelOriginX, itemOriginY - 2.0, self.view.bounds.size.width - OUTER_MARGIN - labelOriginX, 22.0)];
        itemTitleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        itemTitleLabel.text = [content objectForKey:@"title"];
        itemTitleLabel.textColor = [UIColor colorWithWhite:0 alpha:.85];
        [self.scrollView addSubview:itemTitleLabel];
        
        UILabel *itemDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelOriginX, itemOriginY + itemTitleLabel.bounds.size.height, itemTitleLabel.bounds.size.width, 100.0)];
        itemDescriptionLabel.numberOfLines = 0;
        itemDescriptionLabel.font = [UIFont systemFontOfSize:15.0];
        itemDescriptionLabel.textColor = [UIColor colorWithWhite:0 alpha:.65];
        itemDescriptionLabel.text = [content objectForKey:@"description"];
        [itemDescriptionLabel sizeToFit];
        [self.scrollView addSubview:itemDescriptionLabel];
        
        itemOriginY += itemTitleLabel.bounds.size.height + itemDescriptionLabel.bounds.size.height + VERTICAL_MARGIN;
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, itemOriginY - VERTICAL_MARGIN);
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    doneButton.frame = CGRectMake(0, self.scrollView.frame.origin.y + self.scrollView.bounds.size.height, self.view.bounds.size.width, BUTTON_HEIGHT);
    doneButton.titleLabel.font = [UIFont systemFontOfSize:23.0];
    [doneButton setTitle:NSLocalizedString(@"WHATS_NEW_DISMISS", nil) forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:doneButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.presentingViewController.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    UIImage *snapshotOfPresentingViewController = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    snapshotOfPresentingViewController = [snapshotOfPresentingViewController applyLightEffect];
    
    self.snapshotImageView = [[UIImageView alloc] initWithImage:snapshotOfPresentingViewController];
    self.snapshotImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.snapshotImageView.transform = CGAffineTransformMakeTranslation(0, -snapshotOfPresentingViewController.size.height);
        
        [UIView animateWithDuration:[context transitionDuration] animations:^{
            self.snapshotImageView.transform = CGAffineTransformIdentity;
        }];
    } completion:NULL];
    
    [self.view insertSubview:self.snapshotImageView atIndex:0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.tinyScreen) [self.scrollView flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[context transitionDuration]];
        [UIView setAnimationCurve:[context completionCurve]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        self.snapshotImageView.transform = CGAffineTransformMakeTranslation(0, -self.snapshotImageView.image.size.height);
        
        [UIView commitAnimations];
    } completion:NULL];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
