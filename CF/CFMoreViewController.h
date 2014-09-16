//
//  CFMoreViewController.h
//  CF
//
//  Created by Radu Dutzan on 11/18/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFDrawerController.h"

@interface CFMoreViewController : UITableViewController <CFDrawerScrollingDelegate>

@property (nonatomic, weak) id<CFDrawerScrollingDelegate> scrollingDelegate;

@end
