//
//  CFEnterStopCodeView.h
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CFEnterStopCodeViewDelegate <NSObject>

- (void)enterStopCodeViewDidEnterStopCode:(NSString *)stopCode;

@end

@interface CFEnterStopCodeView : UIView

@property (nonatomic, strong) UITextField *elPeA;
@property (nonatomic, weak) id<CFEnterStopCodeViewDelegate> delegate;

@end
