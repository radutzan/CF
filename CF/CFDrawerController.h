//
//  CFDrawerController.h
//  CF
//
//  Created by Radu Dutzan on 8/18/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CFDrawerControllerDelegate <NSObject>

- (void)drawerDidSelectCellWithStop:(NSString *)stopCode;

@optional
- (void)drawerDidOpen;
- (void)drawerDidClose;

@end

@interface CFDrawerController : UIViewController

- (void)reloadUserData;

@property (nonatomic, weak) id<CFDrawerControllerDelegate> delegate;

@end
