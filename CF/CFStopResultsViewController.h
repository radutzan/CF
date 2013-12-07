//
//  CFStopResultsViewController.h
//  CF
//
//  Created by Radu Dutzan on 11/17/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFStop.h"

@interface CFStopResultsViewController : UITableViewController

@property (nonatomic, strong) NSString *stopCode;
@property (nonatomic, strong) CFStop *stop;

@end
