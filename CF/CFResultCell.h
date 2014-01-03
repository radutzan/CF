//
//  CFResultCell.h
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CFResultCell : UITableViewCell

@property (nonatomic, strong) UILabel *serviceLabel;
@property (nonatomic, strong) UILabel *directionLabel;
@property (nonatomic, strong) NSArray *estimations;
@property (nonatomic, strong) UIColor *badgeColor;

@end
