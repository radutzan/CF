//
//  CFSearchField.m
//  CF
//
//  Created by Radu Dutzan on 6/11/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFSearchField.h"

@interface CFSearchField () <UITextFieldDelegate>

@property (nonatomic, strong) UIImageView *glyphView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, copy, readwrite) NSString *text;

@end

@implementation CFSearchField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _glyphView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16.0, frame.size.height - 1.0)];
        _glyphView.contentMode = UIViewContentModeCenter;
//        _glyphView.tintColor = [UIColor colorWithWhite:0 alpha:.2];
        _glyphView.image = [[UIImage imageNamed:@"searchfield-glyph"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self addSubview:_glyphView];
        
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(_glyphView.bounds.size.width + 2.0, 0, frame.size.width - 1.0 - _glyphView.bounds.size.width, frame.size.height)];
        _textField.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        _textField.returnKeyType = UIReturnKeySearch;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.delegate = self;
        _textField.font = [UIFont fontWithName:DEFAULT_FONT_NAME_REGULAR size:18.0];
        [self addSubview:_textField];
        
        _text = @"";
    }
    return self;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.glyphView.tintColor = nil;
    [self.delegate searchFieldDidBeginEditing:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
//    self.glyphView.tintColor = [UIColor colorWithWhite:0 alpha:.2];
    [self.delegate searchFieldDidEndEditing:self];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *searchString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    self.text = searchString;
    [self.delegate searchField:self textDidChange:searchString];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self.delegate searchField:self textDidChange:@""];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.delegate searchFieldSearchButtonClicked:self];
    return YES;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    self.textField.placeholder = placeholder;
}

- (BOOL)isEditing
{
    return self.textField.editing;
}

- (void)clear
{
    self.textField.text = @"";
}

@end
