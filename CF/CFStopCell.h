//
//  CFStopCell.h
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

#define HORIZONTAL_MARGIN 6.0
#define CELL_HEIGHT 56.0

@interface CFStopCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *codeLabel;
@property (nonatomic, strong) UIImageView *metroBadge;

@end
