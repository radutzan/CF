//
//  CFServiceSuggestionView.h
//  CF
//
//  Created by Radu Dutzan on 5/26/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CFServiceSuggestionViewDelegate <NSObject>

- (void)serviceSuggestionViewDidSelectButtonAtIndex:(NSUInteger)index service:(NSString *)service;

@end

@interface CFServiceSuggestionView : UIView

@property (nonatomic, strong) NSString *service;
@property (nonatomic, strong) NSString *outwardDirectionString;
@property (nonatomic, strong) NSString *inwardDirectionString;
@property (nonatomic, weak) id<CFServiceSuggestionViewDelegate> delegate;

@end
