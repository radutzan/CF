//
//  CFDrawerController.h
//  CF
//
//  Created by Radu Dutzan on 8/18/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#define DRAWER_ORIGIN_Y 160.0

@protocol CFDrawerControllerDelegate <NSObject>

- (void)drawerDidSelectCellWithStop:(NSString *)stopCode;

@end

@protocol CFDrawerScrollingDelegate <NSObject>

- (void)drawerScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)drawerScrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;

@end

@interface CFDrawerController : UIViewController

- (void)reloadUserData;
- (void)hideDrawer;
- (void)showDrawer;

@property (nonatomic, assign) BOOL drawerOpen;
@property (nonatomic, weak) id<CFDrawerControllerDelegate> delegate;

@end
