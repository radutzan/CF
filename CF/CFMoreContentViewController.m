//
//  CFMoreContentViewController.m
//  CF
//
//  Created by Radu Dutzan on 12/7/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFMoreContentViewController.h"

@interface CFMoreContentViewController ()

@end

@implementation CFMoreContentViewController

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
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

@end
