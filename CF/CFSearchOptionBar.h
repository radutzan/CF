//
//  CFSearchOptionBar.h
//  CF
//
//  Created by Radu Dutzan on 4/1/15.
//  Copyright (c) 2015 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CFSearchOptionBar;

@protocol CFSearchOptionBarDelegate <NSObject>

- (void)searchOptionBarTapped:(CFSearchOptionBar *)optionBar;

@end

@interface CFSearchOptionBar : UIView

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *optionTitle;
@property (nonatomic, strong) UIImage *optionImage;
@property (nonatomic, assign) id<CFSearchOptionBarDelegate> delegate;

@end
