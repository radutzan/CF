//
//  CFMapSearchSuggestionView.h
//  CF
//
//  Created by Radu Dutzan on 9/18/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CFMapSearchSuggestionViewDelegate <NSObject>

- (void)mapSearchSuggestionViewTapped;

@end

@interface CFMapSearchSuggestionView : UIView

@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, assign) id<CFMapSearchSuggestionViewDelegate> delegate;

@end
