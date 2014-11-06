//
//  CFStopTableViewController.h
//  CF
//
//  Created by Radu Dutzan on 11/19/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CFStop.h"
#import "CFStopCell.h"
#import "CFDrawerController.h"

@protocol CFStopTableViewDelegate <NSObject>

- (void)stopTableView:(UITableView *)tableView didSelectCellWithStop:(NSString *)stopCode;

@end

@interface CFStopTableViewController : UITableViewController

@property (nonatomic, weak) id<CFStopTableViewDelegate> delegate;
@property (nonatomic, weak) id<CFDrawerScrollingDelegate> scrollingDelegate;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) NSString *placeholderTitle;
@property (nonatomic, strong) NSString *placeholderMessage;
@property (nonatomic, assign) BOOL placeholderVisible;
@property (nonatomic, strong) NSString *footerString;

@end
