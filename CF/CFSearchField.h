//
//  CFSearchField.h
//  CF
//
//  Created by Radu Dutzan on 6/11/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CFSearchFieldDelegate;
@interface CFSearchField : UIView

@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, weak) id<CFSearchFieldDelegate> delegate;
@property (nonatomic, copy) NSString *text;

@end

@protocol CFSearchFieldDelegate <NSObject>

- (void)searchFieldDidBeginEditing:(CFSearchField *)searchField;
- (void)searchFieldDidEndEditing:(CFSearchField *)searchField;
- (void)searchField:(CFSearchField *)searchField textDidChange:(NSString *)searchText;
- (void)searchFieldSearchButtonClicked:(CFSearchField *)searchField;

@end