//
//  CFResultCell.h
//  CF
//
//  Created by Radu Dutzan on 12/1/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CFResultCellDelegate <NSObject>

- (void)sendComplaintTweetForService:(NSString *)service;

@end

@interface CFResultCell : UITableViewCell

@property (nonatomic, strong) UILabel *serviceLabel;
@property (nonatomic, strong) UILabel *directionLabel;
@property (nonatomic, strong) NSArray *estimations;
@property (nonatomic, strong) NSString *noEstimationReason;
@property (nonatomic, strong) UIColor *badgeColor;
@property (nonatomic, weak) id<CFResultCellDelegate> delegate;
@property (nonatomic, assign) BOOL loading;

@end
