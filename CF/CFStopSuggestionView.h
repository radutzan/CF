//
//  CFStopSuggestionView.h
//  CF
//
//  Created by Radu Dutzan on 5/31/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFStop.h"

@protocol CFStopSuggestionViewDelegate <NSObject>

- (void)stopSuggestionViewDidSelectStop:(NSString *)stop;
- (void)stopSuggestionViewDidSelectService:(NSString *)service directionString:(NSString *)directionString;

@end

@interface CFStopSuggestionView : UIView

@property (nonatomic, strong) CFStop *stop;
@property (nonatomic, weak) id<CFStopSuggestionViewDelegate> delegate;

@end
